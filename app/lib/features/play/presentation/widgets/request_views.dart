import 'dart:async';

import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/avatar.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/domain/scoring.dart';
import 'package:baglanti_agi/core/ui/avatar.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/chips.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/application/play_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// "Onay bekleniyor": my request is out, the other phone decides (FR-15).
class WaitingView extends ConsumerWidget {
  const new({required this.waiting, super.key});

  final Waiting waiting;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final left = ((waiting.expiresAt - now) / 1000).ceil().clamp(0, 999);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        PopIn(
          child: AvatarBadge(
            spec: AvatarSpec.of(waiting.targetName, waiting.targetInterests),
            size: 112,
            outline: Palette.paper,
          ),
        ),
        const SizedBox(height: 22),
        Text(
          '${waiting.targetName} onaylasın',
          textAlign: TextAlign.center,
          style: TextStyles.display.copyWith(
            fontSize: 26,
            color: Palette.paper,
          ),
        ),
        const SizedBox(height: 10),
        _Pulse(
          child: Text(
            left > 0 ? 'istek $left sn geçerli' : 'süre doluyor…',
            style: TextStyles.code.copyWith(
              fontSize: 15,
              color: Palette.yellow,
            ),
          ),
        ),
        const SizedBox(height: 24),
        LinkButton(
          label: 'Vazgeç',
          onPressed: () => unawaited(
            ref.read(playControllerProvider.notifier).cancelWaiting(),
          ),
        ),
      ],
    );
  }
}

/// Someone scanned me: approve or decline (FR-15).
class IncomingRequestCard extends ConsumerStatefulWidget {
  const new({required this.request, required this.me, super.key});

  final ConnectionRequest request;
  final Player me;

  @override
  ConsumerState<IncomingRequestCard> createState() =>
      _IncomingRequestCardState();
}

class _IncomingRequestCardState extends ConsumerState<IncomingRequestCard> {
  bool _busy = false;

  Future<void> _answer({required bool accept}) async {
    setState(() => _busy = true);
    final result = await ref
        .read(playControllerProvider.notifier)
        .respond(widget.request.id, accept: accept);
    if (!mounted) return;
    setState(() => _busy = false);
    if (result case Err(:final failure)) {
      if (failure is! RequestExpired || accept) showFailure(context, failure);
    }
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.request;
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final left = ((r.expiresAt - now) / 1000).ceil().clamp(0, 999);
    final points = pointsFor(widget.me.interests, r.fromInterests);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'YENİ BAĞLANTI İSTEĞİ',
          textAlign: TextAlign.center,
          style: TextStyles.label.copyWith(color: Palette.yellow, fontSize: 12),
        ),
        const SizedBox(height: 16),
        StampIn(
          child: Sticker(
            shadow: Palette.blue,
            shadowOffset: 8,
            radius: 24,
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                AvatarBadge(
                  spec: AvatarSpec.of(r.fromName, r.fromInterests),
                  size: 92,
                ),
                const SizedBox(height: 12),
                Text(
                  r.fromName,
                  style: TextStyles.display.copyWith(
                    fontSize: 24,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final i in r.fromInterests)
                      InterestChip(interestId: i, compact: true),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  points.bonus > 0
                      ? 'Ortak ilgi alanınız yok: onaylarsan ikinize '
                            '+${points.total} puan'
                      : 'Onaylarsan ikinize +${points.total} puan',
                  textAlign: TextAlign.center,
                  style: TextStyles.ui.copyWith(
                    fontSize: 14,
                    color: Palette.inkMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$left sn',
                  style: TextStyles.code.copyWith(
                    fontSize: 13,
                    color: Palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: GhostButton(
                label: 'Şimdi değil',
                onPressed: _busy ? null : () => _answer(accept: false),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: PrimaryButton(
                label: 'Onayla',
                color: Palette.green,
                height: 52,
                busy: _busy,
                onPressed: () => _answer(accept: true),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Pulse extends StatefulWidget {
  const new({required this.child});
  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: Motion.pulse);

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
  Widget build(BuildContext context) => FadeTransition(
    opacity: Tween<double>(begin: 0.35, end: 1).animate(_c),
    child: widget.child,
  );
}
