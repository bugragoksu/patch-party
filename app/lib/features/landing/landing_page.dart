import 'package:baglanti_agi/app/env.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/platform/browser.dart';
import 'package:baglanti_agi/core/ui/brand_mark.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/chips.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:flutter/material.dart';

/// What the game is, shown at `/` when no event is open and this browser has
/// not joined one. Players never see it during an event: they arrive through
/// the projector QR (`/j/CODE`).
class LandingPage extends StatefulWidget {
  const new({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

/// One string in both languages.
typedef _T = ({String tr, String en});

class _LandingPageState extends State<LandingPage> {
  bool _tr = Browser.prefersTurkish;

  String t(_T s) => _tr ? s.tr : s.en;

  void _openRepo() => Browser.openExternal(Env.repoUrl);
  void _openSetup() =>
      Browser.openExternal('${Env.repoUrl}#run-it-for-your-own-event');

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 860;
    return Scaffold(
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: wide ? 40 : 20,
                vertical: 20,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _TopBar(
                    turkish: _tr,
                    onLanguage: (tr) => setState(() => _tr = tr),
                    onRepo: _openRepo,
                  ),
                  SizedBox(height: wide ? 56 : 32),
                  _Hero(
                    wide: wide,
                    t: t,
                    onRepo: _openRepo,
                    onSetup: _openSetup,
                  ),
                  SizedBox(height: wide ? 88 : 56),
                  _SectionTitle(t((tr: 'Nasıl oynanır?', en: 'How it plays'))),
                  const SizedBox(height: 24),
                  _Steps(wide: wide, t: t),
                  SizedBox(height: wide ? 88 : 56),
                  _SectionTitle(
                    t((
                      tr: "İlk kez GDG Adana'da oynandı",
                      en: 'First played at GDG Adana',
                    )),
                  ),
                  const SizedBox(height: 24),
                  _Stats(t: t),
                  SizedBox(height: wide ? 88 : 56),
                  _OpenSource(t: t, onRepo: _openRepo, onSetup: _openSetup),
                  const SizedBox(height: 48),
                  _Footer(t: t, onRepo: _openRepo),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const new({
    required this.turkish,
    required this.onLanguage,
    required this.onRepo,
  });

  final bool turkish;
  final ValueChanged<bool> onLanguage;
  final VoidCallback onRepo;

  @override
  Widget build(BuildContext context) {
    Widget lang(String label, {required bool tr}) {
      final active = turkish == tr;
      return Semantics(
        button: true,
        selected: active,
        child: InkWell(
          onTap: () => onLanguage(tr),
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: active ? Palette.paper : Colors.transparent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: TextStyles.label.copyWith(
                fontSize: 12,
                color: active ? Palette.ink : Palette.textMuted,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        const BrandMark(size: 40),
        const SizedBox(width: 10),
        Text(
          'Patch Party',
          style: TextStyles.display.copyWith(
            fontSize: 20,
            color: Palette.paper,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Palette.line, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [lang('TR', tr: true), lang('EN', tr: false)],
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'GitHub',
          onPressed: onRepo,
          icon: const Icon(Icons.code, color: Palette.paper),
        ),
      ],
    );
  }
}

class _Hero extends StatelessWidget {
  const new({
    required this.wide,
    required this.t,
    required this.onRepo,
    required this.onSetup,
  });

  final bool wide;
  final String Function(_T) t;
  final VoidCallback onRepo;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t((
            tr: 'ETKİNLİKLER İÇİN TANIŞMA OYUNU',
            en: 'A NETWORKING GAME FOR EVENTS',
          )),
          style: TextStyles.label.copyWith(fontSize: 13, color: Palette.yellow),
        ),
        const SizedBox(height: 14),
        Text(
          t((
            tr: 'Tanışmayı oyuna çevir.',
            en: 'Turn meeting people into a game.',
          )),
          style: TextStyles.display.copyWith(
            fontSize: wide ? 56 : 36,
            color: Palette.paper,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          t((
            tr:
                "Herkes telefonundan katılır, birbirinin QR'ını okutarak "
                'tanışır ve her eşleşmeye ortak bir sohbet sorusu gelir. '
                'Projeksiyonda salonun bağlantı ağı canlı büyür. Uygulama '
                'indirmek yok.',
            en:
                'Everyone joins from their phone, meets by scanning each '
                "other's QR code, and every pair gets a conversation "
                "starter. The room's network grows live on the projector. "
                'Nothing to install.',
          )),
          style: TextStyles.ui.copyWith(
            fontSize: wide ? 19 : 16,
            color: const Color(0xFFD8D3C8),
          ),
        ),
        const SizedBox(height: 28),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            SizedBox(
              width: 220,
              child: PrimaryButton(
                label: t((tr: "GitHub'da incele", en: 'View on GitHub')),
                onPressed: onRepo,
              ),
            ),
            SizedBox(
              width: 220,
              child: GhostButton(
                label: t((
                  tr: 'Kendi etkinliğinde kur',
                  en: 'Run it at your event',
                )),
                height: 60,
                onPressed: onSetup,
              ),
            ),
          ],
        ),
      ],
    );
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [text, const SizedBox(height: 40), const _HeroArt()],
      );
    }
    return Row(
      children: [
        Expanded(flex: 6, child: text),
        const SizedBox(width: 40),
        const Expanded(flex: 5, child: _HeroArt()),
      ],
    );
  }
}

