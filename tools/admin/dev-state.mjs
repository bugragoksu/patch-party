#!/usr/bin/env node
// Emulator-only helper for local testing: sets the event state and prints the
// current join code. Never runs against a real project.
//   node tools/admin/dev-state.mjs <eventId> <draft|lobby|live|ended> [liveMinutes]
import { createRequire } from 'node:module';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
const require = createRequire(new URL('../../functions/package.json', import.meta.url));
const { initializeApp } = require('firebase-admin/app');
const { getFirestore } = require('firebase-admin/firestore');
const { joinCodeFor, windowOf } = await import('../../functions/lib/domain/totp.js');

const [eventId, state, minutes] = process.argv.slice(2);
if (!eventId || !['draft', 'lobby', 'live', 'ended'].includes(state)) {
  console.error('usage: node tools/admin/dev-state.mjs <eventId> <draft|lobby|live|ended> [liveMinutes]');
  process.exit(2);
}
initializeApp({ projectId: 'demo-baglanti' });
const db = getFirestore();
const now = Date.now();
const patch = { state, updatedAt: now };
if (state === 'live') {
  patch.liveStartAt = now;
  patch.liveEndAt = minutes ? now + Number(minutes) * 60_000 : null;
}
await db.doc(`events/${eventId}`).update(patch);
const seed = (await db.doc(`events/${eventId}/private/joinSecret`).get()).get('joinSeed');
const code = joinCodeFor(seed, eventId, windowOf(now, 300));
console.log(`state=${state} joinCode=${code} url=/j/${code}`);
