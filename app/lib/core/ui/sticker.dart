import 'dart:math' as math;

import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:flutter/material.dart';

/// The base of the visual language (04-design.md §1.3): fill, 3 px outline,
/// hard offset shadow, optional tilt.
class Sticker extends StatelessWidget {
  const new({
    required this.child,
    super.key,
    this.color = Palette.paper,
    this.outline = Palette.ink,
    this.shadow,
    this.shadowOffset = 6,
    this.radius = Radii.card,
    this.tiltDegrees = 0,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final Color color;
  final Color outline;
  final Color? shadow;
  final double shadowOffset;
  final double radius;
  final double tiltDegrees;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final box = DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: outline, width: Stroke.width),
        boxShadow: shadow == null
            ? null
            : [
                BoxShadow(
                  color: shadow!,
                  offset: Offset(shadowOffset, shadowOffset),
                ),
              ],
      ),
      child: Padding(padding: padding, child: child),
    );
    if (tiltDegrees == 0) return box;
    return Transform.rotate(angle: tiltDegrees * math.pi / 180, child: box);
  }
}

/// Plays the "stamp" entrance once; respects reduced motion.
class StampIn extends StatelessWidget {
  const new({required this.child, super.key, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Motion.stamp + delay,
      curve: Interval(
        delay.inMilliseconds / (Motion.stamp + delay).inMilliseconds,
        1,
        curve: Motion.stampCurve,
      ),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.scale(scale: 1.25 - 0.25 * t, child: child),
      ),
    );
  }
}

/// Short rise-and-fade used for score stickers.
class PopIn extends StatelessWidget {
  const new({required this.child, super.key, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    final delay = Motion.popStagger * index;
    final total = Motion.pop + delay;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: total,
      curve: Interval(
        delay.inMilliseconds / total.inMilliseconds,
        1,
        curve: Curves.easeOut,
      ),
      child: child,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 12 * (1 - t)),
          child: child,
        ),
      ),
    );
  }
}
