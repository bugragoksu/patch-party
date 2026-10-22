import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
  type RulesTestEnvironment,
} from '@firebase/rules-unit-testing';
import { collection, doc, getDoc, getDocs, limit, query, setDoc, updateDoc, where } from 'firebase/firestore';
import { afterAll, beforeAll, describe, it } from 'vitest';

const E = 'evt';
let env: RulesTestEnvironment;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-baglanti-rules',
    firestore: { rules: readFileSync(resolve(import.meta.dirname, '../../../firebase/firestore.rules'), 'utf8') },
  });
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, `events/${E}`), { name: 'T', state: 'live' });
    await setDoc(doc(db, `events/${E}/private/joinSecret`), { joinSeed: 'x' });
    await setDoc(doc(db, `events/${E}/players/alice`), { displayName: 'Alice', score: 0 });
    await setDoc(doc(db, `events/${E}/players/bob`), { displayName: 'Bob', score: 0 });
    await setDoc(doc(db, `events/${E}/playerSecrets/alice`), { totpSeed: 's1' });
    await setDoc(doc(db, `events/${E}/playerSecrets/bob`), { totpSeed: 's2' });
    await setDoc(doc(db, `events/${E}/playerCodes/K7M`), { uid: 'alice' });
    await setDoc(doc(db, `events/${E}/displayNames/alice`), { uid: 'alice' });
    await setDoc(doc(db, `events/${E}/connections/alice_bob`), { participants: ['alice', 'bob'], createdAt: 1 });
    await setDoc(doc(db, `events/${E}/connections/bob_carol`), { participants: ['bob', 'carol'], createdAt: 2 });
    await setDoc(doc(db, `events/${E}/connectionRequests/alice_bob`), { fromUid: 'alice', toUid: 'bob', status: 'pending' });
    await setDoc(doc(db, `events/${E}/rateLimits/alice`), { failures: 1 });
  });
});

afterAll(async () => {
  await env.cleanup();
});

const player = (uid: string, eventId = E) => env.authenticatedContext(uid, { eventId }).firestore();
const projector = () => env.authenticatedContext('screen', { projector: true }).firestore();
const admin = () => env.authenticatedContext('boss', { admin: true }).firestore();
const anon = () => env.unauthenticatedContext().firestore();

describe('nobody writes from the client', () => {
  it('denies writes for players, staff and admins alike', async () => {
    for (const db of [player('alice'), projector(), admin()]) {
      await assertFails(setDoc(doc(db, `events/${E}/players/alice`), { score: 999 }));
      await assertFails(updateDoc(doc(db, `events/${E}/players/alice`), { score: 999 }));
      await assertFails(setDoc(doc(db, `events/${E}`), { state: 'ended' }));
      await assertFails(setDoc(doc(db, `events/${E}/connections/x_y`), { participants: ['x', 'y'] }));
    }
  });
});

describe('events', () => {
  it('anyone can read an event document, only staff can list events', async () => {
    await assertSucceeds(getDoc(doc(anon(), `events/${E}`)));
    await assertFails(getDocs(collection(anon(), 'events')));
    await assertFails(getDocs(collection(player('alice'), 'events')));
    await assertSucceeds(getDocs(collection(projector(), 'events')));
  });

  it('the join seed is staff only', async () => {
    await assertFails(getDoc(doc(player('alice'), `events/${E}/private/joinSecret`)));
    await assertFails(getDoc(doc(anon(), `events/${E}/private/joinSecret`)));
    await assertSucceeds(getDoc(doc(projector(), `events/${E}/private/joinSecret`)));
  });
});

describe('players', () => {
  it('players of the event can read a player, others cannot', async () => {
    await assertSucceeds(getDoc(doc(player('alice'), `events/${E}/players/bob`)));
    await assertFails(getDoc(doc(player('mallory', 'other'), `events/${E}/players/bob`)));
    await assertFails(getDoc(doc(anon(), `events/${E}/players/bob`)));
  });

  it('players may list at most 20, staff may list everyone', async () => {
    await assertSucceeds(getDocs(query(collection(player('alice'), `events/${E}/players`), limit(20))));
    await assertFails(getDocs(query(collection(player('alice'), `events/${E}/players`), limit(21))));
    await assertFails(getDocs(collection(player('alice'), `events/${E}/players`)));
    await assertSucceeds(getDocs(collection(projector(), `events/${E}/players`)));
  });
});

describe('secrets and lookup tables', () => {
  it('only the owner reads their own seed', async () => {
    await assertSucceeds(getDoc(doc(player('alice'), `events/${E}/playerSecrets/alice`)));
    await assertFails(getDoc(doc(player('alice'), `events/${E}/playerSecrets/bob`)));
    await assertFails(getDoc(doc(player('alice', 'other'), `events/${E}/playerSecrets/alice`)));
    await assertFails(getDoc(doc(admin(), `events/${E}/playerSecrets/alice`)));
  });

  it('player codes and display names are never readable', async () => {
    await assertFails(getDoc(doc(player('alice'), `events/${E}/playerCodes/K7M`)));
    await assertFails(getDocs(collection(admin(), `events/${E}/playerCodes`)));
    await assertFails(getDoc(doc(player('alice'), `events/${E}/displayNames/alice`)));
  });
});

describe('connections and requests', () => {
  it('a player sees only their own connections, at most 100 per query', async () => {
    const db = player('alice');
    await assertSucceeds(getDoc(doc(db, `events/${E}/connections/alice_bob`)));
    await assertFails(getDoc(doc(db, `events/${E}/connections/bob_carol`)));
    await assertSucceeds(
      getDocs(query(collection(db, `events/${E}/connections`), where('participants', 'array-contains', 'alice'), limit(100))),
    );
    await assertFails(getDocs(query(collection(db, `events/${E}/connections`), limit(10))));
    await assertSucceeds(getDocs(collection(projector(), `events/${E}/connections`)));
  });

  it('a request is visible to its two sides only', async () => {
    await assertSucceeds(getDoc(doc(player('alice'), `events/${E}/connectionRequests/alice_bob`)));
    await assertSucceeds(getDoc(doc(player('bob'), `events/${E}/connectionRequests/alice_bob`)));
    await assertFails(getDoc(doc(player('carol'), `events/${E}/connectionRequests/alice_bob`)));
    await assertSucceeds(
      getDocs(
        query(collection(player('bob'), `events/${E}/connectionRequests`), where('toUid', '==', 'bob'), limit(3)),
      ),
    );
  });
});

describe('admin-only collections', () => {
  it('rate limits are admin only', async () => {
    await assertFails(getDoc(doc(player('alice'), `events/${E}/rateLimits/alice`)));
    await assertFails(getDoc(doc(projector(), `events/${E}/rateLimits/alice`)));
    await assertSucceeds(getDoc(doc(admin(), `events/${E}/rateLimits/alice`)));
  });
});
