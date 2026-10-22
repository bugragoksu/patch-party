import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/avatar.dart';
import 'package:baglanti_agi/core/domain/catalog.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/names.dart';
import 'package:baglanti_agi/core/observability/error_reporter.dart';
import 'package:baglanti_agi/core/ui/avatar.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/chips.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-01, FR-17: name + 2-3 interests, the projector's join code from the URL.
class JoinScreen extends ConsumerStatefulWidget {
  const new({super.key, this.joinCode});

  final String? joinCode;

  @override
  ConsumerState<JoinScreen> createState() => _JoinScreenState();
}

class _JoinScreenState extends ConsumerState<JoinScreen> {
  final _name = TextEditingController();
  late final _code = TextEditingController(text: widget.joinCode ?? '');
  final List<String> _picked = [];
  bool _busy = false;
  GameFailure? _failure;

  @override
  void initState() {
    super.initState();
    _name.addListener(() => setState(() {}));
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _code.dispose();
    super.dispose();
  }

  String get _cleanCode =>
      _code.text.toUpperCase().replaceAll(RegExp('[^0-9A-Z]'), '');

  bool get _canJoin =>
      !_busy &&
      isValidDisplayName(_name.text) &&
      Catalog.isValidPick(_picked) &&
      _cleanCode.length == 6;

  void _toggle(String id) {
    setState(() {
      if (_picked.contains(id)) {
        _picked.remove(id);
      } else {
        _picked.add(id);
        if (_picked.length > catalogMaxPick) _picked.removeAt(0);
      }
    });
  }

  Future<void> _join() async {
    if (!_canJoin) return;
    final reporter = ref.read(errorReporterProvider)
      ..breadcrumb(AppEvent.joinStarted);
    setState(() {
      _busy = true;
      _failure = null;
    });
    final result = await ref
        .read(gameRepositoryProvider)
        .join(
          eventId: ref.read(eventIdProvider),
          joinCode: _cleanCode,
          displayName: cleanDisplayName(_name.text),
          interests: List.of(_picked),
        );
    if (!mounted) return;
    switch (result) {
      case Ok(:final value):
        reporter.breadcrumb(AppEvent.joined);
        ref.read(clockOffsetProvider.notifier).learn(value.serverTime);
      // The auth state change moves PlayerRoot on to the game.
      case Err(:final failure):
        reporter.breadcrumb(
          AppEvent.joinRejected,
          detail: failure.runtimeType.toString(),
        );
        setState(() {
          _busy = false;
          _failure = failure;
        });
    }
  }

  void _useName(String name) {
    _name.text = name;
    setState(() => _failure = null);
  }

