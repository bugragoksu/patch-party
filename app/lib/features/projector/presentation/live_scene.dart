import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/brand_mark.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/projector/application/projector_providers.dart';
import 'package:baglanti_agi/features/projector/graph/network_graph.dart';
import 'package:baglanti_agi/features/projector/leaderboard/leaderboard.dart';
import 'package:baglanti_agi/features/projector/presentation/projector_widgets.dart';
import 'package:baglanti_agi/features/projector/presentation/stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// live (FR-20, FR-21): network graph, top 10, counters, small join QR.
class LiveScene extends ConsumerWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(projectorPlayersProvider);
    final connAsync = ref.watch(projectorConnectionsProvider);
    final players = ref.watch(activePlayersProvider);
    final ranked = ref.watch(rankedPlayersProvider);
    final connections = ref.watch(
      projectorConnectionsProvider.select((a) => a.value),
    );
    final endAt = event.liveEndAt;

    void retry() {
      ref
        ..invalidate(projectorPlayersProvider)
        ..invalidate(projectorConnectionsProvider);
    }

    final hasData = players != null && connections != null;
    final counts = hasData ? ProjectorCounts.of(players, connections) : null;

    return SceneFrame(
      error: hasData && (playersAsync.hasError || connAsync.hasError),
      onRetry: retry,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 76,
            child: Row(
              children: [
                const BrandMark(size: 64),
                const SizedBox(width: 16),
                Flexible(
                  child: Text(
                    event.settings.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.display.copyWith(
                      fontSize: 44,
                      color: Palette.paper,
                    ),
                  ),
                ),
                const SizedBox(width: 22),
                const LivePill(),
                const Spacer(),
                if (counts != null) ...[
                  CountSticker(value: '${counts.players}', label: 'oyuncu'),
                  const SizedBox(width: 22),
                  CountSticker(
                    value: '${counts.connections}',
                    label: 'bağlantı',
                    shadow: Palette.green,
                  ),
                ],
                if (endAt != null) ...[
                  const SizedBox(width: 22),
                  RemainingSticker(endAt: endAt),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(Radii.big),
                      border: Border.all(
                        color: Palette.line,
                        width: Stroke.width,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(Radii.big - 3),
                      child: hasData
                          ? _GraphPanel(
                              players: players,
                              connections: connections,
                            )
                          : AsyncBlocker(
                              value: playersAsync.hasError
                                  ? playersAsync
                                  : connAsync,
                              onRetry: retry,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 28),
                SizedBox(
                  width: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8, top: 4),
                        child: JoinQrCard(
                          event: event,
                          qrSize: 168,
                          horizontal: true,
                        ),
                      ),
                      const SizedBox(height: 30),
                      Expanded(
                        child: _Leaderboard(
                          top: ranked?.take(10).toList(growable: false),
                        ),
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

class _GraphPanel extends StatelessWidget {
  const new({required this.players, required this.connections});

  final List<Player> players;
  final List<Connection> connections;

  @override
  Widget build(BuildContext context) {
    final newest = newestConnection(connections);
    return Stack(
      fit: StackFit.expand,
      children: [
        NetworkGraph(players: players, connections: connections),
        if (players.isEmpty)
          Center(
            child: Text(
              'Oyuncular katıldıkça ağ burada büyüyecek',
              style: TextStyles.ui.copyWith(
                fontSize: 28,
                color: Palette.textMuted,
              ),
            ),
          ),
        if (newest != null)
          Positioned(
            left: 0,
            right: 0,
            bottom: 22,
            child: Center(
              child: _NewBridge(
                key: ValueKey(newest.id),
                connection: newest,
                players: players,
              ),
            ),
          ),
      ],
    );
  }
}

class _NewBridge extends StatelessWidget {
  const new({required this.connection, required this.players, super.key});

  final Connection connection;
  final List<Player> players;

  String _name(String uid) {
    for (final p in players) {
      if (p.uid == uid) return p.publicName;
    }
    return 'Oyuncu';
  }

  @override
  Widget build(BuildContext context) {
    final parts = connection.participants;
    final names = parts.length < 2
        ? ''
        : '${_name(parts[0])} + ${_name(parts[1])}';
    return StampIn(
      child: Sticker(
        shadow: Palette.yellow,
        radius: 16,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              'YENİ BAĞLANTI',
              style: TextStyles.ui.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
                color: Palette.inkMuted,
              ),
            ),
            const SizedBox(width: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Text(
                names,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyles.ui.copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Palette.ink,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '+${connection.points + connection.bonus}',
              style: TextStyles.code.copyWith(fontSize: 28, color: Palette.ink),
            ),
          ],
        ),
      ),
    );
  }
}

class _Leaderboard extends StatelessWidget {
  const new({required this.top});

  final List<Player>? top;

  @override
  Widget build(BuildContext context) {
    final top = this.top;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 12),
      decoration: BoxDecoration(
        color: Palette.asphaltRaised,
        borderRadius: BorderRadius.circular(Radii.card),
        border: Border.all(color: Palette.line, width: Stroke.width),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const StageTitle('İlk 10'),
          const SizedBox(height: 8),
          if (top == null)
            const Expanded(
              child: Center(
                child: CircularProgressIndicator(color: Palette.yellow),
              ),
            )
          else if (top.isEmpty)
            Expanded(
              child: Center(
                child: Text(
                  'Henüz oyuncu yok',
                  style: TextStyles.ui.copyWith(
                    fontSize: 24,
                    color: Palette.textMuted,
                  ),
                ),
              ),
            )
          else ...[
            for (var i = 0; i < 10; i++)
              Expanded(
                child: i < top.length
                    ? _LeaderRow(rank: i + 1, player: top[i], last: i == 9)
                    : const SizedBox(),
              ),
          ],
        ],
      ),
    );
  }
}

class _LeaderRow extends StatelessWidget {
  const new({required this.rank, required this.player, required this.last});

  final int rank;
  final Player player;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: Palette.line, width: 2)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 46,
            child: Text(
              '$rank',
              style: TextStyles.code.copyWith(
                fontSize: 26,
                color: rank <= 3 ? Palette.yellow : Palette.textMuted,
              ),
            ),
          ),
          PlayerAvatar(player: player, size: 38),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              player.publicName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.ui.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Palette.paper,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '${player.score}',
            style: TextStyles.display.copyWith(
              fontSize: 28,
              color: Palette.paper,
            ),
          ),
        ],
      ),
    );
  }
}
