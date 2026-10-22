import { describe, expect, it } from 'vitest';
import {
  canTransition,
  computeRanks,
  earnedBadges,
  isLive,
  pairId,
  parseScannedCode,
  validInterests,
} from '../../src/domain/rules.js';
import { isOffensive, nameSuggestions } from '../../src/domain/names.js';

describe('validInterests', () => {
  it('needs 2-3 unique catalog ids', () => {
    expect(validInterests(['flutter', 'ai'])).toBe(true);
    expect(validInterests(['flutter', 'ai', 'devops'])).toBe(true);
    expect(validInterests(['flutter'])).toBe(false);
    expect(validInterests(['flutter', 'ai', 'devops', 'web'])).toBe(false);
    expect(validInterests(['flutter', 'flutter'])).toBe(false);
    expect(validInterests(['flutter', 'coffee'])).toBe(false);
  });
});

describe('pairId', () => {
  it('is order independent', () => {
    expect(pairId('b', 'a')).toBe('a_b');
    expect(pairId('a', 'b')).toBe('a_b');
  });
});

describe('event state', () => {
  it('allows only the defined transitions', () => {
    expect(canTransition('draft', 'lobby')).toBe(true);
    expect(canTransition('lobby', 'live')).toBe(true);
    expect(canTransition('live', 'lobby')).toBe(true);
    expect(canTransition('live', 'ended')).toBe(true);
    expect(canTransition('ended', 'archived')).toBe(true);
    expect(canTransition('draft', 'live')).toBe(false);
    expect(canTransition('archived', 'live')).toBe(false);
  });

  it('respects the optional live window', () => {
    expect(isLive({ state: 'live' }, 100)).toBe(true);
    expect(isLive({ state: 'live', liveStartAt: 200 }, 100)).toBe(false);
    expect(isLive({ state: 'live', liveEndAt: 100 }, 100)).toBe(false);
    expect(isLive({ state: 'lobby' }, 100)).toBe(false);
  });
});

describe('parseScannedCode', () => {
  it('reads the QR url, the bare payload and the manual code', () => {
    expect(parseScannedCode('https://x.web.app/#/c/K7M.SMW3VDRMVC')).toEqual({
      kind: 'qr',
      playerCode: 'K7M',
      token: 'SMW3VDRMVC',
    });
    expect(parseScannedCode('k7m.smw3vdrmvc')?.kind).toBe('qr');
    expect(parseScannedCode('K7M-4821')).toEqual({ kind: 'digits', playerCode: 'K7M', token: '4821' });
    expect(parseScannedCode(' k7m 4821 ')).toEqual({ kind: 'digits', playerCode: 'K7M', token: '4821' });
  });

  it('rejects anything else', () => {
    expect(parseScannedCode('hello')).toBeNull();
    expect(parseScannedCode('K7M-482')).toBeNull();
    expect(parseScannedCode('https://evil.example/#/c/K7M.SHORT')).toBeNull();
  });
});

describe('computeRanks', () => {
  it('orders by score, then by who got there first, and skips disqualified players', () => {
    const ranks = computeRanks([
      { uid: 'a', score: 20, lastConnectionAt: 300, disqualified: false },
      { uid: 'b', score: 30, lastConnectionAt: 500, disqualified: false },
      { uid: 'c', score: 20, lastConnectionAt: 100, disqualified: false },
      { uid: 'd', score: 99, lastConnectionAt: 50, disqualified: true },
    ]);
    expect([...ranks.entries()]).toEqual([
      ['b', 1],
      ['c', 2],
      ['a', 3],
    ]);
  });
});

describe('badges', () => {
  it('derives badges from counters', () => {
    expect(earnedBadges({ connectionCount: 0, bridgeCount: 0, clustersMet: 0 })).toEqual([]);
    expect(earnedBadges({ connectionCount: 10, bridgeCount: 1, clustersMet: 4 })).toEqual([
      'first_connection',
      'bridge',
      'explorer',
      'social_butterfly',
    ]);
  });
});

describe('names', () => {
  it('suggests numbered variants within the length limit', () => {
    const gen = nameSuggestions('Deniz');
    expect(gen.next().value).toBe('Deniz 2');
    expect(gen.next().value).toBe('Deniz 3');
    const long = nameSuggestions('Abcdefghijklmnopqrstuvwx').next().value as string;
    expect([...long].length).toBeLessThanOrEqual(24);
  });

  it('flags a few offensive words regardless of case and Turkish letters', () => {
    expect(isOffensive('AMK')).toBe(true);
    expect(isOffensive('Deniz')).toBe(false);
  });
});
