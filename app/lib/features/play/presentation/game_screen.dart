import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/features/play/application/play_controller.dart';
import 'package:baglanti_agi/features/play/application/questions.dart';
import 'package:baglanti_agi/features/play/application/session.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/connections_list.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/lobby_view.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/manual_entry.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/qr_view.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/request_views.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/scan_view.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/success_view.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/summary_view.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One-scene game screen: QR'ım / Tara, with request, waiting and success
/// scenes layered on top as the server state changes.
class GameScreen extends ConsumerStatefulWidget {
  const new({super.key, this.scannedPayload});

  /// A QR payload opened with the phone's own camera (/#/c/...).
  final String? scannedPayload;

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  Set<String>? _seen;
  Connection? _success;

  /// Badges a player had right before each connection, keyed by the
  /// connection time. The player document and the connection document arrive
  /// in either order, so new badges are worked out at build time.
  final Map<int, List<String>> _badgesBeforeConnection = {};
  bool _payloadUsed = false;

  @override
  void initState() {
    super.initState();
    ref
      // Questions are needed only after the first connection; load them now
      // so the success screen never waits.
      ..listenManual(questionPoolProvider, (_, _) {})
      ..listenManual(
        myConnectionsProvider,
        _onConnections,
        fireImmediately: true,
      )
      ..listenManual(outgoingRequestProvider, _onOutgoing)
      ..listenManual(playControllerProvider.select((s) => s.failure), (
        _,
        failure,
      ) {
        if (failure == null || !mounted) return;
        showFailure(context, failure);
        ref.read(playControllerProvider.notifier).clearFailure();
      })
      ..listenManual(myPlayerProvider, (prev, next) {
        final before = prev?.value;
        final after = next.value;
        if (before == null || after == null) return;
        final at = after.lastConnectionAt;
        if (at != null && at != before.lastConnectionAt) {
          setState(() => _badgesBeforeConnection[at] = before.badges);
        }
      });
  }

  void _onConnections(
    AsyncValue<List<Connection>>? _,
    AsyncValue<List<Connection>> next,
  ) {
    final list = next.value;
    if (list == null) return;
    final ids = list.map((c) => c.id).toSet();
    final seen = _seen;
    _seen = ids;
    if (seen == null) return; // First load: nothing is "new".
    final fresh = list.where((c) => !seen.contains(c.id)).toList();
    if (fresh.isEmpty) return;
    ref.read(playControllerProvider.notifier).connected();
    setState(() => _success = fresh.first);
  }

  List<String> _newBadgesFor(Connection connection, Player me) {
    final before = _badgesBeforeConnection[connection.createdAt];
    if (before == null || me.lastConnectionAt != connection.createdAt) {
      return const [];
    }
    return me.badges.where((b) => !before.contains(b)).toList();
  }

  void _onOutgoing(
    AsyncValue<ConnectionRequest?>? _,
    AsyncValue<ConnectionRequest?> next,
  ) {
    final request = next.value;
    if (request == null) return;
    final controller = ref.read(playControllerProvider.notifier);
    switch (request.status) {
      case RequestStatus.declined:
        controller.waitingEnded(const Declined());
      case RequestStatus.expired:
        controller.waitingEnded(const RequestExpired());
      case RequestStatus.pending ||
          RequestStatus.accepted ||
          RequestStatus.cancelled:
        break;
    }
  }

  void _maybeUsePayload(EventInfo event, int now) {
    final payload = widget.scannedPayload;
    if (payload == null || _payloadUsed || !event.isLiveAt(now)) return;
    _payloadUsed = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => unawaited(
        ref.read(playControllerProvider.notifier).submitCode(payload),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider).value;
    final me = ref.watch(myPlayerProvider).value;
    final play = ref.watch(playControllerProvider);
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final controller = ref.read(playControllerProvider.notifier);

    if (event == null || me == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Palette.yellow)),
      );
    }
    _maybeUsePayload(event, now);

    final waiting = play.waiting;
    if (play.mode == PlayMode.waiting &&
        waiting != null &&
        now > waiting.expiresAt + 2000) {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => controller.waitingEnded(const RequestExpired()),
      );
    }

    final live = event.isLiveAt(now);
    final ended =
        event.state == EventState.ended || event.state == EventState.archived;
    final incoming =
        (ref.watch(incomingRequestsProvider).value ?? const [])
            .where((r) => r.isOpenAt(now))
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    final success = _success;

    final Widget scene;
    var showDock = false;
    if (ended) {
      scene = SummaryView(me: me, event: event);
    } else if (incoming.isNotEmpty) {
      // Shown over the success screen: whoever scanned you is standing
      // right there; the conversation screen comes back afterwards.
      scene = IncomingRequestCard(
        key: ValueKey(incoming.first.id),
        request: incoming.first,
        me: me,
      );
    } else if (success != null) {
      scene = SuccessView(
        connection: success,
        otherName: success.names[success.otherThan(me.uid)] ?? '',
        newBadges: _newBadgesFor(success, me),
        onScanNext: () {
          setState(() => _success = null);
          controller.showScan();
        },
        onDone: () {
          setState(() => _success = null);
          controller.showQr();
        },
        holdUntil: success.createdAt + event.settings.cooldownSec * 1000,
        nowMs: now,
      );
    } else if (play.mode == PlayMode.waiting && waiting != null) {
      scene = WaitingView(waiting: waiting);
    } else if (play.mode == PlayMode.manual && live) {
      scene = const ManualEntry();
    } else if (play.mode == PlayMode.scan && live) {
      scene = const ScanView();
      showDock = true;
    } else {
      scene = live
          ? QrView(player: me, event: event)
          : LobbyView(player: me, paused: event.state == EventState.live);
      showDock = true;
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                PlayerTopBar(
                  player: me,
                  // No rank in the corner while the winners are announced.
                  showRank:
                      event.settings.playerRank &&
                      (!ended || event.resultsRevealed),
                  nowMs: now,
                  onConnections: () =>
                      unawaited(showConnectionsSheet(context, me)),
                ),
                if (me.disqualified)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      failureMessage(const Disqualified()),
                      style: TextStyles.ui.copyWith(
                        color: Palette.red,
                        fontSize: 13,
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      child: KeyedSubtree(
                        key: ValueKey(scene.runtimeType),
                        child: scene,
                      ),
                    ),
                  ),
                ),
                if (showDock)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: DockButton(
                            label: "QR'ım",
                            icon: Icons.qr_code_2,
                            active: play.mode != PlayMode.scan,
                            onPressed: controller.showQr,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DockButton(
                            label: 'Tara',
                            icon: Icons.qr_code_scanner,
                            active: play.mode == PlayMode.scan,
                            enabled: live,
                            onPressed: live
                                ? controller.showScan
                                : () => showFailure(context, const NotLive()),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
