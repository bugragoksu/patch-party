import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/application/session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether this browser has been through the how-to-play cards.
final howToPlaySeenProvider = NotifierProvider<HowToPlaySeen, bool>(
  HowToPlaySeen.new,
);

class HowToPlaySeen extends Notifier<bool> {
  static const _key = 'bag.howToPlay.v1';

  @override
  bool build() => Browser.read(_key) == '1';

  void markSeen() {
    Browser.write(_key, '1');
    state = true;
  }

  /// Opens the cards again (from the lobby); finishing them marks seen.
  void showAgain() => state = false;
}

class _Step {
  const new({
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String body;
}

const _steps = [
  _Step(
    icon: Icons.qr_code_scanner,
    color: Palette.blue,
    title: 'Birini bul, QR’ını okut',
    body:
        'Telefonunda sana ait bir QR var. Yeni biriyle tanış, '
        '“Tara” ile onun QR’ını okut.',
  ),
  _Step(
    icon: Icons.handshake_outlined,
    color: Palette.green,
    title: 'İkiniz de onaylayın',
    body:
        'Okuttuğun kişi 45 saniye içinde onaylar. Bağlantı kurulunca '
        'ikinize de +10 puan ve konuşmak için ortak bir soru gelir.',
  ),
  _Step(
    icon: Icons.auto_awesome,
    color: Palette.yellow,
    title: 'Farklı olana bonus',
    body:
        'Ortak ilgi alanınız yoksa +5 bonus. '
        'Ne kadar çok yeni insan, o kadar puan. '
        'Sıralama projeksiyonda.',
  ),
];

/// FR-41: three cards shown once after joining. The game streams start
/// underneath so the QR is ready when the player taps "Oyna".
class HowToPlay extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<HowToPlay> createState() => _HowToPlayState();
}

class _HowToPlayState extends ConsumerState<HowToPlay> {
  final _pages = PageController();
  var _index = 0;

  bool get _last => _index == _steps.length - 1;

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  void _next() {
    if (_last) {
      ref.read(howToPlaySeenProvider.notifier).markSeen();
      return;
    }
    _pages.nextPage(
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Warm the streams the game screen needs next.
    ref
      ..watch(myPlayerProvider)
      ..watch(eventProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 8, 8, 0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'NASIL OYNANIR',
                          style: TextStyles.label.copyWith(
                            color: Palette.textMuted,
                          ),
                        ),
                      ),
                      LinkButton(
                        label: 'Atla',
                        onPressed: () =>
                            ref.read(howToPlaySeenProvider.notifier).markSeen(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pages,
                    itemCount: _steps.length,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemBuilder: (context, i) => _StepCard(
                      step: _steps[i],
                      number: i + 1,
                      tilt: i.isEven ? -1.5 : 1.5,
                    ),
                  ),
                ),
                _Dots(count: _steps.length, index: _index),
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                  child: PrimaryButton(
                    label: _last ? 'Oyna' : 'İleri',
                    onPressed: _next,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StepCard extends StatelessWidget {
  const new({required this.step, required this.number, required this.tilt});

  final _Step step;
  final int number;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(26, 18, 26, 18),
      child: Center(
        child: StampIn(
          child: Sticker(
            shadow: step.color,
            tiltDegrees: tilt,
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Sticker(
                      color: step.color,
                      radius: 40,
                      shadowOffset: 0,
                      padding: const EdgeInsets.all(14),
                      child: Icon(step.icon, size: 40, color: Palette.ink),
                    ),
                    const Spacer(),
                    Text(
                      '$number/${_steps.length}',
                      style: TextStyles.code.copyWith(
                        fontSize: 16,
                        color: Palette.inkMuted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  step.title,
                  style: TextStyles.display.copyWith(
                    fontSize: 24,
                    color: Palette.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  step.body,
                  style: TextStyles.ui.copyWith(
                    fontSize: 16,
                    color: Palette.ink,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const new({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: i == index ? 26 : 10,
            height: 10,
            decoration: BoxDecoration(
              color: i == index ? Palette.yellow : Palette.line,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Palette.paper, width: 1.5),
            ),
          ),
      ],
    );
  }
}
