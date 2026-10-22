import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/projector/presentation/projector_widgets.dart';
import 'package:baglanti_agi/features/projector/presentation/stage.dart';
import 'package:flutter/material.dart';

/// archived: personal data is gone; only the summary counts remain.
class ArchivedScene extends StatelessWidget {
  const new({required this.event, super.key});

  final EventInfo event;

  @override
  Widget build(BuildContext context) {
    final summary = event.summary ?? const {};
    final players = summary['playerCount'];
    final connections = summary['connectionCount'];
    final title = event.name.isNotEmpty
        ? event.name
        : event.settings.displayName;

    return SceneFrame(
      child: Center(
        child: StampIn(
          child: Sticker(
            shadow: Palette.yellow,
            shadowOffset: 8,
            radius: Radii.big,
            tiltDegrees: -2,
            padding: const EdgeInsets.fromLTRB(64, 52, 64, 56),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Oyun bitti, teşekkürler',
                  textAlign: TextAlign.center,
                  style: TextStyles.display.copyWith(
                    fontSize: 72,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyles.ui.copyWith(
                    fontSize: 30,
                    fontWeight: FontWeight.w700,
                    color: Palette.inkMuted,
                  ),
                ),
                if (players is num || connections is num) ...[
                  const SizedBox(height: 36),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (players is num)
                        CountSticker(
                          value: '${players.toInt()}',
                          label: 'oyuncu',
                          fontSize: 48,
                        ),
                      if (players is num && connections is num)
                        const SizedBox(width: 28),
                      if (connections is num)
                        CountSticker(
                          value: '${connections.toInt()}',
                          label: 'bağlantı',
                          shadow: Palette.green,
                          fontSize: 48,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
