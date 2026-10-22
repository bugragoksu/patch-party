import 'dart:math' as math;

import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/avatar.dart';
import 'package:flutter/material.dart';

/// Generated avatar (FR-16): cluster-colored disc with the initial and a
/// small corner badge in the second interest's color.
class AvatarBadge extends StatelessWidget {
  const new({
    required this.spec,
    super.key,
    this.size = 56,
    this.outline = Palette.ink,
  });

  final AvatarSpec spec;
  final double size;
  final Color outline;

  @override
  Widget build(BuildContext context) {
    final badge = size * 0.36;
    final border = math.max(2, size / 20).toDouble();
    return ExcludeSemantics(
      child: SizedBox.square(
        dimension: size + badge * 0.25,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: Color(spec.primary),
                shape: BoxShape.circle,
                border: Border.all(color: outline, width: border),
              ),
              alignment: Alignment.center,
              child: Text(
                spec.initial,
                style: TextStyles.display.copyWith(
                  fontSize: size * 0.42,
                  color: Palette.ink,
                  height: 1,
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              child: RotationTransition(
                turns: AlwaysStoppedAnimation(spec.badgeTurns),
                child: CustomPaint(
                  size: Size.square(badge),
                  painter: _BadgePainter(
                    spec.badgeShape,
                    Color(spec.secondary),
                    outline,
                    border,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgePainter extends CustomPainter {
  new(this.shape, this.fill, this.stroke, this.width);

  final BadgeShape shape;
  final Color fill;
  final Color stroke;
  final double width;

  @override
  void paint(Canvas canvas, Size size) {
    final r = Offset.zero & size;
    final inset = r.deflate(width / 2);
    final path = switch (shape) {
      BadgeShape.square =>
        Path()..addRRect(
          RRect.fromRectAndRadius(inset, Radius.circular(size.width * 0.22)),
        ),
      BadgeShape.circle => Path()..addOval(inset),
      BadgeShape.triangle =>
        Path()
          ..moveTo(inset.center.dx, inset.top)
          ..lineTo(inset.right, inset.bottom)
          ..lineTo(inset.left, inset.bottom)
          ..close(),
      BadgeShape.diamond =>
        Path()
          ..moveTo(inset.center.dx, inset.top)
          ..lineTo(inset.right, inset.center.dy)
          ..lineTo(inset.center.dx, inset.bottom)
          ..lineTo(inset.left, inset.center.dy)
          ..close(),
    };
    canvas
      ..drawPath(path, Paint()..color = fill)
      ..drawPath(
        path,
        Paint()
          ..color = stroke
          ..style = PaintingStyle.stroke
          ..strokeWidth = width
          ..strokeJoin = StrokeJoin.round,
      );
  }

  @override
  bool shouldRepaint(_BadgePainter old) =>
      old.shape != shape ||
      old.fill != fill ||
      old.stroke != stroke ||
      old.width != width;
}
