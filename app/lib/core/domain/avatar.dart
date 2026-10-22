import 'package:baglanti_agi/core/domain/catalog.dart';
import 'package:characters/characters.dart';

/// Deterministic avatar (FR-16): same name and interests draw the same avatar
/// on every device. No photos.
class AvatarSpec {
  const new({
    required this.initial,
    required this.primary,
    required this.secondary,
    required this.badgeShape,
    required this.badgeTurns,
  });

  factory of(String displayName, List<String> interests) {
    final first = interests.isNotEmpty ? interests.first : '';
    final second = interests.length > 1 ? interests[1] : first;
    final hash = _fnv1a('$displayName|${interests.join(',')}');
    return AvatarSpec(
      initial: initialOf(displayName),
      primary: Catalog.clusterOf(first).color,
      secondary: Catalog.clusterOf(second).color,
      badgeShape: BadgeShape.values[hash % BadgeShape.values.length],
      badgeTurns: ((hash >> 4) % 5 - 2) / 32,
    );
  }

  final String initial;
  final int primary;
  final int secondary;
  final BadgeShape badgeShape;

  /// Small tilt of the corner badge, in turns (-1/16 .. 1/16).
  final double badgeTurns;
}

enum BadgeShape { square, circle, triangle, diamond }

/// Turkish-aware first letter: "işıl" -> "İ".
String initialOf(String name) {
  final c = name.trim().characters.firstOrNull ?? '?';
  return switch (c) {
    'i' => 'İ',
    'ı' => 'I',
    _ => c.toUpperCase(),
  };
}

int _fnv1a(String s) {
  var h = 0x811c9dc5;
  for (final unit in s.codeUnits) {
    h ^= unit;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}
