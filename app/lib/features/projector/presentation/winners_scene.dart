import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/projector/application/projector_providers.dart';
import 'package:baglanti_agi/features/projector/presentation/projector_widgets.dart';
import 'package:baglanti_agi/features/projector/presentation/stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ended (FR-23): podium for the top 3, then places 4-10, prizes if set.
class WinnersScene extends ConsumerWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playersAsync = ref.watch(projectorPlayersProvider);
    final ranked = ref.watch(rankedPlayersProvider);
    final prizes = event.settings.prizes;
    String? prizeAt(int i) => i < prizes.length ? prizes[i] : null;

    Widget body;
    if (ranked == null) {
      body = AsyncBlocker(
        value: playersAsync,
        onRetry: () => ref.invalidate(projectorPlayersProvider),
      );
    } else if (ranked.isEmpty) {
      body = Center(
        child: Text(
          'Bu oyunda kazanan çıkmadı',
          style: TextStyles.ui.copyWith(fontSize: 32, color: Palette.textMuted),
        ),
      );
    } else {
      final rest = ranked.skip(3).take(7).toList(growable: false);
      body = Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final place in const [2, 1, 3])
                  if (place <= ranked.length)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: _PodiumSpot(
                        place: place,
                        player: ranked[place - 1],
                        prize: prizeAt(place - 1),
                      ),
                    ),
              ],
            ),
          ),
          if (rest.isNotEmpty) ...[
            const SizedBox(width: 40),
            SizedBox(
              width: 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < rest.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: PopIn(
                        index: i,
                        child: _PlaceRow(
                          place: i + 4,
                          player: rest[i],
                          prize: prizeAt(i + 3),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return SceneFrame(
      error: playersAsync.hasError && ranked != null,
      onRetry: () => ref.invalidate(projectorPlayersProvider),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Kazananlar',
                style: TextStyles.display.copyWith(
                  fontSize: 72,
                  color: Palette.yellow,
                ),
              ),
              const SizedBox(width: 36),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: EventTitle(event: event, size: 40),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _PodiumSpot extends StatelessWidget {
  const new({required this.place, required this.player, this.prize});

  final int place;
  final Player player;
  final String? prize;

  @override
  Widget build(BuildContext context) {
    final (color, height, tilt) = switch (place) {
      1 => (Palette.yellow, 250.0, -2.0),
      2 => (Palette.blue, 170.0, 1.5),
      _ => (Palette.green, 110.0, 1.5),
    };
    final first = place == 1;
    return SizedBox(
      width: first ? 400 : 340,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          StampIn(
            delay: Duration(milliseconds: (3 - place) * 250 + 200),
            child: Sticker(
              shadow: color,
              shadowOffset: 8,
              radius: Radii.big,
              tiltDegrees: tilt,
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PlayerAvatar(player: player, size: first ? 120 : 96),
                  const SizedBox(height: 14),
                  Text(
                    player.publicName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.display.copyWith(
                      fontSize: first ? 36 : 30,
                      color: Palette.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${player.score} puan',
                    style: TextStyles.code.copyWith(
                      fontSize: first ? 40 : 32,
                      color: Palette.ink,
                    ),
                  ),
                  if (prize != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      prize!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyles.ui.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Palette.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: height,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(Radii.card),
              ),
              border: Border.all(color: Palette.ink, width: Stroke.width),
            ),
            child: Text(
              '$place',
              style: TextStyles.display.copyWith(
                fontSize: first ? 110 : 80,
                color: Palette.ink,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const new({required this.place, required this.player, this.prize});

  final int place;
  final Player player;
  final String? prize;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      color: Palette.asphaltRaised,
      outline: Palette.line,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 50,
            child: Text(
              '$place',
              style: TextStyles.code.copyWith(
                fontSize: 28,
                color: Palette.textMuted,
              ),
            ),
          ),
          PlayerAvatar(player: player, size: 44),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  player.publicName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.ui.copyWith(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Palette.paper,
                  ),
                ),
                if (prize != null)
                  Text(
                    prize!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyles.ui.copyWith(
                      fontSize: 20,
                      color: Palette.textMuted,
                    ),
                  ),
              ],
            ),
          ),
          Text(
            '${player.score}',
            style: TextStyles.display.copyWith(
              fontSize: 30,
              color: Palette.paper,
            ),
          ),
        ],
      ),
    );
  }
}
