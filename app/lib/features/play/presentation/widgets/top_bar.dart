import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/avatar.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/avatar.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:flutter/material.dart';

/// Avatar, name, rank (FR-24, up to a minute old) and score sticker.
class PlayerTopBar extends StatelessWidget {
  const new({
    required this.player,
    required this.showRank,
    required this.nowMs,
    required this.onConnections,
    super.key,
  });

  final Player player;
  final bool showRank;
  final int nowMs;
  final VoidCallback onConnections;

  String? get _rankText {
    final rank = player.rank;
    if (!showRank || rank == null) return null;
    final at = player.rankedAt;
    final minutes = at == null ? null : ((nowMs - at) / 60000).floor();
    final age = minutes == null || minutes < 1 ? 'şimdi' : '$minutes dk önce';
    return '$rank. sıra · $age';
  }

  @override
  Widget build(BuildContext context) {
    final rank = _rankText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 8),
      child: Row(
        children: [
          AvatarBadge(
            spec: AvatarSpec.of(player.displayName, player.interests),
            size: 44,
            outline: Palette.paper,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  player.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyles.ui.copyWith(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Palette.paper,
                  ),
                ),
                Text(
                  rank ?? '${player.connectionCount} bağlantı',
                  style: TextStyles.ui.copyWith(
                    fontSize: 12,
                    color: Palette.textMuted,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Bağlantılarım',
            onPressed: onConnections,
            icon: const Icon(Icons.people_alt_outlined, color: Palette.paper),
          ),
          const SizedBox(width: 4),
          Semantics(
            label: '${player.score} puan',
            excludeSemantics: true,
            child: Sticker(
              shadow: Palette.blue,
              shadowOffset: 4,
              tiltDegrees: 2,
              radius: 12,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Column(
                children: [
                  AnimatedSwitcher(
                    duration: Motion.pop,
                    transitionBuilder: (child, a) =>
                        ScaleTransition(scale: a, child: child),
                    child: Text(
                      '${player.score}',
                      key: ValueKey(player.score),
                      style: TextStyles.display.copyWith(
                        fontSize: 20,
                        color: Palette.ink,
                        height: 1.1,
                      ),
                    ),
                  ),
                  Text(
                    'PUAN',
                    style: TextStyles.label.copyWith(
                      fontSize: 10,
                      color: Palette.ink,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
