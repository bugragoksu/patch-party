import 'dart:async';

import 'package:baglanti_agi/app/env.dart';
import 'package:baglanti_agi/core/data/game_repository.dart';
import 'package:baglanti_agi/core/data/staff_auth.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/observability/error_reporter.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/platform/camera_scanner.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Composition root. Tests override these with fakes (ADR-0005).

final errorReporterProvider = Provider<ErrorReporter>((ref) => DebugReporter());
final gameRepositoryProvider = Provider<GameRepository>(
  (ref) => GameRepository(),
);
final cameraScannerProvider = Provider<CameraScanner>(
  (ref) => WebCameraScanner(),
);
final eventIdProvider = Provider<String>((ref) => Env.eventId);

/// Server-minus-device clock difference, learned at join (FR-03 tokens).
final clockOffsetProvider = NotifierProvider<ClockOffset, int>(ClockOffset.new);

class ClockOffset extends Notifier<int> {
  static const _key = 'bag.clockOffsetMs';

  @override
  int build() => int.tryParse(Browser.read(_key) ?? '') ?? 0;

  void learn(int serverTimeMs) {
    state = serverTimeMs - DateTime.now().millisecondsSinceEpoch;
    Browser.write(_key, '$state');
  }
}

/// Server-aligned "now", ticking once a second.
final nowProvider = StreamProvider<int>((ref) {
  final offset = ref.watch(clockOffsetProvider);
  int now() => DateTime.now().millisecondsSinceEpoch + offset;
  final controller = StreamController<int>()..add(now());
  final timer = Timer.periodic(
    const Duration(seconds: 1),
    (_) => controller.add(now()),
  );
  ref.onDispose(() {
    timer.cancel();
    unawaited(controller.close());
  });
  return controller.stream;
});

int readNow(Ref ref) =>
    ref.read(nowProvider).value ??
    DateTime.now().millisecondsSinceEpoch + ref.read(clockOffsetProvider);

final authUserProvider = StreamProvider<User?>(
  (ref) => FirebaseAuth.instance.idTokenChanges(),
);

/// The staff (Google) account on the staff Firebase app. Only read on the
/// admin and projector surfaces, after `initStaffFirebase`.
final staffUserProvider = StreamProvider<User?>(
  (ref) => StaffAuth().userChanges(),
);

/// Custom claims of the signed-in user: `eventId` for players, `admin` /
/// `projector` for staff.
final claimsProvider = FutureProvider<Map<String, Object?>>((ref) async {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return const {};
  final token = await user.getIdTokenResult();
  return token.claims?.cast<String, Object?>() ?? const {};
});

final eventProvider = StreamProvider<EventInfo?>((ref) {
  return ref
      .watch(gameRepositoryProvider)
      .watchEvent(ref.watch(eventIdProvider));
});
