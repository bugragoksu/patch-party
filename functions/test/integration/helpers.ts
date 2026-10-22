import type { CallableRequest } from 'firebase-functions/v2/https';
import { db, paths } from '../../src/data/db.js';
import { DEFAULT_SETTINGS, type EventSettings } from '../../src/data/model.js';
import type { EventState } from '../../src/domain/rules.js';
import { joinCodeFor, tokenFor, windowOf } from '../../src/domain/totp.js';
import { join, type JoinResult } from '../../src/handlers/join.js';
import { HttpsError } from 'firebase-functions/v2/https';

export const JOIN_SEED = 'AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA';

let counter = 0;
export function uniqueEventId(): string {
  counter += 1;
  return `test-${Date.now().toString(36)}-${counter}`;
}

export async function seedEvent(
  eventId: string,
  state: EventState = 'live',
  settings: Partial<EventSettings> = {},
): Promise<void> {
  await paths.event(eventId).set({
    name: 'Test',
    state,
    liveStartAt: null,
    liveEndAt: null,
    settings: { ...DEFAULT_SETTINGS, cooldownSec: 0, ...settings },
    updatedAt: Date.now(),
  });
  await paths.joinSecret(eventId).set({ joinSeed: JOIN_SEED });
}

export function joinCode(eventId: string): string {
  return joinCodeFor(JOIN_SEED, eventId, windowOf(Date.now(), DEFAULT_SETTINGS.joinWindowSec));
}

interface Caller {
  uid?: string;
  eventId?: string;
  admin?: boolean;
}

export function req(data: unknown, caller: Caller = {}): CallableRequest<unknown> {
  const token: Record<string, unknown> = {};
  if (caller.eventId) token.eventId = caller.eventId;
  if (caller.admin) token.admin = true;
  return {
    data,
    auth: caller.uid ? { uid: caller.uid, token, rawToken: 'test' } : undefined,
    rawRequest: { ip: '203.0.113.7', headers: { 'user-agent': 'Mozilla/5.0 (iPhone) Safari' } },
    acceptsStreaming: false,
  } as unknown as CallableRequest<unknown>;
}

export async function joinAs(eventId: string, name: string, interests: string[]): Promise<JoinResult> {
  return join(req({ eventId, joinCode: joinCode(eventId), displayName: name, interests }));
}

export function qrOf(eventId: string, player: JoinResult, offsetWindows = 0): string {
  const w = windowOf(Date.now(), DEFAULT_SETTINGS.tokenWindowSec) + offsetWindows;
  return `https://example.web.app/#/c/${player.playerCode}.${tokenFor(player.totpSeed, eventId, w).qr}`;
}

export function manualOf(eventId: string, player: JoinResult): string {
  const w = windowOf(Date.now(), DEFAULT_SETTINGS.tokenWindowSec);
  return `${player.playerCode}-${tokenFor(player.totpSeed, eventId, w).digits}`;
}

export function as(eventId: string, player: JoinResult): Caller {
  return { uid: player.uid, eventId };
}

/** Resolves to the failure `reason`, or throws if the call succeeded. */
export async function reasonOf(call: Promise<unknown>): Promise<string> {
  try {
    await call;
  } catch (error) {
    if (error instanceof HttpsError) return (error.details as { reason: string }).reason;
    if (error && typeof error === 'object' && 'reason' in error) return String((error as { reason: unknown }).reason);
    throw error;
  }
  throw new Error('expected the call to fail');
}

export { db, paths };
