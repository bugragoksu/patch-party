import catalog from '../generated/interests.json' with { type: 'json' };

// Pure game rules shared by the handlers. No Firebase imports in this folder.

export const INTEREST_IDS: ReadonlySet<string> = new Set(catalog.interests.map((i) => i.id));
export const MIN_PICK = catalog.minPick;
export const MAX_PICK = catalog.maxPick;

export function validInterests(ids: readonly string[]): boolean {
  return (
    ids.length >= MIN_PICK &&
    ids.length <= MAX_PICK &&
    new Set(ids).size === ids.length &&
    ids.every((id) => INTEREST_IDS.has(id))
  );
}

export interface Points {
  base: number;
  bonus: number;
  total: number;
}

/** FR-11: +10 per connection, +5 when the two players share no interest. Both players get it. */
export function pointsFor(a: readonly string[], b: readonly string[]): Points {
  const shared = a.some((id) => b.includes(id));
  const bonus = shared ? 0 : 5;
  return { base: 10, bonus, total: 10 + bonus };
}

/** One document per unordered pair. */
export function pairId(uidA: string, uidB: string): string {
  return uidA < uidB ? `${uidA}_${uidB}` : `${uidB}_${uidA}`;
}

export type EventState = 'draft' | 'lobby' | 'live' | 'ended' | 'archived';

const TRANSITIONS: Record<EventState, readonly EventState[]> = {
  draft: ['lobby'],
  lobby: ['live', 'draft'],
  live: ['lobby', 'ended'],
  ended: ['archived', 'live'],
  archived: [],
};

export function canTransition(from: EventState, to: EventState): boolean {
  return TRANSITIONS[from].includes(to);
}

export interface LiveWindow {
  state: EventState;
  liveStartAt?: number | null;
  liveEndAt?: number | null;
}

export function isLive(event: LiveWindow, nowMs: number): boolean {
  if (event.state !== 'live') return false;
  if (event.liveStartAt != null && nowMs < event.liveStartAt) return false;
  if (event.liveEndAt != null && nowMs >= event.liveEndAt) return false;
  return true;
}

export function canJoin(event: LiveWindow): boolean {
  return event.state === 'lobby' || event.state === 'live';
}

const PLAYER_CODE_ALPHABET = 'ABCDEFGHJKMNPQRSTUVWXYZ23456789';

export function randomPlayerCode(random: () => number = Math.random): string {
  let code = '';
  for (let i = 0; i < 3; i++) code += PLAYER_CODE_ALPHABET[Math.floor(random() * PLAYER_CODE_ALPHABET.length)];
  return code;
}

export type ScannedCode =
  | { kind: 'qr'; playerCode: string; token: string }
  | { kind: 'digits'; playerCode: string; token: string };

/**
 * Accepts either the QR payload (a URL ending in `/c/<code>.<token10>`, or just `<code>.<token10>`)
 * or a manually typed short code (`K7M-4821`, separators optional).
 */
export function parseScannedCode(raw: string): ScannedCode | null {
  const input = raw.trim().toUpperCase();
  const qr = /(?:^|\/C\/)([A-Z2-9]{3})\.([0-9A-HJKMNP-TV-Z]{10})$/.exec(input);
  if (qr) return { kind: 'qr', playerCode: qr[1]!, token: qr[2]! };
  const manual = /^([A-Z2-9]{3})[\s-]*([0-9]{4})$/.exec(input);
  if (manual) return { kind: 'digits', playerCode: manual[1]!, token: manual[2]! };
  return null;
}

export interface RankInput {
  uid: string;
  score: number;
  lastConnectionAt: number | null;
  disqualified: boolean;
}

/** FR-24: higher score first, ties broken by who reached the score first. */
export function computeRanks(players: readonly RankInput[]): Map<string, number> {
  const eligible = players.filter((p) => !p.disqualified);
  eligible.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    const ta = a.lastConnectionAt ?? Number.MAX_SAFE_INTEGER;
    const tb = b.lastConnectionAt ?? Number.MAX_SAFE_INTEGER;
    if (ta !== tb) return ta - tb;
    return a.uid < b.uid ? -1 : 1;
  });
  return new Map(eligible.map((p, i) => [p.uid, i + 1]));
}

export type BadgeId = 'first_connection' | 'bridge' | 'explorer' | 'social_butterfly';

export interface BadgeStats {
  connectionCount: number;
  bridgeCount: number;
  clustersMet: number;
}

/** P1 badges, derived from counters the connection transaction already updates. */
export function earnedBadges(stats: BadgeStats): BadgeId[] {
  const out: BadgeId[] = [];
  if (stats.connectionCount >= 1) out.push('first_connection');
  if (stats.bridgeCount >= 1) out.push('bridge');
  if (stats.clustersMet >= 4) out.push('explorer');
  if (stats.connectionCount >= 10) out.push('social_butterfly');
  return out;
}

export function clusterOf(interestId: string): string | undefined {
  return catalog.interests.find((i) => i.id === interestId)?.cluster;
}
