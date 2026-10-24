import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore, type Firestore } from 'firebase-admin/firestore';
import { DEFAULT_SETTINGS, type EventDoc } from './model.js';
import { GameError } from '../infra/errors.js';

if (getApps().length === 0) initializeApp();

export const db: Firestore = getFirestore();

export const paths = {
  event: (e: string) => db.doc(`events/${e}`),
  joinSecret: (e: string) => db.doc(`events/${e}/private/joinSecret`),
  player: (e: string, uid: string) => db.doc(`events/${e}/players/${uid}`),
  players: (e: string) => db.collection(`events/${e}/players`),
  playerSecret: (e: string, uid: string) => db.doc(`events/${e}/playerSecrets/${uid}`),
  playerCode: (e: string, code: string) => db.doc(`events/${e}/playerCodes/${code}`),
  displayName: (e: string, key: string) => db.doc(`events/${e}/displayNames/${key}`),
  request: (e: string, id: string) => db.doc(`events/${e}/connectionRequests/${id}`),
  requests: (e: string) => db.collection(`events/${e}/connectionRequests`),
  connection: (e: string, id: string) => db.doc(`events/${e}/connections/${id}`),
  rateLimit: (e: string, uid: string) => db.doc(`events/${e}/rateLimits/${uid}`),
  joinAudit: (e: string, uid: string) => db.doc(`events/${e}/joinAudit/${uid}`),
  auditLog: (e: string) => db.collection(`events/${e}/auditLog`),
};

/** Event with settings merged over defaults, so a partially seeded event still works. */
export function readEvent(data: FirebaseFirestore.DocumentData | undefined): EventDoc {
  if (!data) throw new GameError('not_found', { what: 'event' });
  return {
    name: data.name ?? '',
    state: data.state ?? 'draft',
    liveStartAt: data.liveStartAt ?? null,
    liveEndAt: data.liveEndAt ?? null,
    settings: { ...DEFAULT_SETTINGS, ...(data.settings ?? {}), features: { ...DEFAULT_SETTINGS.features, ...(data.settings?.features ?? {}) } },
    reveal: data.reveal ?? 0,
    updatedAt: data.updatedAt ?? 0,
  };
}
