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
                    // No countdown on purpose: a ticking timer made people
                    // rush. The code just rotates; the server accepts the
                    // neighbouring windows too.
                    Text(
                      code,
                      textAlign: TextAlign.center,
                      style: TextStyles.code.copyWith(
                        fontSize: 22,
                        color: Palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Kod kendiliğinden yenilenir, ekran görüntüsü işe yaramaz.',
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
