import { beforeEach, describe, expect, it } from 'vitest';
import {
  cancelRequest,
  requestConnection,
  respondToRequest,
} from '../../src/handlers/connections.js';
import { join } from '../../src/handlers/join.js';
import { moderatePlayer, purgeEvent, setEventState } from '../../src/handlers/admin.js';
import { rankEvent } from '../../src/handlers/ranks.js';
import type { ConnectionDoc, PlayerDoc } from '../../src/data/model.js';
import { as, joinAs, joinCode, manualOf, paths, qrOf, reasonOf, req, seedEvent, uniqueEventId } from './helpers.js';

let eventId: string;

beforeEach(async () => {
  eventId = uniqueEventId();
  await seedEvent(eventId);
});

async function player(uid: string): Promise<PlayerDoc> {
  return (await paths.player(eventId, uid).get()).data() as PlayerDoc;
}

describe('join', () => {
  it('creates a player and returns a custom token, code and seed', async () => {
    const r = await joinAs(eventId, 'Deniz', ['flutter', 'ai']);
    expect(r.customToken).toBeTruthy();
    expect(r.playerCode).toMatch(/^[A-Z2-9]{3}$/);
    const p = await player(r.uid);
    expect(p.displayName).toBe('Deniz');
    expect(p.score).toBe(0);
    expect((await paths.playerSecret(eventId, r.uid).get()).get('totpSeed')).toBe(r.totpSeed);
  });

  it('rejects a wrong or missing join code', async () => {
    const reason = await reasonOf(
      join(req({ eventId, joinCode: 'ZZZZZZ', displayName: 'Ali', interests: ['flutter', 'ai'] })),
    );
    expect(reason).toBe('join_code_invalid');
  });

  it('accepts the join code with separators and lowercase', async () => {
    const code = joinCode(eventId);
    const r = await join(
      req({ eventId, joinCode: `${code.slice(0, 3).toLowerCase()}-${code.slice(3)}`, displayName: 'Ali', interests: ['web', 'ai'] }),
    );
    expect(r.uid).toBeTruthy();
  });

  it('keeps names unique regardless of case and Turkish letters, and suggests a free one', async () => {
    await joinAs(eventId, 'Deniz', ['flutter', 'ai']);
    expect(await reasonOf(joinAs(eventId, 'DENİZ', ['web', 'ai']))).toBe('name_taken');
    await joinAs(eventId, 'Deniz 2', ['web', 'ai']);
    try {
      await joinAs(eventId, ' Deniz ', ['web', 'ai']);
      expect.unreachable();
    } catch (error) {
      expect((error as { details: { suggestion: string } }).details.suggestion).toBe('Deniz 3');
    }
  });

  it('gives a name to only one of two simultaneous joins', async () => {
    const results = await Promise.allSettled([
      joinAs(eventId, 'Işıl', ['flutter', 'ai']),
      joinAs(eventId, 'ISIL', ['web', 'ai']),
    ]);
    expect(results.filter((r) => r.status === 'fulfilled')).toHaveLength(1);
  });

  it('validates names and interests', async () => {
    expect(await reasonOf(joinAs(eventId, 'A', ['flutter', 'ai']))).toBe('invalid_name');
    expect(await reasonOf(joinAs(eventId, 'amk', ['flutter', 'ai']))).toBe('invalid_name');
    expect(await reasonOf(joinAs(eventId, 'Can', ['flutter']))).toBe('invalid_interests');
    expect(await reasonOf(joinAs(eventId, 'Can', ['flutter', 'coffee']))).toBe('invalid_interests');
  });

  it('is closed in draft and full at maxPlayers', async () => {
    const closed = uniqueEventId();
    await seedEvent(closed, 'draft');
    expect(await reasonOf(joinAs(closed, 'Can', ['flutter', 'ai']))).toBe('event_closed');

    const small = uniqueEventId();
    await seedEvent(small, 'lobby', { maxPlayers: 1 });
    await joinAs(small, 'Can', ['flutter', 'ai']);
    expect(await reasonOf(joinAs(small, 'Ece', ['flutter', 'ai']))).toBe('event_full');
  });
});

