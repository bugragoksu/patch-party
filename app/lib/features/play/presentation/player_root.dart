import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/ui/chips.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/features/join/presentation/join_screen.dart';
import 'package:baglanti_agi/features/play/application/session.dart';
import 'package:baglanti_agi/features/play/presentation/game_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Player surface entry: join if this browser has no player yet, else play.
class PlayerRoot extends ConsumerWidget {
  const new({super.key, this.joinCode, this.scannedPayload});

  final String? joinCode;
  final String? scannedPayload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(playerSessionProvider);
    final body = session.when(
      data: (s) => s == null
          ? JoinScreen(joinCode: joinCode)
          : GameScreen(scannedPayload: scannedPayload),
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator(color: Palette.yellow)),
      ),
      error: (error, stack) {
        unawaited(
          ref
              .read(errorReporterProvider)
              .report(error, stack, surface: 'player'),
        );
        return Scaffold(
          body: ErrorCard(
            message: 'Oturumun yüklenemedi. Sayfayı yenilemeyi dene.',
            actionLabel: 'Tekrar dene',
            onAction: () => ref.invalidate(playerSessionProvider),
          ),
        );
      },
    );
    if (!Browser.isInAppBrowser) return body;
    return Column(
      children: [
        Material(
          color: Palette.asphalt,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: NoticeBox(
                child: Text(
                  'Uygulama içi tarayıcıdasın. Kamera çalışmazsa linki Chrome '
                  "ya da Safari'de aç.",
                  style: TextStyles.ui.copyWith(fontSize: 13),
                ),
              ),
            ),
          ),
        ),
        Expanded(child: body),
      ],
    );
  }
}
