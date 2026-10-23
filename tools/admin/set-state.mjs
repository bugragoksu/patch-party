#!/usr/bin/env node
// Operator tool for rehearsals: sets the event state on a real project and
// prints the current join code. Prod requires --yes.
//   node tools/admin/set-state.mjs <staging|prod> <draft|lobby|live|ended> [liveMinutes] [--yes]
// Credentials: GOOGLE_APPLICATION_CREDENTIALS (see docs/ops/runbook.md).
import { createRequire } from 'node:module';
import { loadEnv } from '../env.mjs';

const require = createRequire(new URL('../../functions/package.json', import.meta.url));
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { joinCodeFor, windowOf } = await import('../../functions/lib/domain/totp.js');

const args = process.argv.slice(2).filter((a) => a !== '--yes');
const [envName, state, minutes] = args;
if (!['staging', 'prod'].includes(envName) || !['draft', 'lobby', 'live', 'ended'].includes(state)) {
  console.error('usage: node tools/admin/set-state.mjs <staging|prod> <draft|lobby|live|ended> [liveMinutes] [--yes]');
  process.exit(2);
}
if (envName === 'prod' && !process.argv.includes('--yes')) {
  console.error('refusing to change prod without --yes');
  process.exit(2);
}
const env = loadEnv(envName);
initializeApp({ projectId: env.FIREBASE_PROJECT_ID });
const db = getFirestore();
const eventId = env.APP_EVENT_ID;
const now = Date.now();
const patch = { state, updatedAt: now };
if (state === 'live') {
  patch.liveStartAt = now;
  patch.liveEndAt = minutes ? now + Number(minutes) * 60_000 : null;
}
await db.doc(`events/${eventId}`).update(patch);
const seed = (await db.doc(`events/${eventId}/private/joinSecret`).get()).get('joinSeed');
const code = joinCodeFor(seed, eventId, windowOf(now, 300));
console.log(`${envName}: ${eventId} state=${state} joinCode=${code} (valid ~5-10 min)`);
