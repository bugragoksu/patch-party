import 'dart:async';

import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/scan_code.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/play/application/play_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FR-05: type the short code under someone's QR, e.g. K7M-4821.
class ManualEntry extends ConsumerStatefulWidget {
  const new({super.key});

  @override
  ConsumerState<ManualEntry> createState() => _ManualEntryState();
}

class _ManualEntryState extends ConsumerState<ManualEntry> {
  final _code = TextEditingController();

  @override
  void initState() {
    super.initState();
    _code.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  bool get _valid => ScanInput.parse(_code.text) is ManualCode;

  void _submit() {
    if (_valid) {
      unawaited(
        ref.read(playControllerProvider.notifier).submitCode(_code.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(playControllerProvider.select((s) => s.busy));
    final controller = ref.read(playControllerProvider.notifier);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Kodu elle gir',
          textAlign: TextAlign.center,
          style: TextStyles.display.copyWith(
            fontSize: 24,
            color: Palette.paper,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Karşındakinin QR'ının altındaki kısa kod",
          textAlign: TextAlign.center,
          style: TextStyles.ui.copyWith(fontSize: 14, color: Palette.textMuted),
        ),
        const SizedBox(height: 22),
        Sticker(
          shadow: Palette.blue,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: TextField(
            controller: _code,
            autofocus: true,
            maxLength: 8,
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp('[0-9A-Za-z -]')),
            ],
            style: TextStyles.code.copyWith(fontSize: 32, color: Palette.ink),
            decoration: InputDecoration(
              hintText: 'K7M-4821',
              hintStyle: TextStyles.code.copyWith(
                fontSize: 32,
                color: const Color(0xFFCFC9BD),
              ),
              counterText: '',
            ),
            onSubmitted: (_) => _submit(),
          ),
        ),
        const SizedBox(height: 22),
        PrimaryButton(
          label: 'Gönder',
          busy: busy,
          onPressed: _valid ? _submit : null,
        ),
        const SizedBox(height: 8),
        LinkButton(label: 'Kameraya dön', onPressed: controller.showScan),
      ],
    );
  }
}
