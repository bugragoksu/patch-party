import 'dart:convert';

import 'package:crypto/crypto.dart';

// Rotating tokens (ADR-0004). Must stay identical to functions/src/domain/totp.ts;
// both run shared/test-vectors/totp.json.

const _crockford = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

class TokenPair {
  const new({required this.qr, required this.digits});

  final String qr;
  final String digits;
}

int windowOf(int unixMs, int windowSec) => unixMs ~/ (windowSec * 1000);

List<int> _decodeSeed(String seed) =>
    base64Url.decode(seed.padRight((seed.length + 3) ~/ 4 * 4, '='));

TokenPair tokenFor(String seed, String eventId, int window) {
  final digest = Hmac(
    sha256,
    _decodeSeed(seed),
  ).convert(utf8.encode('$eventId|$window')).bytes;

  final bits = StringBuffer();
  for (final byte in digest.take(7)) {
    bits.write(byte.toRadixString(2).padLeft(8, '0'));
  }
  final s = bits.toString();
  final qr = StringBuffer();
  for (var i = 0; i < 10; i++) {
    qr.write(_crockford[int.parse(s.substring(i * 5, i * 5 + 5), radix: 2)]);
  }

  final tail =
      (digest[28] << 24) | (digest[29] << 16) | (digest[30] << 8) | digest[31];
  final digits = ((tail & 0xFFFFFFFF) % 10000).toString().padLeft(4, '0');
  return TokenPair(qr: qr.toString(), digits: digits);
}

/// Projector join code: 6 characters, rotates every join window.
String joinCodeFor(String joinSeed, String eventId, int window) =>
    tokenFor(joinSeed, 'join:$eventId', window).qr.substring(0, 6);

/// QR payload: a URL, so a phone's built-in camera also opens the game.
String qrPayload(String origin, String playerCode, String token) =>
    '$origin/#/c/$playerCode.$token';

String shortCode(String playerCode, String digits) => '$playerCode-$digits';
