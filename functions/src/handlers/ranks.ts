import { logger } from 'firebase-functions/v2';
import { db, paths } from '../data/db.js';
import type { PlayerDoc } from '../data/model.js';
import { computeRanks } from '../domain/rules.js';

/** Writes rank only to players whose rank changed (ADR-0014). */
export async function rankEvent(eventId: string, now = Date.now()): Promise<number> {
  const snap = await paths.players(eventId).get();
  const players = snap.docs.map((d) => ({ uid: d.id, data: d.data() as PlayerDoc }));
  const ranks = computeRanks(
    players.map((p) => ({
      uid: p.uid,
      score: p.data.score,
      lastConnectionAt: p.data.lastConnectionAt,
      disqualified: p.data.disqualified,
    })),
  );
  const total = ranks.size;
  let writes = 0;
  let batch = db.batch();
  for (const p of players) {
    const rank = ranks.get(p.uid) ?? null;
    if (p.data.rank === rank && p.data.rankTotal === total) continue;
    batch.update(paths.player(eventId, p.uid), { rank, rankTotal: total, rankedAt: now });
    if (++writes % 400 === 0) {
      await batch.commit();
      batch = db.batch();
    }
  }
  if (writes % 400 !== 0) await batch.commit();
  return writes;
}

export async function rankLiveEvents(): Promise<void> {
  const live = await db.collection('events').where('state', '==', 'live').get();
  for (const event of live.docs) {
    const writes = await rankEvent(event.id);
    logger.info('ranks_computed', { eventId: event.id, writes });
  }
}
