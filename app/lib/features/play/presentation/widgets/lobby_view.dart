import 'dart:async';

import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/avatar.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/ui/avatar.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/chips.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/presentation/how_to_play.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Shown instead of the QR while scanning is closed: before the game starts,
/// and when a live window ran out. Switches to the QR by itself once live.
class LobbyView extends ConsumerStatefulWidget {
  const new({required this.player, required this.paused, super.key});

  final Player player;

  /// Live state but outside the time window (expired or not extended yet).
  final bool paused;

  @override
  ConsumerState<LobbyView> createState() => _LobbyViewState();
}

class _LobbyViewState extends ConsumerState<LobbyView> {
  // Keeps the phone awake so the QR is on screen the moment the game starts.
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
    final me = widget.player;
    final paused = widget.paused;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          paused ? 'Oyun duraklatıldı' : 'Oyun birazdan başlıyor',
          style: TextStyles.ui.copyWith(
            fontSize: 14,
            color: const Color(0xFFD8D3C8),
          ),
        ),
        const SizedBox(height: 16),
        StampIn(
          child: Sticker(
            shadow: paused ? Palette.red : Palette.yellow,
            shadowOffset: 8,
            tiltDegrees: -2,
            radius: 24,
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Breathing(
                  child: AvatarBadge(
                    spec: AvatarSpec.of(me.displayName, me.interests),
                    size: 92,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  paused ? 'Biraz bekle' : 'Hazırsın!',
                  textAlign: TextAlign.center,
                  style: TextStyles.display.copyWith(
                    fontSize: 26,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  paused
                      ? 'Görevliler oyunu yeniden açınca '
                            'QR’ın burada belirecek.'
                      : 'Oyun başlayınca QR’ın burada belirecek. '
                            'Ekranı açık tut.',
                  textAlign: TextAlign.center,
                  style: TextStyles.ui.copyWith(
                    fontSize: 15,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final i in me.interests)
                      InterestChip(interestId: i, compact: true),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),
        LinkButton(
          label: 'Nasıl oynanır?',
          onPressed: () => ref.read(howToPlaySeenProvider.notifier).showAgain(),
        ),
      ],
    );
  }
}

/// Slow scale in and out; still under reduced motion.
class _Breathing extends StatefulWidget {
  const new({required this.child});

  final Widget child;

  @override
  State<_Breathing> createState() => _BreathingState();
}

class _BreathingState extends State<_Breathing>
    with SingleTickerProviderStateMixin {
  late final _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ScaleTransition(
    scale: Tween<double>(
      begin: 0.94,
      end: 1.06,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
    child: widget.child,
  );
}
