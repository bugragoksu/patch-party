import 'package:characters/characters.dart';

// Display-name rules (FR-17). Mirrors functions/src/domain/names.ts and the
// shared vectors. The server is the authority; this is for instant feedback.

const nameMinLength = 2;
const nameMaxLength = 24;

const Map<String, String> _trFold = {
  'ı': 'i',
  'ş': 's',
  'ğ': 'g',
  'ü': 'u',
  'ö': 'o',
  'ç': 'c',
};

const Map<String, String> _latinFold = {
  'á': 'a', 'à': 'a', 'â': 'a', 'ä': 'a', 'ã': 'a', 'å': 'a', //
  'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e', //
  'í': 'i', 'ì': 'i', 'î': 'i', 'ï': 'i', //
  'ó': 'o', 'ò': 'o', 'ô': 'o', 'õ': 'o', //
  'ú': 'u', 'ù': 'u', 'û': 'u', //
  'ñ': 'n', 'ý': 'y', 'ÿ': 'y',
};

String cleanDisplayName(String raw) =>
    raw.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).join(' ');

String normalizeName(String raw) {
  var s = cleanDisplayName(raw).replaceAll('I', 'ı').replaceAll('İ', 'i');
  // Decomposed accents lose their mark; precomposed ones fold below.
  s = s.toLowerCase().replaceAll(RegExp(r'\p{M}', unicode: true), '');
  final out = StringBuffer();
  for (final c in s.characters) {
    final folded = _trFold[c] ?? _latinFold[c] ?? c;
    out.write(RegExp(r'^[a-z0-9 ]$').hasMatch(folded) ? folded : ' ');
  }
  return out.toString().split(' ').where((p) => p.isNotEmpty).join('-');
}

bool isValidDisplayName(String raw) {
  final s = cleanDisplayName(raw);
  final length = s.runes.length;
  if (length < nameMinLength || length > nameMaxLength) return false;
  if (!RegExp(r"^[\p{L}\p{N} .'-]+$", unicode: true).hasMatch(s)) return false;
  return normalizeName(s).isNotEmpty;
}
