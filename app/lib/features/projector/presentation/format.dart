// Pure text helpers for the projector (no Flutter imports, VM-testable).

/// Web origin for the join link; empty outside http(s) (tests, desktop).
String webOrigin() {
  final base = Uri.base;
  return base.isScheme('http') || base.isScheme('https') ? base.origin : '';
}

/// "7QK2PX" -> "7QK-2PX".
String formatJoinCode(String code) =>
    code.length == 6 ? '${code.substring(0, 3)}-${code.substring(3)}' : code;

String joinLink(String origin, String code) => '$origin/j/$code';

/// "mm:ss" (or "h:mm:ss") left until [endMs]; never negative.
String formatRemaining(int endMs, int nowMs) {
  final total = ((endMs - nowMs) / 1000).ceil().clamp(0, 359999);
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
}
