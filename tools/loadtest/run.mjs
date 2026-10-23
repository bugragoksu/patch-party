#!/usr/bin/env node
// T13 load test: N virtual players join, scan each other and confirm, through
// the real callables, using the Firebase JS SDK like the app does.
//   node tools/loadtest/run.mjs --emulator [--players 150] [--minutes 3]
// Against a real project only with --project <id> and an event in `live`
// state; never against prod during the event.
import { createRequire } from 'node:module';
import { performance } from 'node:perf_hooks';

const require = createRequire(new URL('../../functions/package.json', import.meta.url));
const { initializeApp } = require('firebase/app');
const { getAuth, connectAuthEmulator, signInWithCustomToken } = require('firebase/auth');
const { getFunctions, connectFunctionsEmulator, httpsCallable } = require('firebase/functions');
const { tokenFor, windowOf, joinCodeFor } = await import('../../functions/lib/domain/totp.js');

const args = Object.fromEntries(
  process.argv.slice(2).reduce((acc, a, i, all) => {
    if (a.startsWith('--')) acc.push([a.slice(2), all[i + 1]?.startsWith('--') || all[i + 1] === undefined ? 'true' : all[i + 1]]);
    return acc;
  }, []),
);
const emulator = args.emulator === 'true';
const projectId = emulator ? 'demo-baglanti' : args.project;
const eventId = args.event ?? 'gdg-adana-2026-10';
const players = Number(args.players ?? 150);
const minutes = Number(args.minutes ?? 3);
const joinSeed = args.joinSeed;
if (!projectId) {
  console.error('usage: --emulator | --project <id> [--joinSeed seed] [--event id] [--players n] [--minutes m]');
  process.exit(2);
}

const INTERESTS = ['flutter', 'web', 'gamedev', 'ai', 'data', 'opensource', 'design', 'product', 'community', 'backend', 'devops', 'security'];
const pick = (n) => [...INTERESTS].sort(() => Math.random() - 0.5).slice(0, n);
const latencies = { join: [], request: [], respond: [] };
const reasons = {};
let connections = 0;

/** Reads the join seed with the Admin SDK (emulator, or ADC for a real project). */
async function readJoinSeed() {
  if (joinSeed) return joinSeed;
  const { initializeApp: adminInit, getApp } = require('firebase-admin/app');
  const { getFirestore } = require('firebase-admin/firestore');
  if (emulator) process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
  adminInit({ projectId }, 'loadtest-admin');
  const db = getFirestore(getApp('loadtest-admin'));
  return (await db.doc(`events/${eventId}/private/joinSecret`).get()).get('joinSeed');
}

function client(i) {
  const app = initializeApp({ apiKey: 'demo-key', projectId, appId: '1:1:web:1' }, `p${i}`);
  const auth = getAuth(app);
  const functions = getFunctions(app, 'europe-west3');
  if (emulator) {
    connectAuthEmulator(auth, 'http://127.0.0.1:9099', { disableWarnings: true });
    connectFunctionsEmulator(functions, '127.0.0.1', 5001);
  }
  const call = (name) => async (data) => {
    const started = performance.now();
    try {
      const res = await httpsCallable(functions, name)(data);
      return { ok: true, data: res.data, ms: performance.now() - started };
    } catch (e) {
      const reason = e?.details?.reason ?? e?.code ?? 'unknown';
      reasons[reason] = (reasons[reason] ?? 0) + 1;
      return { ok: false, reason, ms: performance.now() - started };
    }
  };
  return { auth, join: call('join'), request: call('requestConnection'), respond: call('respondToRequest') };
}

const pct = (xs, p) => {
  if (!xs.length) return 0;
  const s = [...xs].sort((a, b) => a - b);
  return Math.round(s[Math.min(s.length - 1, Math.floor((p / 100) * s.length))]);
};

const run = Math.random().toString(36).slice(2, 6);
const seed = await readJoinSeed();
const code = joinCodeFor(seed, eventId, windowOf(Date.now(), 300));
console.log(`joining ${players} players…`);
const crowd = [];
await Promise.all(
  Array.from({ length: players }, async (_, i) => {
    const c = client(i);
    const r = await c.join({ eventId, joinCode: code, displayName: `Yük ${run} ${i + 1}`, interests: pick(2 + (i % 2)) });
    latencies.join.push(r.ms);
    if (!r.ok) return;
    await signInWithCustomToken(c.auth, r.data.customToken);
    crowd.push({ ...c, uid: r.data.uid, playerCode: r.data.playerCode, seed: r.data.totpSeed });
  }),
);
console.log(`joined ${crowd.length}/${players}`);

const end = Date.now() + minutes * 60_000;
await Promise.all(
  crowd.map(async (me) => {
    while (Date.now() < end) {
      await new Promise((r) => setTimeout(r, 3000 + Math.random() * 12_000));
      const target = crowd[Math.floor(Math.random() * crowd.length)];
      if (target.uid === me.uid) continue;
      const bad = Math.random() < 0.1;
      const token = bad ? '0000000000' : tokenFor(target.seed, eventId, windowOf(Date.now(), 30)).qr;
      const sent = await me.request({ eventId, code: `${target.playerCode}.${token}` });
      latencies.request.push(sent.ms);
      if (!sent.ok || sent.data.status !== 'pending') {
        if (sent.ok) connections++;
        continue;
      }
      await new Promise((r) => setTimeout(r, 500 + Math.random() * 3000));
      const answer = await target.respond({ eventId, requestId: sent.data.requestId, accept: Math.random() > 0.1 });
      latencies.respond.push(answer.ms);
      if (answer.ok && answer.data.status === 'accepted') connections++;
    }
  }),
);

const line = (name) =>
  `${name.padEnd(8)} n=${String(latencies[name].length).padStart(5)}  p50=${pct(latencies[name], 50)}ms  p95=${pct(latencies[name], 95)}ms  max=${pct(latencies[name], 100)}ms`;
console.log(['', line('join'), line('request'), line('respond'), `connections=${connections}`, `rejections=${JSON.stringify(reasons)}`].join('\n'));
process.exit(0);
