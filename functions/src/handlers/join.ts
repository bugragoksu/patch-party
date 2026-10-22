import { createHash } from 'node:crypto';
import { getAuth } from 'firebase-admin/auth';
import type { CallableRequest } from 'firebase-functions/v2/https';
import { z } from 'zod';
import { db, paths, readEvent } from '../data/db.js';
import type { PlayerDoc } from '../data/model.js';
import { cleanDisplayName, isOffensive, isValidDisplayName, nameSuggestions, normalizeName } from '../domain/names.js';
import { canJoin, randomPlayerCode, validInterests } from '../domain/rules.js';
import { newSeed, verifyJoinCode } from '../domain/totp.js';
import { checkAppCheck } from '../infra/auth.js';
import { GameError } from '../infra/errors.js';
import { eventIdSchema, parse } from '../infra/validate.js';

const input = z.object({
  eventId: eventIdSchema,
  joinCode: z.string().max(16),
  displayName: z.string().max(64),
  interests: z.array(z.string().max(32)).max(5),
});

export interface JoinResult {
  uid: string;
  customToken: string;
  playerCode: string;
  totpSeed: string;
  serverTime: number;
}

export async function join(request: CallableRequest<unknown>): Promise<JoinResult> {
  const data = parse(input, request.data);
  const now = Date.now();

  const eventSnap = await paths.event(data.eventId).get();
  const event = readEvent(eventSnap.data());
  checkAppCheck(request, event.settings);
  if (!canJoin(event)) throw new GameError('event_closed');

  const secret = await paths.joinSecret(data.eventId).get();
  const joinSeed = secret.get('joinSeed') as string | undefined;
  if (!joinSeed || !verifyJoinCode(joinSeed, data.eventId, data.joinCode, now, event.settings.joinWindowSec)) {
    throw new GameError('join_code_invalid');
  }

  const displayName = cleanDisplayName(data.displayName);
  if (!isValidDisplayName(displayName) || isOffensive(displayName)) throw new GameError('invalid_name');
  if (!validInterests(data.interests)) throw new GameError('invalid_interests');
  const nameKey = normalizeName(displayName);

  const count = await paths.players(data.eventId).count().get();
  if (count.data().count >= event.settings.maxPlayers) throw new GameError('event_full');

  const uid = paths.players(data.eventId).doc().id;
  const totpSeed = newSeed();

  const playerCode = await db.runTransaction(async (tx) => {
    const nameDoc = await tx.get(paths.displayName(data.eventId, nameKey));
    if (nameDoc.exists) throw new GameError('name_taken');

    let code: string | null = null;
    for (let attempt = 0; attempt < 8 && !code; attempt++) {
      const candidate = randomPlayerCode();
      const codeDoc = await tx.get(paths.playerCode(data.eventId, candidate));
      if (!codeDoc.exists) code = candidate;
    }
    if (!code) throw new Error('could not allocate a player code');

    const player: PlayerDoc = {
      displayName,
      nameKey,
      nameHidden: false,
      interests: data.interests,
      playerCode: code,
      score: 0,
      connectionCount: 0,
      bridgeCount: 0,
      clustersMet: [],
      badges: [],
      rank: null,
      rankTotal: null,
      rankedAt: null,
      lastConnectionAt: null,
      outgoingRequest: null,
      disqualified: false,
      joinedAt: now,
    };
    tx.create(paths.displayName(data.eventId, nameKey), { uid });
    tx.create(paths.playerCode(data.eventId, code), { uid });
    tx.create(paths.player(data.eventId, uid), player);
    tx.create(paths.playerSecret(data.eventId, uid), { totpSeed });
    tx.create(paths.joinAudit(data.eventId, uid), {
      ipHash: hashIp(request.rawRequest?.ip, joinSeed),
      userAgentFamily: uaFamily(request.rawRequest?.headers['user-agent']),
      joinedAt: now,
    });
    return code;
  }).catch(async (error: unknown) => {
    if (error instanceof GameError && error.reason === 'name_taken') {
      throw new GameError('name_taken', { suggestion: await firstFreeName(data.eventId, displayName) });
    }
    throw error;
  });

  const customToken = await getAuth().createCustomToken(uid, { eventId: data.eventId });
  return { uid, customToken, playerCode, totpSeed, serverTime: Date.now() };
}

async function firstFreeName(eventId: string, displayName: string): Promise<string | null> {
  for (const candidate of nameSuggestions(displayName)) {
    const doc = await paths.displayName(eventId, normalizeName(candidate)).get();
    if (!doc.exists) return candidate;
  }
  return null;
}

function hashIp(ip: string | undefined, salt: string): string | null {
  return ip ? createHash('sha256').update(`${salt}:${ip}`).digest('hex').slice(0, 20) : null;
}

/** Only the browser family is kept, never the full user agent. */
function uaFamily(ua: string | string[] | undefined): string {
  const s = Array.isArray(ua) ? ua.join(' ') : (ua ?? '');
  if (/Instagram|FBAN|FBAV|WhatsApp|LinkedIn/i.test(s)) return 'in-app';
  if (/CriOS|Chrome/i.test(s)) return /Android/i.test(s) ? 'chrome-android' : 'chrome';
  if (/Safari/i.test(s)) return /iPhone|iPad/i.test(s) ? 'safari-ios' : 'safari';
  if (/Firefox/i.test(s)) return 'firefox';
  return 'other';
}
