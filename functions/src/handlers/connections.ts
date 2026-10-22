import type { Transaction } from 'firebase-admin/firestore';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { db, paths, readEvent } from '../data/db.js';
import type { ConnectionDoc, ConnectionRequestDoc, EventDoc, PlayerDoc, RateLimitDoc } from '../data/model.js';
import { questionFor } from '../domain/questions.js';
import { clusterOf, earnedBadges, isLive, pairId, parseScannedCode, pointsFor } from '../domain/rules.js';
import { verifyToken } from '../domain/totp.js';
import { checkAppCheck, requirePlayerOf } from '../infra/auth.js';
import { COUNTED_FAILURES, GameError } from '../infra/errors.js';
import { eventIdSchema, parse } from '../infra/validate.js';

const FAILURE_WINDOW_MS = 60_000;
const QR_FAILURE_LIMIT = 10;
const MANUAL_FAILURE_LIMIT = 5;
const BLOCK_MS = 60_000;
const DECLINE_RETRY_MS = 60_000;
const MAX_INCOMING = 3;

export interface RequestResult {
  status: 'pending' | 'accepted';
  requestId: string;
  expiresAt: number;
  target: { uid: string; name: string; interests: string[] };
  connection?: ConnectionResult;
}

export interface ConnectionResult {
  connectionId: string;
  points: number;
  bonus: number;
  questionKey: string;
  questionSeed: number;
}

const requestInput = z.object({ eventId: eventIdSchema, code: z.string().min(4).max(200) });

export async function requestConnection(request: CallableRequest<unknown>): Promise<RequestResult> {
  const data = parse(requestInput, request.data);
  const uid = requirePlayerOf(request, data.eventId);
  const now = Date.now();
  const scanned = parseScannedCode(data.code);

  await assertNotBlocked(data.eventId, uid, now);

  try {
    if (!scanned) throw new GameError('code_invalid');
    return await db.runTransaction(async (tx) => {
      const event = readEvent((await tx.get(paths.event(data.eventId))).data());
      checkAppCheck(request, event.settings);
      if (!isLive(event, now)) throw new GameError('not_live');

      const me = await getPlayer(tx, data.eventId, uid);
      if (me.disqualified) throw new GameError('disqualified');
      if (me.connectionCount >= event.settings.maxConnPerPlayer) throw new GameError('connection_limit');
      if (me.lastConnectionAt && now - me.lastConnectionAt < event.settings.cooldownSec * 1000) {
        throw new GameError('cooldown', { retryAt: me.lastConnectionAt + event.settings.cooldownSec * 1000 });
      }

      const codeDoc = await tx.get(paths.playerCode(data.eventId, scanned.playerCode));
      const targetUid = codeDoc.get('uid') as string | undefined;
      if (!targetUid) throw new GameError('code_invalid');
      if (targetUid === uid) throw new GameError('self_scan');

      const secret = await tx.get(paths.playerSecret(data.eventId, targetUid));
      const seed = secret.get('totpSeed') as string | undefined;
      if (!seed || !verifyToken(seed, data.eventId, scanned.token, scanned.kind, now, event.settings.tokenWindowSec)) {
        throw new GameError('token_invalid');
      }

      const target = await getPlayer(tx, data.eventId, targetUid);
      if (target.disqualified) throw new GameError('code_invalid');

      const id = pairId(uid, targetUid);
      const [connection, existing] = await Promise.all([
        tx.get(paths.connection(data.eventId, id)),
        tx.get(paths.request(data.eventId, id)),
      ]);
      if (connection.exists) throw new GameError('already_connected');

      const targetSummary = { uid: targetUid, name: target.displayName, interests: target.interests };
      const req = existing.data() as ConnectionRequestDoc | undefined;
      if (req && req.status === 'pending' && req.expiresAt > now) {
        if (req.fromUid === uid) {
          return { status: 'pending', requestId: id, expiresAt: req.expiresAt, target: targetSummary };
        }
        // The other player already asked us: scanning them back counts as accepting (ADR-0013).
        const result = acceptInTx(tx, event, data.eventId, id, req, target, me, now);
        return { status: 'accepted', requestId: id, expiresAt: req.expiresAt, target: targetSummary, connection: result };
      }
      if (req && req.status === 'declined' && req.respondedAt && now - req.respondedAt < DECLINE_RETRY_MS) {
        throw new GameError('cooldown', { retryAt: req.respondedAt + DECLINE_RETRY_MS });
      }

      if (me.outgoingRequest && me.outgoingRequest.expiresAt > now) {
        const open = await tx.get(paths.request(data.eventId, me.outgoingRequest.requestId));
        if (open.get('status') === 'pending') throw new GameError('request_limit', { which: 'outgoing' });
      }
      const incoming = await tx.get(
        paths
          .requests(data.eventId)
          .where('toUid', '==', targetUid)
          .where('status', '==', 'pending')
          .where('expiresAt', '>', now)
          .limit(MAX_INCOMING),
      );
      if (incoming.size >= MAX_INCOMING) throw new GameError('request_limit', { which: 'incoming' });

      const expiresAt = now + event.settings.requestTtlSec * 1000;
      const doc: ConnectionRequestDoc = {
        fromUid: uid,
        toUid: targetUid,
        fromName: me.displayName,
        fromInterests: me.interests,
        toName: target.displayName,
        toInterests: target.interests,
        status: 'pending',
        createdAt: now,
        expiresAt,
        respondedAt: null,
      };
      tx.set(paths.request(data.eventId, id), doc);
      tx.update(paths.player(data.eventId, uid), { outgoingRequest: { requestId: id, toUid: targetUid, expiresAt } });
      return { status: 'pending', requestId: id, expiresAt, target: targetSummary };
    });
  } catch (error) {
    if (error instanceof GameError && COUNTED_FAILURES.has(error.reason)) {
      await recordFailure(data.eventId, uid, error.reason, scanned?.kind === 'digits', now);
    }
    throw error;
  }
}

