import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/application/questions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const badgeLabels = {
  'first_connection': 'İlk Bağlantı',
  'bridge': 'Zıt Kutuplar',
  'explorer': 'Her Telden',
  'social_butterfly': 'Sosyal Kelebek',
};

/// "Bağlandınız!": points, the shared question, a new badge if any (FR-07/08/12).
class SuccessView extends ConsumerWidget {
  const new({
    required this.connection,
    required this.otherName,
    required this.newBadges,
    required this.onScanNext,
    required this.onDone,
    super.key,
  });

  final Connection connection;
  final String otherName;
  final List<String> newBadges;
  final VoidCallback onScanNext;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pool = ref.watch(questionPoolProvider).value;
    final question =
        pool?.questionFor(connection.questionKey, connection.questionSeed) ??
        QuestionPool.fallback;
    final base = connection.points - connection.bonus;

    return ListView(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      children: [
        Center(
          child: StampIn(
            child: Sticker(
              color: Palette.yellow,
              shadow: Palette.paper,
              tiltDegrees: -3,
              radius: 18,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              child: Text(
                'BAĞLANDINIZ!',
                style: TextStyles.display.copyWith(
                  fontSize: 28,
                  color: Palette.ink,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          otherName,
          textAlign: TextAlign.center,
          style: TextStyles.ui.copyWith(fontSize: 15, color: Palette.textMuted),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: PopIn(
                child: _PointsSticker(
                  value: '+$base',
                  label: 'yeni bağlantı',
                  color: Palette.blue,
                  tilt: -2,
                ),
              ),
            ),
            if (connection.bonus > 0) ...[
              const SizedBox(width: 12),
              Expanded(
                child: PopIn(
                  index: 1,
                  child: _PointsSticker(
                    value: '+${connection.bonus}',
                    label: 'farklı alan bonusu',
                    color: Palette.green,
                    tilt: 2,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 16),
        PopIn(
          index: 2,
          child: Sticker(
            shadow: Palette.red,
            radius: 20,
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ORTAK SORUNUZ · İKİNİZDE DE AYNI',
                  style: TextStyles.label.copyWith(color: Palette.inkMuted),
                ),
                const SizedBox(height: 10),
                Text(
                  question,
                  style: TextStyles.title.copyWith(
                    fontSize: 19,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Gemini ile hazırlanmış soru',
                  style: TextStyles.ui.copyWith(
                    fontSize: 11,
                    color: Palette.inkMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
        for (final badge in newBadges) ...[
          const SizedBox(height: 14),
          PopIn(
            index: 3,
            child: Sticker(
              color: Palette.asphaltRaised,
              outline: Palette.yellow,
              radius: 14,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: badgeLabels[badge] ?? badge,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const TextSpan(text: ' rozetini açtın'),
                  ],
                ),
                style: TextStyles.ui.copyWith(
                  fontSize: 14,
                  color: Palette.paper,
                ),
              ),
            ),
          ),
        ],
        const SizedBox(height: 22),
        PrimaryButton(label: 'Yeni birini tara', onPressed: onScanNext),
        const SizedBox(height: 6),
        Center(
          child: LinkButton(label: "QR'ıma dön", onPressed: onDone),
        ),
      ],
    );
  }
}

class _PointsSticker extends StatelessWidget {
  const new({
    required this.value,
    required this.label,
    required this.color,
    required this.tilt,
  });

  final String value;
  final String label;
  final Color color;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      color: color,
      tiltDegrees: tilt,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyles.display.copyWith(
              fontSize: 30,
              color: Palette.ink,
            ),
          ),
          Text(
            label,
            style: TextStyles.ui.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Palette.ink,
            ),
          ),
        ],
      ),
    );
  }
}
