import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/ui/buttons.dart';
import 'package:baglanti_agi/core/ui/feedback.dart';
import 'package:baglanti_agi/core/ui/sticker.dart';
import 'package:baglanti_agi/features/admin/data/admin_repository.dart';
import 'package:flutter/material.dart';

/// Server failure text for the panel. Admin-only reasons that [GameFailure]
/// does not model get their own line; everything else uses [failureMessage].
String adminFailureMessage(Err<Object?> err) {
  final reason = err is AdminErr<Object?> ? err.reason : null;
  return switch (reason) {
    'invalid_transition' =>
      'Bu durum geçişi şu an geçerli değil. Durum başka biri tarafından '
          'değiştirilmiş olabilir.',
    'invalid_argument' => 'Sunucu girilen değerleri kabul etmedi.',
    _ => failureMessage(err.failure),
  };
}

/// A paper sticker with a small uppercase label: one panel section.
class AdminSection extends StatelessWidget {
  const new({
    required this.title,
    required this.child,
    super.key,
    this.trailing,
    this.outline = Palette.ink,
    this.shadow = Palette.paper,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final Color outline;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22, right: 6),
      child: Sticker(
        outline: outline,
        shadow: shadow,
        shadowOffset: 5,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title.toUpperCase(),
                      style: TextStyles.label.copyWith(color: Palette.inkMuted),
                    ),
                  ),
                ),
                ?trailing,
              ],
            ),
            const SizedBox(height: 10),
            // Ink (switches, row highlights) paints on the paper, not under it.
            Material(type: MaterialType.transparency, child: child),
          ],
        ),
      ),
    );
  }
}

/// Compact sticker button for tool actions on paper.
class ToolButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.color = Palette.yellow,
    this.busy = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 96),
        child: PrimaryButton(
          label: label,
          onPressed: onPressed,
          busy: busy,
          color: color,
          shadow: Palette.ink,
          height: 44,
        ),
      ),
    );
  }
}

/// Plain outlined action on paper (cancel, secondary choices).
class InkOutlineButton extends StatelessWidget {
  const new({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.ink,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: Palette.ink, width: 2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Radii.button),
        ),
        textStyle: TextStyles.ui.copyWith(fontWeight: FontWeight.w700),
      ),
      child: Text(label),
    );
  }
}

/// Labeled text field drawn for the paper surface.
class PaperField extends StatelessWidget {
  const new({
    required this.label,
    required this.controller,
    super.key,
    this.error,
    this.hint,
    this.numeric = false,
    this.onChanged,
    this.onSubmitted,
    this.maxLength,
    this.autofocus = false,
  });

  final String label;
  final TextEditingController controller;
  final String? error;
  final String? hint;
  final bool numeric;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Palette.ink, width: 2),
    );
    return TextField(
      controller: controller,
      autofocus: autofocus,
      keyboardType: numeric ? TextInputType.number : TextInputType.text,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      maxLength: maxLength,
      style: TextStyles.ui.copyWith(color: Palette.ink, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        errorText: error,
        counterText: '',
        isDense: true,
        filled: true,
        fillColor: Palette.paper,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        labelStyle: TextStyles.ui.copyWith(color: Palette.inkMuted),
        floatingLabelStyle: TextStyles.ui.copyWith(
          color: Palette.ink,
          fontWeight: FontWeight.w700,
        ),
        hintStyle: TextStyles.ui.copyWith(color: Palette.inkMuted),
        errorStyle: TextStyles.ui.copyWith(
          color: Palette.red,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: Palette.blue, width: 3),
        ),
        errorBorder: border.copyWith(
          borderSide: const BorderSide(color: Palette.red, width: 2),
        ),
        focusedErrorBorder: border.copyWith(
          borderSide: const BorderSide(color: Palette.red, width: 3),
        ),
      ),
    );
  }
}

/// In-page confirmation (no browser dialogs): states the consequence and
/// offers confirm / cancel. [child] may hold extra inputs.
class ConfirmStrip extends StatelessWidget {
  const new({
    required this.message,
    required this.confirmLabel,
    required this.onConfirm,
    required this.onCancel,
    super.key,
    this.busy = false,
    this.danger = false,
    this.child,
  });

  final String message;
  final String confirmLabel;
  final VoidCallback? onConfirm;
  final VoidCallback onCancel;
  final bool busy;
  final bool danger;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final accent = danger ? Palette.red : Palette.yellow;
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.ink, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                danger ? Icons.warning_amber_rounded : Icons.help_outline,
                color: Palette.ink,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: TextStyles.ui.copyWith(
                    color: Palette.ink,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          if (child != null) ...[const SizedBox(height: 10), child!],
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.end,
            children: [
              InkOutlineButton(
                label: 'Vazgeç',
                onPressed: busy ? null : onCancel,
              ),
              ToolButton(
                label: confirmLabel,
                onPressed: onConfirm,
                busy: busy,
                color: danger ? Palette.red : Palette.yellow,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// One-line result of the last action in a section.
class StatusNote extends StatelessWidget {
  const new({required this.text, super.key, this.error = false});

  final String text;
  final bool error;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Padding(
        padding: const EdgeInsets.only(top: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              error ? Icons.error_outline : Icons.check_circle_outline,
              size: 18,
              color: error ? Palette.red : Palette.green,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyles.ui.copyWith(
                  color: Palette.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Small pill on paper: state, flags.
class Tag extends StatelessWidget {
  const new({required this.label, super.key, this.color = Palette.yellow});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Palette.ink, width: 2),
      ),
      child: Text(
        label,
        style: TextStyles.ui.copyWith(
          color: Palette.ink,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.3,
        ),
      ),
    );
  }
}

String formatClock(int ms) {
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(t.hour)}:${two(t.minute)}:${two(t.second)}';
}
