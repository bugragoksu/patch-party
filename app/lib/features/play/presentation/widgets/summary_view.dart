import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/confetti.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/connections_list.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/success_view.dart';
import 'package:flutter/material.dart';

/// FR-10: shown once the event has ended. Ranks stay hidden until the host
/// has announced the winners on the projector (event.reveal).
class SummaryView extends StatelessWidget {
  const new({required this.me, required this.event, super.key});

  final Player me;
  final EventInfo event;

  @override
  Widget build(BuildContext context) {
    final revealed = event.resultsRevealed;
    final rank = me.rank;
    final podium = revealed && rank != null && rank <= 3;
    return ConfettiBurst(
      burstKey: podium,
      intensity: podium ? 4 - rank : 0,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 8),
            child: Column(
              children: [
                StampIn(
                  child: Text(
                    'Oyun bitti!',
                    style: TextStyles.display.copyWith(
                      fontSize: 30,
                      color: Palette.paper,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Stat(
                        value: '${me.connectionCount}',
                        label: 'kişiyle tanıştın',
                        color: Palette.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        value: '${me.score}',
                        label: 'puan',
                        color: Palette.yellow,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _Stat(
                        value: !revealed
                            ? '?'
                            : rank == null
                            ? '–'
                            : '$rank.',
                        label: 'sıra',
                        color: Palette.green,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  !revealed
                      ? 'Kazananlar perdede açıklanıyor, gözün perdede olsun.'
                      : podium
                      ? 'Tebrikler, $rank. oldun!'
                      : 'Teşekkürler, iyi ki geldin!',
                  textAlign: TextAlign.center,
                  style: TextStyles.ui.copyWith(
                    fontSize: 15,
                    fontWeight: podium ? FontWeight.w700 : FontWeight.w400,
                    color: podium ? Palette.yellow : Palette.textMuted,
                  ),
                ),
                if (me.badges.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final b in me.badges)
                        Sticker(
                          color: Palette.asphaltRaised,
                          outline: Palette.yellow,
                          radius: 14,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                badgeTitle(b),
                                style: TextStyles.ui.copyWith(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                badgeReason(b),
                                style: TextStyles.ui.copyWith(
                                  fontSize: 12,
                                  color: Palette.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          Expanded(child: ConnectionsList(me: me)),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const new({required this.value, required this.label, required this.color});

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      color: color,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyles.display.copyWith(
              fontSize: 24,
              color: Palette.ink,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyles.ui.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
