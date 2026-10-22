import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/chips.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/projector/application/projector_providers.dart';
import 'package:baglanti_agi/features/projector/leaderboard/leaderboard.dart';
import 'package:baglanti_agi/features/projector/presentation/projector_widgets.dart';
import 'package:baglanti_agi/features/projector/presentation/stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// draft / lobby (FR-22): big join QR, joined count, newest joiners.
class LobbyScene extends ConsumerWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(projectorPlayersProvider);
    final players = ref.watch(activePlayersProvider);
    final draft = event.state == EventState.draft;

    return SceneFrame(
      error: playersAsync.hasError && players != null,
      onRetry: () => ref.invalidate(projectorPlayersProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: EventTitle(event: event, size: 64)),
              const SizedBox(width: 28),
              if (players != null)
                CountSticker(
                  value: '${players.length}',
                  label: 'oyuncu katıldı',
                  fontSize: 44,
                ),
            ],
          ),
          const SizedBox(height: 28),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 5,
                  child: Center(child: JoinQrCard(event: event, qrSize: 500)),
                ),
                const SizedBox(width: 48),
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (draft) ...[
                        NoticeBox(
                          child: Text(
                            'Katılım birazdan açılacak.',
                            style: TextStyles.ui.copyWith(
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                              color: Palette.paper,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                      const StageTitle('Yeni katılanlar', size: 34),
                      const SizedBox(height: 18),
                      Expanded(
                        child: players == null
                            ? AsyncBlocker(
                                value: playersAsync,
                                onRetry: () =>
                                    ref.invalidate(projectorPlayersProvider),
                              )
                            : _Joiners(players: latestJoiners(players, 7)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Joiners extends StatelessWidget {
  const new({required this.players});

  final List<Player> players;

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) {
      return Text(
        'İlk katılan sen ol!',
        style: TextStyles.ui.copyWith(fontSize: 28, color: Palette.textMuted),
      );
    }
    return ClipRect(
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final p in players)
              Padding(
                key: ValueKey(p.uid),
                padding: const EdgeInsets.only(bottom: 14),
                child: PopIn(
                  child: Sticker(
                    color: Palette.asphaltRaised,
                    outline: Palette.line,
                    radius: 18,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PlayerAvatar(player: p, size: 44),
                        const SizedBox(width: 16),
                        Flexible(
                          child: Text(
                            p.publicName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyles.ui.copyWith(
                              fontSize: 30,
                              fontWeight: FontWeight.w700,
                              color: Palette.paper,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