  @override
  Widget build(BuildContext context) {
    final event = ref.watch(eventProvider).value;
    final name = cleanDisplayName(_name.text);
    final avatar = AvatarSpec.of(name.isEmpty ? '?' : name, _picked);
    final failure = _failure;
    final needsCode = widget.joinCode == null || failure is JoinCodeInvalid;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 28),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (event?.settings.subtitle.isNotEmpty ?? false)
                            ? event!.settings.subtitle.toUpperCase()
                            : 'GDG ADANA',
                        style: TextStyles.label.copyWith(
                          color: Palette.textMuted,
                        ),
                      ),
                    ),
                    if (event != null && !event.canJoin)
                      Text(
                        'KAPALI',
                        style: TextStyles.label.copyWith(color: Palette.red),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  event?.settings.displayName ?? 'Bağlantı Ağı',
                  style: TextStyles.display.copyWith(
                    fontSize: 30,
                    color: Palette.paper,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Birinin QR'ını okut, onaylasın, "
                  'ikinize ortak bir soru gelsin.',
                  style: TextStyles.ui.copyWith(
                    fontSize: 15,
                    color: const Color(0xFFD8D3C8),
                  ),
                ),
                const SizedBox(height: 18),
                Sticker(
                  shadow: Palette.yellow,
                  tiltDegrees: -1.2,
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      AvatarBadge(spec: avatar),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _name,
                          maxLength: nameMaxLength,
                          textCapitalization: TextCapitalization.words,
                          autofillHints: const [AutofillHints.givenName],
                          style: TextStyles.ui.copyWith(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Palette.ink,
                          ),
                          decoration: InputDecoration(
                            labelText: 'Adın veya takma adın',
                            labelStyle: TextStyles.ui.copyWith(
                              color: Palette.inkMuted,
                              fontSize: 13,
                            ),
                            counterText: '',
                            enabledBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Palette.ink,
                                width: 3,
                              ),
                            ),
                            focusedBorder: const UnderlineInputBorder(
                              borderSide: BorderSide(
                                color: Palette.blue,
                                width: 3,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _join(),
                        ),
                      ),
                    ],
                  ),
                ),
                if (failure is NameTaken) ...[
                  const SizedBox(height: 14),
                  _NameTakenNotice(
                    name: name,
                    suggestion: failure.suggestion,
                    onPick: _useName,
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'İlgi alanların',
                        style: TextStyles.title.copyWith(
                          fontSize: 15,
                          color: Palette.paper,
                        ),
                      ),
                    ),
                    Text(
                      _picked.length < catalogMinPick
                          ? 'en az $catalogMinPick seç · ${_picked.length}/$catalogMaxPick'
                          : '${_picked.length}/$catalogMaxPick',
                      style: TextStyles.code.copyWith(
                        fontSize: 13,
                        color: Palette.yellow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: [
                    for (final i in catalogInterests)
                      InterestChip(
                        interestId: i.id,
                        selected: _picked.contains(i.id),
                        onTap: () => _toggle(i.id),
                      ),
                  ],
                ),
                if (needsCode) ...[
                  const SizedBox(height: 22),
                  _JoinCodeField(controller: _code),
                ],
                if (failure != null && failure is! NameTaken) ...[
                  const SizedBox(height: 14),
                  NoticeBox(
                    color: Palette.red,
                    child: Text(
                      failureMessage(failure),
                      style: TextStyles.ui.copyWith(fontSize: 14),
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Oyuna katıl',
                  busy: _busy,
                  onPressed: _canJoin ? _join : null,
                ),
                const SizedBox(height: 12),
                Text(
                  'Adın projeksiyonda görünür. '
                  'Fotoğraf ya da e-posta istemiyoruz. '
                  'Veriler etkinlikten sonra silinir.',
                  textAlign: TextAlign.center,
                  style: TextStyles.ui.copyWith(
                    fontSize: 12,
                    color: Palette.textMuted,
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

class _NameTakenNotice extends StatelessWidget {
  const new({
    required this.name,
    required this.suggestion,
    required this.onPick,
  });

  final String name;
  final String? suggestion;
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return NoticeBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Salonda bir $name var. '
            'Soyadının baş harfini ekleyebilirsin, ya da:',
            style: TextStyles.ui.copyWith(fontSize: 14),
          ),
          if (suggestion != null) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: 180,
              child: PrimaryButton(
                label: suggestion!,
                height: 44,
                shadow: Palette.ink,
                onPressed: () => onPick(suggestion!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _JoinCodeField extends StatelessWidget {
  const new({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Sticker(
      color: Palette.asphaltRaised,
      outline: Palette.line,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Projeksiyondaki QR'ı telefonunun kamerasıyla okut ya da kodu yaz:",
            style: TextStyles.ui.copyWith(fontSize: 14),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            maxLength: 7,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9A-Za-z-]')),
            ],
            style: TextStyles.code.copyWith(fontSize: 24, color: Palette.paper),
            decoration: InputDecoration(
              hintText: 'XXX-XXX',
              hintStyle: TextStyles.code.copyWith(
                fontSize: 24,
                color: Palette.inkMuted,
              ),
              counterText: '',
            ),
          ),
        ],
      ),
    );
  }
}
