import { createHash } from 'node:crypto';

/**
 * Picks which question pool both players see (FR-08). The pool itself is static
 * content on Hosting; the client resolves `key` + `seed` to a question and falls
 * back to the general pool when the key has no questions.
 */
export function questionFor(pair: string, a: readonly string[], b: readonly string[]): { key: string; seed: number } {
  const seed = createHash('sha256').update(pair).digest().readUInt32BE(0) & 0x7fffffff;
  const shared = a.filter((id) => b.includes(id));
  if (shared.length > 0) {
    const id = shared[seed % shared.length]!;
    return { key: `${id}|${id}`, seed };
  }
  const x = a[seed % a.length]!;
  const y = b[(seed >>> 8) % b.length]!;
  return { key: x < y ? `${x}|${y}` : `${y}|${x}`, seed };
}
