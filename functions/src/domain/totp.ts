import { createHmac, randomBytes } from 'node:crypto';

// Rotating tokens (ADR-0004). Must stay identical to the Dart implementation;
// both are checked against shared/test-vectors/totp.json.

const CROCKFORD = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

export interface TokenPair {
  /** 10-character Crockford Base32 token carried in the QR payload. */
  qr: string;
  /** 4-digit token for manual entry. */
  digits: string;
}

export function windowOf(unixMs: number, windowSec: number): number {
  return Math.floor(unixMs / (windowSec * 1000));
}

export function newSeed(): string {
  return randomBytes(32).toString('base64url');
}

export function tokenFor(seed: string, eventId: string, window: number): TokenPair {
  const key = Buffer.from(seed, 'base64url');
  const digest = createHmac('sha256', key).update(`${eventId}|${window}`, 'utf8').digest();

  let bits = '';
  for (const byte of digest.subarray(0, 7)) bits += byte.toString(2).padStart(8, '0');
  let qr = '';
  for (let i = 0; i < 10; i++) qr += CROCKFORD[parseInt(bits.slice(i * 5, i * 5 + 5), 2)];

  const digits = (digest.readUInt32BE(28) % 10000).toString().padStart(4, '0');
  return { qr, digits };
}

/** Event join code shown on the projector: 6 Crockford characters, rotates every join window. */
export function joinCodeFor(joinSeed: string, eventId: string, window: number): string {
  return tokenFor(joinSeed, `join:${eventId}`, window).qr.slice(0, 6);
}

export function normalizeJoinCode(raw: string): string {
  return raw.toUpperCase().replace(/[^0-9A-Z]/g, '');
}

export function verifyJoinCode(joinSeed: string, eventId: string, raw: string, nowMs: number, windowSec: number): boolean {
  const code = normalizeJoinCode(raw);
  const current = windowOf(nowMs, windowSec);
  return [current, current - 1].some((w) => joinCodeFor(joinSeed, eventId, w) === code);
}

export type TokenKind = 'qr' | 'digits';

/** Accepts the current and the immediately previous window (FR-03). */
export function verifyToken(
  seed: string,
  eventId: string,
  token: string,
  kind: TokenKind,
  nowMs: number,
  windowSec: number,
): boolean {
  const current = windowOf(nowMs, windowSec);
  for (const w of [current, current - 1]) {
    const expected = tokenFor(seed, eventId, w)[kind];
    if (expected === token) return true;
  }
  return false;
}
