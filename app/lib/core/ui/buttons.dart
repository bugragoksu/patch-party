import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:flutter/material.dart';

/// Main action: yellow sticker button. Disabled state drops color and shadow.
class PrimaryButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.busy = false,
    this.color = Palette.yellow,
    this.shadow = Palette.paper,
    this.height = 60,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final Color color;
  final Color shadow;
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !busy;
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: _Pressable(
        onTap: enabled ? onPressed : null,
        builder: ({required pressed}) => AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          transform: Matrix4.translationValues(
            pressed ? 3 : 0,
            pressed ? 3 : 0,
            0,
          ),
          decoration: BoxDecoration(
            color: enabled ? color : Palette.inkMuted,
            borderRadius: BorderRadius.circular(Radii.button),
            border: Border.all(color: Palette.ink, width: Stroke.width),
            boxShadow: enabled && !pressed
                ? [BoxShadow(color: shadow, offset: const Offset(6, 6))]
                : null,
          ),
          alignment: Alignment.center,
          child: busy
              ? const SizedBox.square(
                  dimension: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Palette.ink,
                  ),
                )
              : Text(
                  label,
                  style: TextStyles.display.copyWith(
                    fontSize: 18,
                    color: enabled ? Palette.ink : Palette.textMuted,
                  ),
                ),
        ),
      ),
    );
  }
}

/// Outline button on the dark ground for secondary choices.
class GhostButton extends StatelessWidget {
  const new({
    required this.label,
    required this.onPressed,
    super.key,
    this.height = 52,
  });

  final String label;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      child: _Pressable(
        onTap: onPressed,
        builder: ({required pressed}) => Container(
          height: height,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Radii.button),
            border: Border.all(
              color: pressed ? Palette.yellow : Palette.paper,
              width: 2,
            ),
          ),
          child: Text(
            label,
            style: TextStyles.ui.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Palette.paper,
            ),
          ),
        ),
      ),
    );
  }
}

/// Underlined text action.
class LinkButton extends StatelessWidget {
  const new({required this.label, required this.onPressed, super.key});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        foregroundColor: Palette.textMuted,
        minimumSize: const Size(44, 44),
      ),
      child: Text(
        label,
        style: const TextStyle(
          decoration: TextDecoration.underline,
          fontSize: 14,
        ),
      ),
    );
  }
}

/// Half of the bottom dock (QR'ım / Tara).
class DockButton extends StatelessWidget {
  const new({
    required this.label,
    required this.icon,
    required this.active,
    required this.onPressed,
    super.key,
    this.enabled = true,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onPressed;

  /// Looks unavailable but still takes taps, so the screen can say why.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final fg = active
        ? Palette.ink
        : enabled
        ? Palette.paper
        : Palette.inkMuted;
    return Semantics(
      button: true,
      selected: active,
      enabled: enabled,
      label: label,
      child: _Pressable(
        onTap: onPressed,
        builder: ({required pressed}) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: 60,
          decoration: BoxDecoration(
            color: active ? Palette.yellow : Palette.asphaltRaised,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active
                  ? Palette.ink
                  : enabled
                  ? Palette.inkMuted
                  : Palette.line,
              width: active ? Stroke.width : 2,
            ),
            boxShadow: active && !pressed
                ? const [BoxShadow(color: Palette.paper, offset: Offset(4, 4))]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 20, color: fg),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyles.ui.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: fg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pressable extends StatefulWidget {
  const new({required this.onTap, required this.builder});

  final VoidCallback? onTap;
  final Widget Function({required bool pressed}) builder;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return FocusableActionDetector(
      enabled: widget.onTap != null,
      mouseCursor: widget.onTap == null
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      actions: {
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (_) {
            widget.onTap?.call();
            return null;
          },
        ),
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: widget.builder(pressed: _pressed),
      ),
    );
  }
}
