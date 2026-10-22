// Display-name rules (FR-17, SEC-30). Mirrors shared/test-vectors/generate.py.

const TR_FOLD: Record<string, string> = { ı: 'i', ş: 's', ğ: 'g', ü: 'u', ö: 'o', ç: 'c' };

export const NAME_MIN = 2;
export const NAME_MAX = 24;

export function cleanDisplayName(raw: string): string {
  return raw.normalize('NFC').split(/\s+/u).filter(Boolean).join(' ');
}

/** Key used for uniqueness: case, Turkish letters, accents, punctuation and spacing do not matter. */
export function normalizeName(raw: string): string {
  let s = cleanDisplayName(raw);
  s = s.replaceAll('I', 'ı').replaceAll('İ', 'i').toLowerCase();
  s = [...s].map((c) => TR_FOLD[c] ?? c).join('');
  s = s.normalize('NFD').replace(/\p{M}/gu, '');
  s = s.replace(/[^a-z0-9 ]/g, ' ');
  return s.split(/\s+/).filter(Boolean).join('-');
}

export function isValidDisplayName(raw: string): boolean {
  const s = cleanDisplayName(raw);
  const length = [...s].length;
  if (length < NAME_MIN || length > NAME_MAX) return false;
  if (!/^[\p{L}\p{N} .'-]+$/u.test(s)) return false;
  return normalizeName(s) !== '';
}

const BLOCKLIST = ['amk', 'aq', 'orospu', 'pic', 'sik', 'yarrak', 'got', 'fuck', 'shit'];

/** Very small profanity screen for the projector (SEC-30); admins can hide names too. */
export function isOffensive(raw: string): boolean {
  const parts = normalizeName(raw).split('-');
  return parts.some((p) => BLOCKLIST.includes(p));
}

/** Numbered variants to suggest when a name is taken: "Deniz 2", "Deniz 3", ... */
export function* nameSuggestions(raw: string): Generator<string> {
  const base = cleanDisplayName(raw);
  for (let n = 2; n < 100; n++) {
    const suffix = ` ${n}`;
    const trimmed = [...base].slice(0, NAME_MAX - suffix.length).join('').trimEnd();
    yield `${trimmed}${suffix}`;
  }
}
