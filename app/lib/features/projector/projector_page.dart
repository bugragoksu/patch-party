import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/features/projector/presentation/archived_scene.dart';
import 'package:baglanti_agi/features/projector/presentation/live_scene.dart';
import 'package:baglanti_agi/features/projector/presentation/lobby_scene.dart';
import 'package:baglanti_agi/features/projector/presentation/projector_widgets.dart';
import 'package:baglanti_agi/features/projector/presentation/staff_gate.dart';
import 'package:baglanti_agi/features/projector/presentation/stage.dart';
import 'package:baglanti_agi/features/projector/presentation/winners_scene.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Projector surface (T09, FR-20..23). Staff-gated, non-interactive; the
/// scene follows the event state.
class ProjectorPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    backgroundColor: Palette.asphalt,
    body: Stack(
      children: [
        Positioned.fill(child: StaffGate(child: ProjectorStage())),
        Positioned(right: 16, bottom: 16, child: _FullscreenButton()),
      ],
    ),
  );
}

/// Shown only outside fullscreen; Esc leaves fullscreen and brings it back.
class _FullscreenButton extends StatefulWidget {
  const new();

  @override
  State<_FullscreenButton> createState() => _FullscreenButtonState();
}

class _FullscreenButtonState extends State<_FullscreenButton> {
  late final StreamSubscription<bool> _sub;
  bool _fullscreen = Browser.isFullscreen;

  @override
  void initState() {
    super.initState();
    _sub = Browser.fullscreenChanges.listen(
      (v) => setState(() => _fullscreen = v),
    );
  }

  @override
  void dispose() {
    unawaited(_sub.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_fullscreen || !Browser.canFullscreen) return const SizedBox.shrink();
    return Tooltip(
      message: 'Çıkmak için Esc',
      child: TextButton.icon(
        onPressed: () => unawaited(Browser.enterFullscreen()),
        icon: const Icon(Icons.fullscreen, size: 22),
        label: const Text('Tam ekran'),
        style: TextButton.styleFrom(
          foregroundColor: Palette.ink,
          backgroundColor: Palette.yellow,
          minimumSize: const Size(44, 44),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          textStyle: TextStyles.ui.copyWith(fontWeight: FontWeight.w700),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radii.button),
            side: const BorderSide(color: Palette.ink, width: Stroke.width),
          ),
        ),
      ),
    );
  }
}

/// Picks the scene for the current event state.
class ProjectorStage extends ConsumerWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventId = ref.watch(eventIdProvider);
    if (eventId.isEmpty) {
      return ErrorCard(
        message: 'Etkinlik kimliği tanımlı değil (APP_EVENT_ID).',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(eventProvider),
      );
    }
    final eventAsync = ref.watch(eventProvider);
    final event = eventAsync.value;
    if (event == null) {
      if (eventAsync.isLoading && !eventAsync.hasError) {
        return const Center(
          child: CircularProgressIndicator(color: Palette.yellow),
        );
      }
      return ErrorCard(
        message: eventAsync.hasError
            ? 'Etkinlik okunamadı. Bağlantıyı kontrol edip tekrar dene.'
            : 'Etkinlik bulunamadı. Kurulumu kontrol et.',
        actionLabel: 'Tekrar dene',
        onAction: () => ref.invalidate(eventProvider),
      );
    }

    final scene = switch (event.state) {
      EventState.draft || EventState.lobby => LobbyScene(event: event),
      EventState.live => LiveScene(event: event),
      EventState.ended => WinnersScene(event: event),
      EventState.archived => ArchivedScene(event: event),
    };
    final reduce = MediaQuery.disableAnimationsOf(context);

    return ProjectorCanvas(
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 500),
              child: KeyedSubtree(
                key: ValueKey(
                  event.state == EventState.draft
                      ? EventState.lobby
                      : event.state,
                ),
                child: scene,
              ),
            ),
          ),
          if (eventAsync.hasError)
            Positioned(
              left: 0,
              right: 0,
              top: 24,
              child: Center(
                child: StreamErrorBanner(
                  onRetry: () => ref.invalidate(eventProvider),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
