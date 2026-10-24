import 'dart:math' as math;

import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Paper confetti falling over [child]. [intensity] 1..3 scales the number of
/// pieces and the length and, at 3, adds side cannons; 0 draws nothing.
/// Change [burstKey] to fire again. Nothing is drawn under reduced motion.
class ConfettiBurst extends StatefulWidget {
  const new({
    required this.child,
    required this.burstKey,
    super.key,
    this.intensity = 1,
  });

  final Widget child;
  final Object burstKey;
  final int intensity;

  @override
  State<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _Piece {
  new({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.spin,
    required this.color,
    required this.w,
    required this.h,
    required this.delay,
  });

  double x;
  double y;
  double vx;
  double vy;
  double angle = 0;
  final double spin;
  final Color color;
  final double w;
  final double h;
  final double delay;
}

class _ConfettiBurstState extends State<ConfettiBurst>
    with SingleTickerProviderStateMixin {
  static const List<Color> _colors = [
    Palette.blue,
    Palette.red,
    Palette.yellow,
    Palette.green,
    Palette.paper,
  ];

  late final Ticker _ticker = createTicker(_tick);
  final _rng = math.Random();
  List<_Piece> _pieces = const [];
  Duration _last = Duration.zero;
  double _elapsed = 0;
  Size _size = Size.zero;

  @override
  void didUpdateWidget(ConfettiBurst old) {
    super.didUpdateWidget(old);
    if (old.burstKey != widget.burstKey) _fire();
  }

  @override
  void initState() {
    super.initState();
    // Fire once on mount, after layout gave us a size.
    WidgetsBinding.instance.addPostFrameCallback((_) => _fire());
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _fire() {
    if (!mounted || _size.isEmpty) return;
    if (MediaQuery.disableAnimationsOf(context)) return;
    final level = widget.intensity.clamp(0, 3);
    if (level == 0) return;
    final count = const [0, 90, 180, 340][level];
    final w = _size.width;
    final h = _size.height;
    _pieces = [
      for (var i = 0; i < count; i++)
        if (level == 3 && i % 3 == 0)
          // Side cannons for the winner.
          _cannon(left: i.isEven, w: w, h: h)
        else
          _Piece(
            x: _rng.nextDouble() * w,
            y: -20 - _rng.nextDouble() * h * 0.4,
            vx: (_rng.nextDouble() - 0.5) * 120,
            vy: 120 + _rng.nextDouble() * 220,
            spin: (_rng.nextDouble() - 0.5) * 10,
            color: _colors[_rng.nextInt(_colors.length)],
            w: 10 + _rng.nextDouble() * 12,
            h: 6 + _rng.nextDouble() * 8,
            delay: _rng.nextDouble() * (0.6 * level),
          ),
    ];
    _elapsed = 0;
    _last = Duration.zero;
    if (!_ticker.isActive) _ticker.start();
  }

  _Piece _cannon({required bool left, required double w, required double h}) {
    final angle = (left ? -1 : 1) * (0.35 + _rng.nextDouble() * 0.5);
    final speed = 700 + _rng.nextDouble() * 500;
    return _Piece(
      x: left ? 0 : w,
      y: h * 0.9,
      vx: -math.sin(angle) * speed,
      vy: -math.cos(angle) * speed,
      spin: (_rng.nextDouble() - 0.5) * 14,
      color: _colors[_rng.nextInt(_colors.length)],
      w: 12 + _rng.nextDouble() * 12,
      h: 7 + _rng.nextDouble() * 8,
      delay: _rng.nextDouble() * 1.2,
    );
  }

  void _tick(Duration now) {
    final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.05);
    _last = now;
    _elapsed += dt;
    var alive = false;
    for (final p in _pieces) {
      if (_elapsed < p.delay) {
        alive = true;
        continue;
      }
      p
        ..vy += 520 * dt
        ..vx *= 0.995
        ..x += p.vx * dt + math.sin((_elapsed + p.delay) * 3) * 20 * dt
        ..y += p.vy * dt
        ..angle += p.spin * dt;
      if (p.y < _size.height + 40) alive = true;
    }
    if (!alive) {
      _ticker.stop();
      _pieces = const [];
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _size = constraints.biggest;
        return Stack(
          children: [
            Positioned.fill(child: widget.child),
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _ConfettiPainter(_pieces, _elapsed),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  new(this.pieces, this.elapsed);

  final List<_Piece> pieces;
  final double elapsed;

  @override
  void paint(Canvas canvas, Size size) {
    final fill = Paint();
    final edge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = Palette.ink;
    for (final p in pieces) {
      if (elapsed < p.delay) continue;
      canvas
        ..save()
        ..translate(p.x, p.y)
        ..rotate(p.angle);
      final rect = Rect.fromCenter(
        center: Offset.zero,
        width: p.w,
        height: p.h,
      );
      fill.color = p.color;
      canvas
        ..drawRect(rect, fill)
        ..drawRect(rect, edge)
        ..restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => true;
}