const respondInput = z.object({ eventId: eventIdSchema, requestId: z.string().max(300), accept: z.boolean() });

export async function respondToRequest(
  request: CallableRequest<unknown>,
): Promise<{ status: 'accepted' | 'declined'; connection?: ConnectionResult }> {
  const data = parse(respondInput, request.data);
  const uid = requirePlayerOf(request, data.eventId);
  const now = Date.now();

  const outcome = await db.runTransaction(async (tx) => {
    const event = readEvent((await tx.get(paths.event(data.eventId))).data());
    checkAppCheck(request, event.settings);
    const reqSnap = await tx.get(paths.request(data.eventId, data.requestId));
    const req = reqSnap.data() as ConnectionRequestDoc | undefined;
    if (!req) throw new GameError('not_found');
    if (req.toUid !== uid) throw new GameError('permission_denied');
    if (req.status !== 'pending') throw new GameError('request_expired', { status: req.status });

    const from = await getPlayer(tx, data.eventId, req.fromUid);
    const me = await getPlayer(tx, data.eventId, uid);

    if (req.expiresAt <= now) {
      tx.update(reqSnap.ref, { status: 'expired', respondedAt: now });
      clearOutgoing(tx, data.eventId, req.fromUid, from, data.requestId);
      // Returned instead of thrown so the expiry write commits.
      return { status: 'expired' as const };
    }
    if (!data.accept) {
      tx.update(reqSnap.ref, { status: 'declined', respondedAt: now });
      clearOutgoing(tx, data.eventId, req.fromUid, from, data.requestId);
      return { status: 'declined' as const };
    }

    if (!isLive(event, now)) throw new GameError('not_live');
    if (from.disqualified || me.disqualified) throw new GameError('disqualified');
    const connection = await tx.get(paths.connection(data.eventId, data.requestId));
    if (connection.exists) throw new GameError('already_connected');

    return { status: 'accepted' as const, connection: acceptInTx(tx, event, data.eventId, data.requestId, req, from, me, now) };
  });
  if (outcome.status === 'expired') throw new GameError('request_expired', { status: 'expired' });
  return outcome;
}

const cancelInput = z.object({ eventId: eventIdSchema, requestId: z.string().max(300) });

