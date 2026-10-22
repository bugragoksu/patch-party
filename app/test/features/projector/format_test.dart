import 'package:baglanti_agi/features/projector/presentation/format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('join code is shown as XXX-XXX and linked by fragment', () {
    expect(formatJoinCode('7QK2PX'), '7QK-2PX');
    expect(
      joinLink('https://x.web.app', '7QK2PX'),
      'https://x.web.app/#/j/7QK2PX',
    );
    expect(webOrigin(), isEmpty, reason: 'VM tests run from file://');
  });

  test('remaining time', () {
    expect(formatRemaining(61500, 0), '01:02');
    expect(formatRemaining(0, 5000), '00:00');
    expect(formatRemaining(3725000, 0), '1:02:05');
  });
}
