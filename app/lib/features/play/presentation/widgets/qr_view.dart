import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/domain/token.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/application/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// My rotating QR (FR-03): changes every token window, short code below,
/// screen kept awake while visible.
class QrView extends ConsumerStatefulWidget {
  const new({required this.player, required this.event, super.key});

  final Player player;
  final EventInfo event;

  @override
  ConsumerState<QrView> createState() => _QrViewState();
}

class _QrViewState extends ConsumerState<QrView> {
  final _wakeLock = WakeLock();

  @override
  void initState() {
    super.initState();
    unawaited(_wakeLock.acquire());
  }

  @override
  void dispose() {
    unawaited(_wakeLock.release());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(playerSessionProvider).value;
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final windowSec = widget.event.settings.tokenWindowSec;
    final window = windowOf(now, windowSec);
    final secondsLeft = windowSec - (now ~/ 1000) % windowSec;
    final token = session == null
        ? null
        : tokenFor(session.seed, widget.event.id, window);
    final live = widget.event.isLiveAt(now);
    final code = token == null
        ? '---'
        : shortCode(widget.player.playerCode, token.digits);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = (constraints.maxWidth - 80).clamp(180.0, 300.0);
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              live ? 'Biri seni okutsun' : 'Oyun birazdan başlıyor',
              style: TextStyles.ui.copyWith(
                fontSize: 14,
                color: const Color(0xFFD8D3C8),
              ),
            ),
            const SizedBox(height: 16),
            Sticker(
              shadow: Palette.yellow,
              shadowOffset: 8,
              tiltDegrees: -2,
              radius: 24,
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                width: side,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Semantics(
                      label: 'Senin QR kodun. Kısa kod: $code',
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: token == null
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: Palette.ink,
                                ),
                              )
                            : AnimatedOpacity(
                                opacity: live ? 1 : 0.35,
                                duration: const Duration(milliseconds: 200),
                                child: QrImageView(
                                  data: qrPayload(
                                    Browser.origin,
                                    widget.player.playerCode,
                                    token.qr,
                                  ),
                                  padding: EdgeInsets.zero,
                                  eyeStyle: const QrEyeStyle(
                                    eyeShape: QrEyeShape.square,
                                    color: Palette.ink,
                                  ),
                                  dataModuleStyle: const QrDataModuleStyle(
                                    dataModuleShape: QrDataModuleShape.square,
                                    color: Palette.ink,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _CountdownBar(fraction: secondsLeft / windowSec),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Expanded(
                          child: Text(
                            token == null
                                ? '---'
                                : shortCode(
                                    widget.player.playerCode,
                                    token.digits,
                                  ),
                            style: TextStyles.code.copyWith(
                              fontSize: 22,
                              color: Palette.ink,
                            ),
                          ),
                        ),
                        Text(
                          '$secondsLeft sn',
                          style: TextStyles.code.copyWith(
                            fontSize: 13,
                            color: Palette.inkMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Kod $windowSec saniyede bir değişir. '
              'Ekran görüntüsü işe yaramaz.',
              textAlign: TextAlign.center,
              style: TextStyles.ui.copyWith(
                fontSize: 13,
                color: Palette.textMuted,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CountdownBar extends StatelessWidget {
  const new({required this.fraction});

  final double fraction;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: const Color(0xFFE1DCD0),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Palette.ink, width: 2),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: fraction.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            color: Palette.green,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}