export async function cancelRequest(request: CallableRequest<unknown>): Promise<{ status: 'cancelled' }> {
  const data = parse(cancelInput, request.data);
  const uid = requirePlayerOf(request, data.eventId);
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const reqSnap = await tx.get(paths.request(data.eventId, data.requestId));
    const req = reqSnap.data() as ConnectionRequestDoc | undefined;
    if (!req) throw new GameError('not_found');
    if (req.fromUid !== uid) throw new GameError('permission_denied');
    const me = await getPlayer(tx, data.eventId, uid);
    if (req.status === 'pending') tx.update(reqSnap.ref, { status: 'cancelled', respondedAt: now });
    clearOutgoing(tx, data.eventId, uid, me, data.requestId);
  });
  return { status: 'cancelled' };
}

/** Writes the connection, both players' new scores and badges, and closes the request. */
function acceptInTx(
  tx: Transaction,
  event: EventDoc,
  eventId: string,
  id: string,
  req: ConnectionRequestDoc,
  from: PlayerDoc,
  to: PlayerDoc,
  now: number,
): ConnectionResult {
  const pts = pointsFor(from.interests, to.interests);
  const question = questionFor(id, from.interests, to.interests);
  const conn: ConnectionDoc = {
    participants: id.split('_') as [string, string],
    scannerUid: req.fromUid,
    targetUid: req.toUid,
    names: { [req.fromUid]: from.displayName, [req.toUid]: to.displayName },
    points: pts.total,
    bonus: pts.bonus,
    questionKey: question.key,
    questionSeed: question.seed,
    createdAt: now,
  };
  tx.create(paths.connection(eventId, id), conn);
  tx.update(paths.request(eventId, id), { status: 'accepted', respondedAt: now });

  for (const [uid, self, other] of [
    [req.fromUid, from, to],
    [req.toUid, to, from],
  ] as const) {
    const clusters = new Set(self.clustersMet);
    for (const i of other.interests) {
      const c = clusterOf(i);
      if (c) clusters.add(c);
    }
    const connectionCount = self.connectionCount + 1;
    const bridgeCount = self.bridgeCount + (pts.bonus > 0 ? 1 : 0);
    const badges = event.settings.features.badges
      ? earnedBadges({ connectionCount, bridgeCount, clustersMet: clusters.size })
      : self.badges;
    tx.update(paths.player(eventId, uid), {
      score: self.score + pts.total,
      connectionCount,
      bridgeCount,
      clustersMet: [...clusters],
      badges,
      lastConnectionAt: now,
      ...(self.outgoingRequest?.requestId === id ? { outgoingRequest: null } : {}),
    });
  }
  return { connectionId: id, points: pts.total, bonus: pts.bonus, questionKey: question.key, questionSeed: question.seed };
}

function clearOutgoing(tx: Transaction, eventId: string, uid: string, player: PlayerDoc, requestId: string): void {
  if (player.outgoingRequest?.requestId === requestId) tx.update(paths.player(eventId, uid), { outgoingRequest: null });
}

async function getPlayer(tx: Transaction, eventId: string, uid: string): Promise<PlayerDoc> {
  const snap = await tx.get(paths.player(eventId, uid));
  if (!snap.exists) throw new GameError('not_found', { what: 'player' });
  return snap.data() as PlayerDoc;
}

async function assertNotBlocked(eventId: string, uid: string, now: number): Promise<void> {
  const rl = (await paths.rateLimit(eventId, uid).get()).data() as RateLimitDoc | undefined;
  if (rl?.blockedUntil && rl.blockedUntil > now) throw new GameError('rate_limited', { retryAt: rl.blockedUntil });
}

async function recordFailure(eventId: string, uid: string, reason: string, manual: boolean, now: number): Promise<void> {
  const limit = manual ? MANUAL_FAILURE_LIMIT : QR_FAILURE_LIMIT;
  await db.runTransaction(async (tx) => {
    const ref = paths.rateLimit(eventId, uid);
    const rl = (await tx.get(ref)).data() as RateLimitDoc | undefined;
    const fresh = !rl || now - rl.windowStart > FAILURE_WINDOW_MS;
    const failures = fresh ? 1 : rl.failures + 1;
    const next: Omit<RateLimitDoc, 'totalFailures'> = {
      windowStart: fresh ? now : rl.windowStart,
      failures,
      blockedUntil: failures >= limit ? now + BLOCK_MS : (rl?.blockedUntil ?? null),
      lastFailureReason: reason,
    };
    tx.set(ref, { ...next, totalFailures: (rl?.totalFailures ?? 0) + 1 });
  });
}