/// A small collage of the game's own stickers: a QR card, interests and
/// the score pops players see.
class _HeroArt extends StatelessWidget {
  const new();

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.05,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: w * 0.12,
                top: w * 0.06,
                width: w * 0.62,
                child: StampIn(
                  child: Sticker(
                    shadow: Palette.yellow,
                    shadowOffset: 8,
                    tiltDegrees: -4,
                    radius: 26,
                    padding: EdgeInsets.all(w * 0.05),
                    child: Column(
                      children: [
                        BrandMark(size: w * 0.34),
                        SizedBox(height: w * 0.03),
                        Text(
                          'K7M-4821',
                          style: TextStyles.code.copyWith(
                            fontSize: w * 0.06,
                            color: Palette.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 0,
                top: w * 0.02,
                child: Transform.rotate(
                  angle: 0.12,
                  child: const _Pop(value: '+10', color: Palette.blue),
                ),
              ),
              Positioned(
                right: w * 0.04,
                top: w * 0.42,
                child: Transform.rotate(
                  angle: -0.1,
                  child: const _Pop(value: '+5', color: Palette.green),
                ),
              ),
              Positioned(
                left: 0,
                bottom: w * 0.04,
                right: w * 0.05,
                child: const Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    InterestChip(interestId: 'flutter'),
                    InterestChip(interestId: 'ai'),
                    InterestChip(interestId: 'design'),
                    InterestChip(interestId: 'security'),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Pop extends StatelessWidget {
  const new({required this.value, required this.color});

  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      color: color,
      shadow: Palette.paper,
      radius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Text(
        value,
        style: TextStyles.display.copyWith(fontSize: 30, color: Palette.ink),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const new(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyles.display.copyWith(fontSize: 30, color: Palette.paper),
  );
}

class _Steps extends StatelessWidget {
  const new({required this.wide, required this.t});

  final bool wide;
  final String Function(_T) t;

  @override
  Widget build(BuildContext context) {
    final steps = <(IconData, Color, _T, _T)>[
      (
        Icons.qr_code_2,
        Palette.blue,
        (tr: 'Katıl', en: 'Join'),
        (
          tr: "Projeksiyondaki QR'ı okut, adını ve 2-3 ilgi alanını seç.",
          en: 'Scan the QR on the projector, pick a name and 2-3 interests.',
        ),
      ),
      (
        Icons.handshake_outlined,
        Palette.green,
        (tr: 'Okut ve onayla', en: 'Scan and confirm'),
        (
          tr:
              "Yanındakinin QR'ını okut, o da onaylasın. QR 30 saniyede "
              'bir değişir; ekran görüntüsü işe yaramaz.',
          en:
              'Scan the person next to you; they confirm. QR codes rotate '
              "every 30 seconds, so screenshots don't work.",
        ),
      ),
      (
        Icons.forum_outlined,
        Palette.yellow,
        (tr: 'Konuş', en: 'Talk'),
        (
          tr:
              'İkinize ortak bir soru gelir. Ortak ilgi alanınız yoksa '
              '+5 bonus: amaç çevrenin dışına çıkmak.',
          en:
              'You both get the same question. No shared interests? +5 '
              'bonus: the point is to meet new circles.',
        ),
      ),
      (
        Icons.emoji_events_outlined,
        Palette.red,
        (tr: 'Kazananlar', en: 'Winners'),
        (
          tr:
              'Ağ projeksiyonda canlı büyür. Sonunda kazananlar 3-2-1 '
              'sırasıyla, konfetiyle açıklanır.',
          en:
              'The network grows live on the projector. At the end, winners '
              'are revealed 3-2-1, with confetti.',
        ),
      ),
    ];
    final cards = [
      for (var i = 0; i < steps.length; i++)
        _StepCard(
          number: i + 1,
          icon: steps[i].$1,
          color: steps[i].$2,
          title: t(steps[i].$3),
          body: t(steps[i].$4),
          tilt: i.isEven ? -1.2 : 1.2,
        ),
    ];
    if (!wide) {
      return Column(
        children: [
          for (final c in cards)
            Padding(padding: const EdgeInsets.only(bottom: 18), child: c),
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < cards.length; i++) ...[
          if (i > 0) const SizedBox(width: 18),
          Expanded(child: cards[i]),
        ],
      ],
    );
  }
}

class _StepCard extends StatelessWidget {
  const new({
    required this.number,
    required this.icon,
    required this.color,
    required this.title,
    required this.body,
    required this.tilt,
  });

  final int number;
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final double tilt;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      shadow: color,
      tiltDegrees: tilt,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Sticker(
                color: color,
                radius: 30,
                padding: const EdgeInsets.all(10),
                child: Icon(icon, color: Palette.ink, size: 26),
              ),
              const Spacer(),
              Text(
                '$number',
                style: TextStyles.display.copyWith(
                  fontSize: 28,
                  color: Palette.inkMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyles.display.copyWith(
              fontSize: 21,
              color: Palette.ink,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: TextStyles.ui.copyWith(fontSize: 15, color: Palette.ink),
          ),
        ],
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  const new({required this.t});

  final String Function(_T) t;

  @override
  Widget build(BuildContext context) {
    final stats = <(String, _T, Color)>[
      ('80', (tr: 'oyuncu', en: 'players'), Palette.blue),
      ('466', (tr: 'bağlantı', en: 'connections'), Palette.green),
      ('25', (tr: 'dakika', en: 'minutes'), Palette.yellow),
      (
        '145',
        (tr: 'zıt kutup eşleşmesi', en: 'cross-interest pairs'),
        Palette.red,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        // Four in a row, or two by two: never an orphan on its own line.
        final cols = c.maxWidth >= 720 ? 4 : 2;
        final w = (c.maxWidth - (cols - 1) * 18 - 8) / cols;
        return Wrap(
          spacing: 18,
          runSpacing: 18,
          children: [
            for (final (value, label, color) in stats)
              SizedBox(
                width: w,
                child: Sticker(
                  color: color,
                  shadow: Palette.paper,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value,
                        style: TextStyles.display.copyWith(
                          fontSize: 48,
                          color: Palette.ink,
                        ),
                      ),
                      Text(
                        t(label),
                        style: TextStyles.ui.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Palette.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _OpenSource extends StatelessWidget {
  const new({required this.t, required this.onRepo, required this.onSetup});

  final String Function(_T) t;
  final VoidCallback onRepo;
  final VoidCallback onSetup;

  @override
  Widget build(BuildContext context) {
    const tech = ['Flutter web', 'Firebase', 'Cloud Functions', 'MIT'];
    return Sticker(
      color: Palette.asphaltRaised,
      outline: Palette.line,
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t((
              tr: 'Açık kaynak: kendi etkinliğinde kullan',
              en: 'Open source: run it at your own event',
            )),
            style: TextStyles.display.copyWith(
              fontSize: 26,
              color: Palette.paper,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            t((
              tr:
                  'Bir Firebase projesi, tek bir yapılandırma dosyası ve '
                  'birkaç komut yeterli. Adı, logoyu, ilgi alanlarını ve '
                  'soruları kendi topluluğuna göre değiştirebilirsin.',
              en:
                  'One Firebase project, a single config file and a few '
                  'commands. Change the name, logo, interests and questions '
                  'to fit your community.',
            )),
            style: TextStyles.ui.copyWith(
              fontSize: 16,
              color: const Color(0xFFD8D3C8),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in tech)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Palette.line, width: 2),
                  ),
                  child: Text(
                    name,
                    style: TextStyles.code.copyWith(
                      fontSize: 13,
                      color: Palette.paper,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 22),
          Wrap(
            spacing: 14,
            runSpacing: 14,
            children: [
              SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: t((tr: 'Kurulum rehberi', en: 'Setup guide')),
                  onPressed: onSetup,
                ),
              ),
              SizedBox(
                width: 220,
                child: GhostButton(
                  label: 'GitHub',
                  height: 60,
                  onPressed: onRepo,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const new({required this.t, required this.onRepo});

  final String Function(_T) t;
  final VoidCallback onRepo;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 4,
      children: [
        Text(
          t((
            tr: 'MIT lisanslı · GDG Adana Info Session için yapıldı',
            en: 'MIT licensed · Built for GDG Adana Info Session',
          )),
          style: TextStyles.ui.copyWith(fontSize: 13, color: Palette.textMuted),
        ),
        LinkButton(label: 'GitHub', onPressed: onRepo),
      ],
    );
  }
}
