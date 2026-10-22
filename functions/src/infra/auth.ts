import type { CallableRequest } from 'firebase-functions/v2/https';
import { GameError } from './errors.js';
import type { EventSettings } from '../data/model.js';

export function requireUid(request: CallableRequest<unknown>): string {
  const uid = request.auth?.uid;
  if (!uid) throw new GameError('unauthenticated');
  return uid;
}

export function requireAdmin(request: CallableRequest<unknown>): string {
  const uid = requireUid(request);
  if (request.auth?.token.admin !== true) throw new GameError('permission_denied');
  return uid;
}

/** The player's custom token carries the event it was issued for. */
export function requirePlayerOf(request: CallableRequest<unknown>, eventId: string): string {
  const uid = requireUid(request);
  if (request.auth?.token.eventId !== eventId) throw new GameError('permission_denied');
  return uid;
}

/** App Check is monitor-only until the rehearsal proves it safe (ADR-0012). */
export function checkAppCheck(request: CallableRequest<unknown>, settings: EventSettings): void {
  if (settings.appCheckEnforce && !request.app) throw new GameError('permission_denied', { appCheck: true });
}
