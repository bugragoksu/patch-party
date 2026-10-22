#!/usr/bin/env node
// Creates or updates the event document and its join seed from .env.<env>,
// and assigns admin/projector custom claims (SEC-40). Uses Application Default
// Credentials (`gcloud auth application-default login`) or the emulators.
//
//   node tools/admin/setup-event.mjs <staging|prod> [--emulator]
import { randomBytes } from 'node:crypto';
import { createRequire } from 'node:module';
import { loadEnv } from '../env.mjs';

const require = createRequire(new URL('../../functions/package.json', import.meta.url));
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { getFirestore } = require('firebase-admin/firestore');

const [envName, flag] = process.argv.slice(2);
if (!['staging', 'prod'].includes(envName)) {
  console.error('usage: node tools/admin/setup-event.mjs <staging|prod> [--emulator]');
  process.exit(2);
}
const env = loadEnv(envName);
const emulator = flag === '--emulator';
const projectId = emulator ? 'demo-baglanti' : env.FIREBASE_PROJECT_ID;
if (emulator) {
  process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
  process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
}
const eventId = env.APP_EVENT_ID;
if (!eventId) throw new Error('APP_EVENT_ID is empty');

initializeApp({ projectId });
const db = getFirestore();
const num = (k, d) => (env[k] ? Number(env[k]) : d);

const eventRef = db.doc(`events/${eventId}`);
const existing = await eventRef.get();
const settings = {
  cooldownSec: num('GAME_COOLDOWN_SEC', 15),
  tokenWindowSec: num('GAME_TOKEN_WINDOW_SEC', 30),
  joinWindowSec: 300,
  requestTtlSec: num('GAME_REQUEST_TTL_SEC', 45),
  maxConnPerPlayer: num('GAME_MAX_CONNECTIONS_PER_PLAYER', 60),
  maxPlayers: num('GAME_MAX_PLAYERS', 200),
  appCheckEnforce: env.GAME_APP_CHECK_ENFORCE === 'true',
  displayName: env.EVENT_DISPLAY_NAME || 'Bağlantı Ağı',
  subtitle: env.EVENT_SUBTITLE || '',
  prizes: [env.EVENT_PRIZE_1, env.EVENT_PRIZE_2, env.EVENT_PRIZE_3].filter(Boolean),
  features: { badges: true, playerRank: true },
};
await eventRef.set(
  {
    name: settings.displayName,
    ...(existing.exists ? {} : { state: 'draft', liveStartAt: null, liveEndAt: null }),
    settings,
    updatedAt: Date.now(),
  },
  { merge: true },
);
const secretRef = db.doc(`events/${eventId}/private/joinSecret`);
if (!(await secretRef.get()).exists) await secretRef.set({ joinSeed: randomBytes(32).toString('base64url') });
console.log(`event ${eventId} ready (${existing.exists ? 'updated' : 'created'})`);

const emails = (key) => (env[key] || '').split(',').map((s) => s.trim()).filter(Boolean);
for (const [key, claim] of [['ADMIN_EMAILS', { admin: true }], ['PROJECTOR_EMAILS', { projector: true }]]) {
  for (const email of emails(key)) {
    try {
      const user = await getAuth().getUserByEmail(email);
      await getAuth().setCustomUserClaims(user.uid, { ...(user.customClaims ?? {}), ...claim });
      console.log(`claim ${Object.keys(claim)[0]} set for one ${key === 'ADMIN_EMAILS' ? 'admin' : 'projector'} account`);
    } catch {
      console.warn(`${key}: an account has not signed in yet; ask it to sign in once, then rerun`);
    }
  }
}
