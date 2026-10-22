import { getAuth } from 'firebase-admin/auth';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { db, paths, readEvent } from '../data/db.js';
import type { PlayerDoc } from '../data/model.js';
import { cleanDisplayName, isOffensive, isValidDisplayName, normalizeName } from '../domain/names.js';
import { canTransition, type EventState } from '../domain/rules.js';
import { requireAdmin } from '../infra/auth.js';
import { GameError } from '../infra/errors.js';
import { uidHash } from '../infra/observability.js';
import { eventIdSchema, parse } from '../infra/validate.js';
import { rankEvent } from './ranks.js';

function audit(eventId: string, actorUid: string, action: string, target: string | null): Promise<unknown> {
  return paths.auditLog(eventId).add({ actorUidHash: uidHash(actorUid), action, target, at: Date.now() });
}

const stateInput = z.object({
  eventId: eventIdSchema,
  state: z.enum(['draft', 'lobby', 'live', 'ended', 'archived']),
  liveDurationMin: z.number().int().min(1).max(120).optional(),
});

export async function setEventState(request: CallableRequest<unknown>): Promise<{ state: EventState }> {
  const data = parse(stateInput, request.data);
  const uid = requireAdmin(request);
  if (data.state === 'archived') throw new GameError('invalid_transition', { hint: 'use purgeEvent' });
  const now = Date.now();
  await db.runTransaction(async (tx) => {
    const ref = paths.event(data.eventId);
    const event = readEvent((await tx.get(ref)).data());
    if (!canTransition(event.state, data.state)) throw new GameError('invalid_transition', { from: event.state });
    const patch: Record<string, unknown> = { state: data.state, updatedAt: now };
    if (data.state === 'live' && event.state === 'lobby' && data.liveDurationMin) {
      patch.liveStartAt = now;
      patch.liveEndAt = now + data.liveDurationMin * 60_000;
    }
    if (data.state === 'ended') patch.liveEndAt = Math.min(event.liveEndAt ?? now, now);
    tx.update(ref, patch);
  });
  if (data.state === 'ended') await rankEvent(data.eventId, now);
  await audit(data.eventId, uid, `state:${data.state}`, null);
  return { state: data.state };
}

const settingsInput = z.object({
  eventId: eventIdSchema,
  settings: z
    .object({
      cooldownSec: z.number().int().min(0).max(600),
      tokenWindowSec: z.number().int().min(10).max(120),
      joinWindowSec: z.number().int().min(60).max(3600),
      requestTtlSec: z.number().int().min(10).max(300),
      maxConnPerPlayer: z.number().int().min(1).max(500),
      maxPlayers: z.number().int().min(1).max(1000),
      appCheckEnforce: z.boolean(),
      displayName: z.string().min(1).max(40),
      subtitle: z.string().max(80),
      prizes: z.array(z.string().max(120)).max(10),
      features: z.object({ badges: z.boolean(), playerRank: z.boolean() }).partial(),
    })
    .partial(),
});

export async function updateEventConfig(request: CallableRequest<unknown>): Promise<{ ok: true }> {
  const data = parse(settingsInput, request.data);
  const uid = requireAdmin(request);
  const patch: Record<string, unknown> = { updatedAt: Date.now() };
  for (const [key, value] of Object.entries(data.settings)) {
    if (key === 'features' && value && typeof value === 'object') {
      for (const [f, v] of Object.entries(value)) patch[`settings.features.${f}`] = v;
    } else {
      patch[`settings.${key}`] = value;
    }
  }
  await paths.event(data.eventId).update(patch);
  await audit(data.eventId, uid, 'settings', Object.keys(data.settings).join(','));
  return { ok: true };
}

const moderateInput = z.object({
  eventId: eventIdSchema,
  uid: z.string().min(1).max(128),
  action: z.enum(['disqualify', 'restore', 'hideName', 'showName', 'rename']),
  displayName: z.string().max(64).optional(),
});

export async function moderatePlayer(request: CallableRequest<unknown>): Promise<{ ok: true }> {
  const data = parse(moderateInput, request.data);
  const actor = requireAdmin(request);
  await db.runTransaction(async (tx) => {
    const ref = paths.player(data.eventId, data.uid);
    const snap = await tx.get(ref);
    if (!snap.exists) throw new GameError('not_found');
    const player = snap.data() as PlayerDoc;
    switch (data.action) {
      case 'disqualify':
        tx.update(ref, { disqualified: true });
        break;
      case 'restore':
        tx.update(ref, { disqualified: false });
        break;
      case 'hideName':
        tx.update(ref, { nameHidden: true });
        break;
      case 'showName':
        tx.update(ref, { nameHidden: false });
        break;
      case 'rename': {
        const name = cleanDisplayName(data.displayName ?? '');
        if (!isValidDisplayName(name) || isOffensive(name)) throw new GameError('invalid_name');
        const key = normalizeName(name);
        if (key !== player.nameKey) {
          const taken = await tx.get(paths.displayName(data.eventId, key));
          if (taken.exists) throw new GameError('name_taken');
          tx.delete(paths.displayName(data.eventId, player.nameKey));
          tx.create(paths.displayName(data.eventId, key), { uid: data.uid });
        }
        tx.update(ref, { displayName: name, nameKey: key });
        break;
      }
    }
  });
  await audit(data.eventId, actor, `moderate:${data.action}`, uidHash(data.uid) ?? null);
  return { ok: true };
}

const purgeInput = z.object({ eventId: eventIdSchema, confirm: z.string() });

/** FR-33: irreversibly removes personal data; keeps only aggregate counts. */
export async function purgeEvent(request: CallableRequest<unknown>): Promise<{ deletedUsers: number }> {
  const data = parse(purgeInput, request.data);
  const uid = requireAdmin(request);
  if (data.confirm !== data.eventId) throw new GameError('invalid_argument', { hint: 'confirm must equal eventId' });
  return purgeEventData(data.eventId, uid);
}

export async function purgeEventData(eventId: string, actorUid: string | null): Promise<{ deletedUsers: number }> {
  const eventRef = paths.event(eventId);
  const event = readEvent((await eventRef.get()).data());
  const players = await paths.players(eventId).select().get();
  const connections = await db.collection(`events/${eventId}/connections`).count().get();
  const uids = players.docs.map((d) => d.id);

  const summary = {
    playerCount: uids.length,
    connectionCount: connections.data().count,
    purgedAt: Date.now(),
    purgedBy: actorUid ? uidHash(actorUid) : 'script',
  };
  for (let i = 0; i < uids.length; i += 1000) await getAuth().deleteUsers(uids.slice(i, i + 1000));
  await db.recursiveDelete(eventRef);
  await eventRef.set({ name: event.name, state: 'archived', summary, updatedAt: Date.now() });
  return { deletedUsers: uids.length };
}
