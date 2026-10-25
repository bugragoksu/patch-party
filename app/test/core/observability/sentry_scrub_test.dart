import 'package:baglanti_agi/core/observability/sentry_reporter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

void main() {
  test('join codes and QR payloads never leave the device', () {
    final event = scrubEvent(
      SentryEvent(
        transaction: '/c/K7M.ABCDEFGHJK',
        request: SentryRequest(url: 'https://x.app/j/7QK2PX?a=1'),
      ),
      Hint(),
    )!;
    expect(event.request!.url, 'https://x.app/j/[code]?a=1');
    expect(event.transaction, '/c/[code]');
  });

  test('dropped connections are not reported', () {
    expect(
      isTransientNetworkError(
        'FirebaseError: [code=unavailable]: Connection failed.',
      ),
      isTrue,
    );
    expect(isTransientNetworkError(StateError('Bad state: ref')), isFalse);
    expect(
      scrubEvent(SentryEvent(throwable: 'Failed to fetch'), Hint()),
      isNull,
    );
  });
}
