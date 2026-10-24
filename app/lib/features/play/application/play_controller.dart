import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/core/data/game_repository.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/scan_code.dart';
import 'package:baglanti_agi/core/observability/error_reporter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

enum PlayMode { qr, scan, manual, waiting }

/// The outgoing request I am waiting on.
class Waiting {
  const new({
    required this.requestId,
    required this.expiresAt,
    required this.targetName,
    required this.targetInterests,
  });

  final String requestId;
  final int expiresAt;
  final String targetName;
  final List<String> targetInterests;
}

class PlayState {
  const new({
    this.mode = PlayMode.qr,
    this.waiting,
    this.busy = false,
    this.failure,
  });

  final PlayMode mode;
  final Waiting? waiting;
  final bool busy;

  /// Last expected failure, shown once by the UI and then cleared.
  final GameFailure? failure;

  PlayState copyWith({
    PlayMode? mode,
    Waiting? waiting,
    bool clearWaiting = false,
    bool? busy,
    GameFailure? failure,
    bool clearFailure = false,
  }) => PlayState(
    mode: mode ?? this.mode,
    waiting: clearWaiting ? null : (waiting ?? this.waiting),
    busy: busy ?? this.busy,
    failure: clearFailure ? null : (failure ?? this.failure),
  );
}

/// Local flow of the player screen. Server state (score, connections,
/// requests) comes from streams; this only tracks what the player is doing.
final playControllerProvider = NotifierProvider<PlayController, PlayState>(
  PlayController.new,
);

class PlayController extends Notifier<PlayState> {
  @override
  PlayState build() => const PlayState();

  /// A scanned QR stays in front of the camera after a rejection; the same
  /// player's code is ignored for this long so it is not resent every frame.
  static const rejectedHold = Duration(seconds: 10);
  ({String key, DateTime at})? _rejected;

  bool _recentlyRejected(String key) {
    final r = _rejected;
    return r != null &&
        r.key == key &&
        DateTime.now().difference(r.at) < rejectedHold;
  }

  GameRepository get _repo => ref.read(gameRepositoryProvider);
  ErrorReporter get _reporter => ref.read(errorReporterProvider);
  String get _eventId => ref.read(eventIdProvider);

  void showQr() => state = state.copyWith(mode: PlayMode.qr);

  void showScan() {
    _reporter.breadcrumb(AppEvent.scanStarted);
    state = state.copyWith(mode: PlayMode.scan);
  }

  void showManual() {
    _reporter.breadcrumb(AppEvent.manualEntryOpened);
    state = state.copyWith(mode: PlayMode.manual);
  }

  void clearFailure() => state = state.copyWith(clearFailure: true);

  /// Handles both a scanned QR payload and a typed short code.
  Future<void> submitCode(String raw, {bool typed = false}) async {
    if (state.busy) return;
    final input = ScanInput.parse(raw);
    final key = input?.playerCode ?? raw.trim();
    if (!typed && _recentlyRejected(key)) return;
    if (input == null) {
      _rejected = (key: key, at: DateTime.now());
      state = state.copyWith(failure: const CodeInvalid());
      return;
    }
    state = state.copyWith(busy: true, clearFailure: true);
    final result = await _repo.requestConnection(_eventId, input.wire);
    switch (result) {
      case Ok(:final value):
        _reporter.breadcrumb(AppEvent.requestSent);
        if (value.accepted) {
          // Mutual scan: the connection listener shows the success screen.
          state = state.copyWith(busy: false, mode: PlayMode.qr);
        } else {
          state = state.copyWith(
            busy: false,
            mode: PlayMode.waiting,
            waiting: Waiting(
              requestId: value.requestId,
              expiresAt: value.expiresAt,
              targetName: value.targetName,
              targetInterests: value.targetInterests,
            ),
          );
        }
      case Err(:final failure):
        _rejected = (key: key, at: DateTime.now());
        _reporter.breadcrumb(
          AppEvent.scanRejected,
          detail: failure.runtimeType.toString(),
        );
        state = state.copyWith(busy: false, failure: failure);
    }
  }

  Future<void> cancelWaiting() async {
    final waiting = state.waiting;
    state = state.copyWith(mode: PlayMode.scan, clearWaiting: true);
    if (waiting != null) await _repo.cancel(_eventId, waiting.requestId);
  }

  /// Called when my outgoing request closes without a connection.
  void waitingEnded(GameFailure reason) {
    if (state.mode != PlayMode.waiting) return;
    state = state.copyWith(
      mode: PlayMode.qr,
      clearWaiting: true,
      failure: reason,
    );
  }

  /// Called by the screen when a new connection appears.
  void connected() {
    _reporter.breadcrumb(AppEvent.connected);
    state = state.copyWith(mode: PlayMode.qr, clearWaiting: true);
  }

  Future<Result<ConnectionOutcome?>> respond(
    String requestId, {
    required bool accept,
  }) async {
    final result = await _repo.respond(_eventId, requestId, accept: accept);
    _reporter.breadcrumb(
      AppEvent.requestAnswered,
      detail: accept ? 'accept' : 'decline',
    );
    return result;
  }
}
