import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/connections_list.dart';
import 'package:baglanti_agi/features/play/presentation/widgets/success_view.dart';
import 'package:flutter/material.dart';

/// FR-10: shown once the event has ended.
class SummaryView extends StatelessWidget {
  const new({required this.me, super.key});

  final Player me;

  @override
  Widget build(BuildContext context) {
    return Column(
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
                      value: me.rank == null ? '–' : '${me.rank}.',
                      label: 'sıra',
                      color: Palette.green,
                    ),
                  ),
                ],
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
                        radius: 999,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: Text(
                          badgeLabels[b] ?? b,
                          style: TextStyles.ui.copyWith(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
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
