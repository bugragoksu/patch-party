import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
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
    body: StaffGate(child: ProjectorStage()),
  );
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