describe('request and confirm', () => {
  it('creates a pending request, the target accepts and both get points', async () => {
    const deniz = await joinAs(eventId, 'Deniz', ['flutter', 'ai']);
    const caner = await joinAs(eventId, 'Caner', ['design', 'backend']);

    const sent = await requestConnection(req({ eventId, code: qrOf(eventId, caner) }, as(eventId, deniz)));
    expect(sent.status).toBe('pending');
    expect(sent.target.name).toBe('Caner');
    expect((await player(deniz.uid)).outgoingRequest?.requestId).toBe(sent.requestId);

    const answer = await respondToRequest(req({ eventId, requestId: sent.requestId, accept: true }, as(eventId, caner)));
    expect(answer.status).toBe('accepted');
    expect(answer.connection).toMatchObject({ points: 15, bonus: 5 });

    const conn = (await paths.connection(eventId, sent.requestId).get()).data() as ConnectionDoc;
    expect(conn.participants.sort()).toEqual([deniz.uid, caner.uid].sort());
    expect(conn.questionKey).toMatch(/\|/);
    const [d, c] = [await player(deniz.uid), await player(caner.uid)];
    expect(d.score).toBe(15);
    expect(c.score).toBe(15);
    expect(d.badges).toEqual(['first_connection', 'bridge']);
    expect(d.outgoingRequest).toBeNull();
  });

  it('gives no bonus when interests overlap and works with the manual short code', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['flutter', 'web']);
    const sent = await requestConnection(req({ eventId, code: manualOf(eventId, b) }, as(eventId, a)));
    const answer = await respondToRequest(req({ eventId, requestId: sent.requestId, accept: true }, as(eventId, b)));
    expect(answer.connection).toMatchObject({ points: 10, bonus: 0, questionKey: 'flutter|flutter' });
  });

  it('accepts a token from the previous window but not older', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const c = await joinAs(eventId, 'Cem', ['web', 'data']);
    expect((await requestConnection(req({ eventId, code: qrOf(eventId, b, -1) }, as(eventId, a)))).status).toBe('pending');
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, c, -2) }, as(eventId, b))))).toBe('token_invalid');
  });

  it('rejects self scans, unknown codes and players of other events', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, a) }, as(eventId, a))))).toBe('self_scan');
    expect(await reasonOf(requestConnection(req({ eventId, code: 'not a code' }, as(eventId, a))))).toBe('code_invalid');
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, b) }, { uid: a.uid, eventId: 'other' })))).toBe(
      'permission_denied',
    );
  });

  it('only the target can answer, and only once', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const sent = await requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a)));
    expect(await reasonOf(respondToRequest(req({ eventId, requestId: sent.requestId, accept: true }, as(eventId, a))))).toBe(
      'permission_denied',
    );
    await respondToRequest(req({ eventId, requestId: sent.requestId, accept: true }, as(eventId, b)));
    expect(await reasonOf(respondToRequest(req({ eventId, requestId: sent.requestId, accept: true }, as(eventId, b))))).toBe(
      'request_expired',
    );
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a))))).toBe('already_connected');
  });

  it('scanning back someone who already asked you connects immediately', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    await requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a)));
    const back = await requestConnection(req({ eventId, code: qrOf(eventId, a) }, as(eventId, b)));
    expect(back.status).toBe('accepted');
    expect((await player(a.uid)).score).toBe(10);
    expect((await player(b.uid)).score).toBe(10);
  });

  it('expires requests on the server clock', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const sent = await requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a)));
    await paths.request(eventId, sent.requestId).update({ expiresAt: Date.now() - 1 });
    expect(await reasonOf(respondToRequest(req({ eventId, requestId: sent.requestId, accept: true }, as(eventId, b))))).toBe(
      'request_expired',
    );
    expect((await paths.request(eventId, sent.requestId).get()).get('status')).toBe('expired');
    expect((await player(a.uid)).outgoingRequest).toBeNull();
  });

  it('a decline blocks the same pair for a minute', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const sent = await requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a)));
    const answer = await respondToRequest(req({ eventId, requestId: sent.requestId, accept: false }, as(eventId, b)));
    expect(answer.status).toBe('declined');
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a))))).toBe('cooldown');
  });

  it('limits one outgoing and three incoming requests', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const c = await joinAs(eventId, 'Cem', ['web', 'data']);
    await requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a)));
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, c) }, as(eventId, a))))).toBe('request_limit');

    const target = await joinAs(eventId, 'Hedef', ['devops', 'security']);
    for (const name of ['Bir', 'Iki', 'Uc']) {
      const p = await joinAs(eventId, name, ['flutter', 'ai']);
      await requestConnection(req({ eventId, code: qrOf(eventId, target) }, as(eventId, p)));
    }
    const fourth = await joinAs(eventId, 'Dort', ['flutter', 'ai']);
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, target) }, as(eventId, fourth))))).toBe(
      'request_limit',
    );
  });

  it('a cancelled request frees the outgoing slot', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const c = await joinAs(eventId, 'Cem', ['web', 'data']);
    const sent = await requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a)));
    await cancelRequest(req({ eventId, requestId: sent.requestId }, as(eventId, a)));
    expect((await requestConnection(req({ eventId, code: qrOf(eventId, c) }, as(eventId, a)))).status).toBe('pending');
  });

  it('enforces the cooldown after a connection', async () => {
    const slow = uniqueEventId();
    await seedEvent(slow, 'live', { cooldownSec: 15 });
    const a = await joinAs(slow, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(slow, 'Bora', ['web', 'ai']);
    const c = await joinAs(slow, 'Cem', ['web', 'data']);
    const sent = await requestConnection(req({ eventId: slow, code: qrOf(slow, b) }, as(slow, a)));
    await respondToRequest(req({ eventId: slow, requestId: sent.requestId, accept: true }, as(slow, b)));
    expect(await reasonOf(requestConnection(req({ eventId: slow, code: qrOf(slow, c) }, as(slow, a))))).toBe('cooldown');
  });

  it('is closed outside live', async () => {
    const lobby = uniqueEventId();
    await seedEvent(lobby, 'lobby');
    const a = await joinAs(lobby, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(lobby, 'Bora', ['web', 'ai']);
    expect(await reasonOf(requestConnection(req({ eventId: lobby, code: qrOf(lobby, b) }, as(lobby, a))))).toBe('not_live');
  });

  it('blocks a player after ten bad tokens in a minute', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const bad = `${b.playerCode}.0000000000`;
    for (let i = 0; i < 10; i++) {
      expect(await reasonOf(requestConnection(req({ eventId, code: bad }, as(eventId, a))))).toBe('token_invalid');
    }
    expect(await reasonOf(requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a))))).toBe('rate_limited');
  });
});

