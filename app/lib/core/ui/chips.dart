import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/catalog.dart';
import 'package:flutter/material.dart';

/// Interest chip: selected chips take their cluster color, outline and shadow,
/// so selection never relies on color alone (04-design.md §6).
class InterestChip extends StatelessWidget {
  const new({
    required this.interestId,
    super.key,
    this.selected = true,
    this.onTap,
    this.compact = false,
  });

  final String interestId;
  final bool selected;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final color = Color(Catalog.clusterOf(interestId).color);
    final label = Catalog.labelOf(interestId);
    final chip = AnimatedContainer(
      duration: const Duration(milliseconds: 140),
      height: compact ? 30 : 40,
      padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 14),
      decoration: BoxDecoration(
        color: selected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected ? Palette.ink : const Color(0xFF6E6A63),
          width: selected ? (compact ? 2 : Stroke.width) : 2,
        ),
        boxShadow: selected && !compact
            ? const [BoxShadow(color: Palette.paper, offset: Offset(3, 3))]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyles.ui.copyWith(
          fontWeight: FontWeight.w700,
          fontSize: compact ? 12 : 14,
          color: selected ? Palette.ink : Palette.paper,
        ),
      ),
    );
    if (onTap == null) return chip;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: chip,
      ),
    );
  }
}

/// Dashed-outline note on the dark ground: suggestions and warnings.
class NoticeBox extends StatelessWidget {
  const new({required this.child, super.key, this.color = Palette.yellow});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorder(color),
      child: Padding(padding: const EdgeInsets.all(12), child: child),
    );
  }
}

class _DashedBorder extends CustomPainter {
  new(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(14),
    );
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(metric.extractPath(d, d + 7), paint);
        d += 12;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorder old) => old.color != color;
}
