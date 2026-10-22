import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/avatar.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/domain/token.dart';
import 'package:baglanti_agi/core/ui/avatar.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/projector/application/projector_providers.dart';
import 'package:baglanti_agi/features/projector/presentation/format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:qr_flutter/qr_flutter.dart';

// Projector building blocks. Sizes target a 1920×1080 stage that is scaled to
// the screen (04-design.md §5): text ≥ 20 px, numbers ≥ 26 px.

class PlayerAvatar extends StatelessWidget {
  const new({required this.player, super.key, this.size = 40});

  final Player player;
  final double size;

  @override
  Widget build(BuildContext context) => AvatarBadge(
    spec: AvatarSpec.of(player.publicName, player.interests),
    size: size,
  );
}

/// Paper counter sticker: big number + label.
class CountSticker extends StatelessWidget {
  const new({
    required this.value,
    required this.label,
    super.key,
    this.shadow = Palette.blue,
    this.color = Palette.paper,
    this.mono = false,
    this.fontSize = 38,
  });

  final String value;
  final String label;
  final Color shadow;
  final Color color;
  final bool mono;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      color: color,
      shadow: shadow,
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.baseline,
        textBaseline: TextBaseline.alphabetic,
        children: [
          Text(
            value,
            style: (mono ? TextStyles.code : TextStyles.display).copyWith(
              fontSize: fontSize,
              color: Palette.ink,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyles.ui.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Red "CANLI" pill with a pulsing dot.
class LivePill extends StatefulWidget {
  const new({super.key});

  @override
  State<LivePill> createState() => _LivePillState();
}

class _LivePillState extends State<LivePill>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: Motion.pulse,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _c
        ..stop()
        ..value = 1;
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
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      decoration: BoxDecoration(
        color: Palette.red,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Palette.ink, width: Stroke.width),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FadeTransition(
            opacity: Tween<double>(
              begin: 0.4,
              end: 1,
            ).animate(CurvedAnimation(parent: _c, curve: Curves.easeInOut)),
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Palette.ink,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'CANLI',
            style: TextStyles.ui.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: 2,
              color: Palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// Remaining live time, ticking every second on its own.
class RemainingSticker extends ConsumerWidget {
  const new({required this.endAt, super.key});

  final int endAt;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    return CountSticker(
      value: formatRemaining(endAt, now),
      label: 'kaldı',
      color: Palette.yellow,
      shadow: Palette.paper,
      mono: true,
    );
  }
}

/// Join QR + rotating code (FR-22). Rebuilds itself every second; the code
/// changes once per join window and needs no write (02-architecture §7.2).
class JoinQrCard extends ConsumerWidget {
  const new({
    required this.event,
    super.key,
    this.qrSize = 420,
    this.horizontal = false,
  });

  final EventInfo event;
  final double qrSize;
  final bool horizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seed = ref.watch(joinSeedProvider);
    final now =
        ref.watch(nowProvider).value ?? DateTime.now().millisecondsSinceEpoch;
    final codeSize = horizontal ? 40.0 : 64.0;

    Widget qrArea;
    String? code;
    final seedValue = seed.value;
    if (seedValue != null && seedValue.isNotEmpty) {
      code = joinCodeFor(
        seedValue,
        event.id,
        windowOf(now, event.settings.joinWindowSec),
      );
      qrArea = QrImageView(
        data: joinLink(webOrigin(), code),
        size: qrSize,
        padding: EdgeInsets.zero,
        backgroundColor: Palette.paper,
        errorCorrectionLevel: QrErrorCorrectLevel.M,
        semanticsLabel: 'Katılım QR kodu',
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Palette.ink,
        ),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Palette.ink,
        ),
      );
    } else {
      final failed = seed.hasError || (seed.hasValue && seedValue == null);
      qrArea = SizedBox.square(
        dimension: qrSize,
        child: Center(
          child: failed
              ? Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Katılım kodu okunamadı',
                    textAlign: TextAlign.center,
                    style: TextStyles.ui.copyWith(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Palette.inkMuted,
                    ),
                  ),
                )
              : const CircularProgressIndicator(color: Palette.ink),
        ),
      );
    }

    final minutes = (event.settings.joinWindowSec / 60).round();
    final texts = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          'Okut ve katıl',
          style: TextStyles.display.copyWith(
            fontSize: horizontal ? 28 : 40,
            color: Palette.ink,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          minutes >= 1
              ? 'Kod $minutes dakikada bir değişir'
              : 'Kod düzenli olarak değişir',
          style: TextStyles.ui.copyWith(fontSize: 20, color: Palette.inkMuted),
        ),
        if (code != null) ...[
          const SizedBox(height: 8),
          Text(
            formatJoinCode(code),
            style: TextStyles.code.copyWith(
              fontSize: codeSize,
              color: Palette.ink,
              letterSpacing: 3,
            ),
          ),
        ],
      ],
    );

    return Sticker(
      shadow: Palette.yellow,
      shadowOffset: 8,
      radius: Radii.big,
      tiltDegrees: horizontal ? -1 : -2,
      padding: EdgeInsets.all(horizontal ? 18 : 28),
      child: horizontal
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                qrArea,
                const SizedBox(width: 20),
                Flexible(child: texts),
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [qrArea, const SizedBox(height: 20), texts],
            ),
    );
  }
}

/// Shown over the last data when a stream fails; Riverpod also retries.
class StreamErrorBanner extends StatelessWidget {
  const new({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      outline: Palette.red,
      shadow: Palette.red,
      radius: 16,
      padding: const EdgeInsets.fromLTRB(20, 8, 8, 8),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Bağlantı koptu, son veriler gösteriliyor.',
            style: TextStyles.ui.copyWith(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 240,
            child: PrimaryButton(
              label: 'Yeniden bağlan',
              onPressed: onRetry,
              shadow: Palette.ink,
              height: 52,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section title on the dark ground.
class StageTitle extends StatelessWidget {
  const new(this.text, {super.key, this.size = 30});

  final String text;
  final double size;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyles.title.copyWith(fontSize: size, color: Palette.paper),
  );
}
