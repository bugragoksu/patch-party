import 'dart:convert';
import 'dart:io';

import 'package:baglanti_agi/core/domain/names.dart';
import 'package:baglanti_agi/core/domain/scoring.dart';
import 'package:baglanti_agi/core/domain/token.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _vectors(String name) =>
    jsonDecode(File('../shared/test-vectors/$name').readAsStringSync())
        as Map<String, dynamic>;

List<Map<String, dynamic>> _cases(String name) =>
    (_vectors(name)['cases'] as List).cast<Map<String, dynamic>>();

void main() {
  group('shared vectors: totp', () {
    for (final c in _cases('totp.json')) {
      test('${c['eventId']} @ ${c['unixMs']}', () {
        expect(
          windowOf(c['unixMs'] as int, c['windowSec'] as int),
          c['window'],
        );
        final t = tokenFor(
          c['seed'] as String,
          c['eventId'] as String,
          c['window'] as int,
        );
        expect(t.qr, c['qr']);
        expect(t.digits, c['digits']);
      });
    }
  });

  group('shared vectors: names', () {
    for (final c in _cases('names.json')) {
      test(jsonEncode(c['input']), () {
        final input = c['input'] as String;
        expect(cleanDisplayName(input), c['clean']);
        expect(normalizeName(input), c['key']);
        expect(isValidDisplayName(input), c['valid']);
      });
    }
  });

  group('shared vectors: scoring', () {
    for (final c in _cases('scoring.json')) {
      test('${c['a']} x ${c['b']}', () {
        final p = pointsFor(
          (c['a'] as List).cast<String>(),
          (c['b'] as List).cast<String>(),
        );
        expect(p.base, c['base']);
        expect(p.bonus, c['bonus']);
        expect(p.total, c['total']);
      });
    }
  });
}