describe('ranks and admin', () => {
  it('ranks by score and only staff can change state', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    const c = await joinAs(eventId, 'Cem', ['design', 'devops']);
    const sent = await requestConnection(req({ eventId, code: qrOf(eventId, c) }, as(eventId, a)));
    await respondToRequest(req({ eventId, requestId: sent.requestId, accept: true }, as(eventId, c)));
    await rankEvent(eventId);
    // a and c share the top score and the same connection time; uid breaks the tie.
    expect([(await player(a.uid)).rank, (await player(c.uid)).rank].sort()).toEqual([1, 2]);
    expect((await player(b.uid)).rank).toBe(3);
    expect((await player(b.uid)).rankTotal).toBe(3);

    expect(await reasonOf(setEventState(req({ eventId, state: 'ended' }, as(eventId, a))))).toBe('permission_denied');
    expect(await reasonOf(setEventState(req({ eventId, state: 'draft' }, { uid: 'boss', admin: true })))).toBe(
      'invalid_transition',
    );
    await setEventState(req({ eventId, state: 'ended' }, { uid: 'boss', admin: true }));
    expect((await paths.event(eventId).get()).get('state')).toBe('ended');
  });

  it('disqualified players drop out of the ranking', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    await moderatePlayer(req({ eventId, uid: a.uid, action: 'disqualify' }, { uid: 'boss', admin: true }));
    await rankEvent(eventId);
    expect((await player(a.uid)).rank).toBeNull();
  });

  it('rename keeps names unique', async () => {
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    await joinAs(eventId, 'Bora', ['web', 'ai']);
    expect(
      await reasonOf(moderatePlayer(req({ eventId, uid: a.uid, action: 'rename', displayName: 'BORA' }, { uid: 'boss', admin: true }))),
    ).toBe('name_taken');
    await moderatePlayer(req({ eventId, uid: a.uid, action: 'rename', displayName: 'Ada K.' }, { uid: 'boss', admin: true }));
    expect((await player(a.uid)).displayName).toBe('Ada K.');
    expect((await joinAs(eventId, 'Ada', ['web', 'ai'])).uid).toBeTruthy();
  });

  it('purge removes personal data and keeps a summary', async () => {
    await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    expect(await reasonOf(purgeEvent(req({ eventId, confirm: 'nope' }, { uid: 'boss', admin: true })))).toBe('invalid_argument');
    const result = await purgeEvent(req({ eventId, confirm: eventId }, { uid: 'boss', admin: true }));
    expect(result.deletedUsers).toBe(1);
    expect((await paths.players(eventId).get()).size).toBe(0);
    expect((await paths.event(eventId).get()).get('summary.playerCount')).toBe(1);
  });
});

describe('reopening', () => {
  it('ended -> live reopens the time window', async () => {
    const boss = { uid: 'boss', admin: true };
    await setEventState(req({ eventId, state: 'ended' }, boss));
    await setEventState(req({ eventId, state: 'live' }, boss));
    const a = await joinAs(eventId, 'Ada', ['flutter', 'ai']);
    const b = await joinAs(eventId, 'Bora', ['web', 'ai']);
    expect((await requestConnection(req({ eventId, code: qrOf(eventId, b) }, as(eventId, a)))).status).toBe('pending');
  });
});
