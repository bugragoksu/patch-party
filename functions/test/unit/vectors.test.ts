import { readFileSync } from 'node:fs';
import { resolve } from 'node:path';
import { describe, expect, it } from 'vitest';
import { tokenFor, windowOf, verifyToken } from '../../src/domain/totp.js';
import { cleanDisplayName, isValidDisplayName, normalizeName } from '../../src/domain/names.js';
import { pointsFor } from '../../src/domain/rules.js';

const vectors = (name: string) =>
  JSON.parse(readFileSync(resolve(import.meta.dirname, '../../../shared/test-vectors', name), 'utf8'));

describe('shared vectors: totp', () => {
  for (const c of vectors('totp.json').cases) {
    it(`${c.eventId} @ ${c.unixMs}`, () => {
      expect(windowOf(c.unixMs, c.windowSec)).toBe(c.window);
      expect(tokenFor(c.seed, c.eventId, c.window)).toEqual({ qr: c.qr, digits: c.digits });
    });
  }
});

describe('shared vectors: names', () => {
  for (const c of vectors('names.json').cases) {
    it(JSON.stringify(c.input), () => {
      expect(cleanDisplayName(c.input)).toBe(c.clean);
      expect(normalizeName(c.input)).toBe(c.key);
      expect(isValidDisplayName(c.input)).toBe(c.valid);
    });
  }
});

describe('shared vectors: scoring', () => {
  for (const c of vectors('scoring.json').cases) {
    it(`${c.a} x ${c.b}`, () => {
      expect(pointsFor(c.a, c.b)).toEqual({ base: c.base, bonus: c.bonus, total: c.total });
    });
  }
});

describe('verifyToken', () => {
  const seed = 'q8Jz0wq3m1sV0b4w6m3n2r8yZt5uQe1fWv9kLp0xYcA';
  const t0 = 1792900800000;
  const current = tokenFor(seed, 'e', windowOf(t0, 30));

  it('accepts the current, the previous and the next window', () => {
    expect(verifyToken(seed, 'e', current.qr, 'qr', t0, 30)).toBe(true);
    expect(verifyToken(seed, 'e', current.qr, 'qr', t0 + 30_000, 30)).toBe(true);
    expect(verifyToken(seed, 'e', current.qr, 'qr', t0 - 30_000, 30)).toBe(true);
  });

  it('rejects a token two windows off, from another event, or of the wrong kind', () => {
    expect(verifyToken(seed, 'e', current.qr, 'qr', t0 + 60_000, 30)).toBe(false);
    expect(verifyToken(seed, 'e', current.qr, 'qr', t0 - 60_000, 30)).toBe(false);
    expect(verifyToken(seed, 'other', current.qr, 'qr', t0, 30)).toBe(false);
    expect(verifyToken(seed, 'e', current.digits, 'qr', t0, 30)).toBe(false);
  });
});
