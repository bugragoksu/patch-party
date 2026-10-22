import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:baglanti_agi/app/theme/tokens.dart';
import 'package:baglanti_agi/core/domain/avatar.dart';
import 'package:baglanti_agi/core/domain/catalog.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/projector/graph/force_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Live network (FR-20, ADR-0008): one CustomPainter for edges, nodes and
/// labels, driven by a Ticker over [ForceLayout]. The ticker stops when the
/// layout settles and restarts on data changes. The "new bridge" ring is a
/// tiny separate painter so its loop never repaints the whole graph.
class NetworkGraph extends StatefulWidget {
  const new({required this.players, required this.connections, super.key});

  /// Players to draw (disqualified ones already filtered out).
  final List<Player> players;
  final List<Connection> connections;

  @override
  State<NetworkGraph> createState() => _NetworkGraphState();
}

/// Cluster index (into [catalogClusters]) of a player's first interest.
int clusterIndexOf(Player p) {
  final id = Catalog.clusterOf(p.interests.isEmpty ? '' : p.interests.first).id;
  final i = catalogClusters.indexWhere((c) => c.id == id);
  return i < 0 ? 0 : i;
}

/// Turkish-aware upper case for labels ("i" -> "İ").
String trUpper(String s) =>
    s.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();

class _Frame extends ChangeNotifier {
  void tick() => notifyListeners();
}

class _NetworkGraphState extends State<NetworkGraph>
    with TickerProviderStateMixin {
  final _layout = ForceLayout(
    width: 1200,
    height: 900,
    seed: 20261025,
    marginY: 72,
  );
  final _frame = _Frame();
  final _cache = _GraphCache();
  late final Ticker _ticker = createTicker(_tick);
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _sync();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    _updateRing();
    _wake();
  }

  @override
  void didUpdateWidget(NetworkGraph old) {
    super.didUpdateWidget(old);
    if (!identical(old.players, widget.players) ||
        !identical(old.connections, widget.connections)) {
      _sync();
      _wake();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _ring.dispose();
    _frame.dispose();
    _cache.dispose();
    super.dispose();
  }

  void _sync() {
    final players = widget.players;
    final ids = <String>[];
    final clusters = <int>[];
    final initials = <String>[];
    for (final p in players) {
      ids.add(p.uid);
      clusters.add(clusterIndexOf(p));
      initials.add(initialOf(p.publicName));
    }
    final edges = <(String, String)>[];
    Connection? newest;
    for (final c in widget.connections) {
      if (c.participants.length < 2) continue;
      edges.add((c.participants[0], c.participants[1]));
      if (newest == null || c.createdAt > newest.createdAt) newest = c;
    }
    _layout.setGraph(nodeIds: ids, nodeClusters: clusters, edges: edges);
    var na = -1;
    var nb = -1;
    if (newest != null) {
      na = _layout.indexOf(newest.participants[0]);
      nb = _layout.indexOf(newest.participants[1]);
      if (na < 0 || nb < 0 || na == nb) na = nb = -1;
    }
    _cache.setData(initials: initials, newestA: na, newestB: nb);
    _updateRing();
  }

  void _updateRing() {
    final animate = _cache.newestA >= 0 && !_reduceMotion;
    if (animate && !_ring.isAnimating) {
      _ring.repeat();
    } else if (!animate && _ring.isAnimating) {
      _ring.stop();
    }
  }

  void _wake() {
    if (_reduceMotion) {
      // No motion: settle synchronously and paint the final state once.
      _ticker.stop();
      for (var i = 0; i < 400 && !_layout.settled; i++) {
        _layout.step();
      }
      _frame.tick();
      return;
    }
    if (!_ticker.isActive && !_layout.settled) _ticker.start();
  }

  void _tick(Duration _) {
    _layout.step();
    _frame.tick();
    if (_layout.settled) _ticker.stop();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        if (size.width != _layout.width || size.height != _layout.height) {
          _layout.resize(size.width, size.height);
          _wake();
        }
        return Stack(
          fit: StackFit.expand,
          children: [
            RepaintBoundary(
              child: CustomPaint(
                painter: _GraphPainter(_layout, _cache, _frame),
                isComplex: true,
                willChange: true,
              ),
            ),
            CustomPaint(
              painter: _RingPainter(
                _layout,
                _cache,
                _ring,
                Listenable.merge([_frame, _ring]),
                reduceMotion: _reduceMotion,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Everything the painter reuses between frames: paints, text layouts and
/// edge vertex buffers.
class _GraphCache {
  static const nodeRadius = 19.0;
  static const _clusterCount = 4;

  List<String> initials = const [];
  int newestA = -1;
  int newestB = -1;

  final Map<String, TextPainter> _initialText = {};
  late final List<TextPainter> clusterLabels = [
    for (final c in catalogClusters.take(_clusterCount))
      TextPainter(
        text: TextSpan(
          text: trUpper(c.label),
          style: TextStyles.title.copyWith(
            fontSize: 22,
            letterSpacing: 2.4,
            color: Color(c.color),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(),
  ];

  late final List<Color> clusterColors = [
    for (final c in catalogClusters.take(_clusterCount)) Color(c.color),
  ];

  /// One vertex buffer per bucket: 4 clusters + cross-cluster.
  final List<Float32List> buckets = List.filled(
    _clusterCount + 1,
    Float32List(0),
  );
  final List<int> bucketLen = List.filled(_clusterCount + 1, 0);

  late final List<Paint> bucketPaints = [
    for (final c in clusterColors)
      Paint()
        ..color = c.withValues(alpha: 0.4)
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round,
    Paint()
      ..color = Palette.paper.withValues(alpha: 0.55)
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round,
  ];
  late final List<Paint> nodeFills = [
    for (final c in clusterColors) Paint()..color = c,
  ];
  final Paint nodeStroke = Paint()
    ..color = Palette.ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = Stroke.width;
  final Paint hotStroke = Paint()
    ..color = Palette.paper
    ..style = PaintingStyle.stroke
    ..strokeWidth = Stroke.width;
  final Paint newestEdge = Paint()
    ..color = Palette.yellow
    ..strokeWidth = 7
    ..strokeCap = StrokeCap.round;
  final Paint newestEdgeOutline = Paint()
    ..color = Palette.ink
    ..strokeWidth = 11
    ..strokeCap = StrokeCap.round;
  final Paint ringPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5;

  void setData({
    required List<String> initials,
    required int newestA,
    required int newestB,
  }) {
    this.initials = initials;
    this.newestA = newestA;
    this.newestB = newestB;
  }

  void ensureBuckets(int edgeCount) {
    final need = edgeCount * 4;
    for (var b = 0; b < buckets.length; b++) {
      if (buckets[b].length < need) {
        buckets[b] = Float32List(math.max(need, 64) + 256);
      }
    }
  }

  TextPainter initialText(String initial, double fontSize) =>
      _initialText.putIfAbsent(
        initial,
        () => TextPainter(
          text: TextSpan(
            text: initial,
            style: TextStyles.display.copyWith(
              fontSize: fontSize,
              color: Palette.ink,
              height: 1,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout(),
      );

  void dispose() {
    for (final t in _initialText.values) {
      t.dispose();
    }
    for (final t in clusterLabels) {
      t.dispose();
    }
  }
}

class _GraphPainter extends CustomPainter {
  new(this.layout, this.cache, Listenable repaint) : super(repaint: repaint);

  final ForceLayout layout;
  final _GraphCache cache;

  @override
  void paint(Canvas canvas, Size size) {
    _paintLabels(canvas, size);

    final xs = layout.xs;
    final ys = layout.ys;
    final clusters = layout.clusters;
    final a = layout.edgeA;
    final b = layout.edgeB;
    final m = layout.edgeCount;
    final na = cache.newestA;
    final nb = cache.newestB;

    cache.ensureBuckets(m);
    final buckets = cache.buckets;
    final len = cache.bucketLen..fillRange(0, cache.bucketLen.length, 0);
    final cross = buckets.length - 1;
    for (var e = 0; e < m; e++) {
      final i = a[e];
      final j = b[e];
      if ((i == na && j == nb) || (i == nb && j == na)) continue;
      final ci = clusters[i];
      final k = ci == clusters[j] ? ci : cross;
      final buf = buckets[k];
      var p = len[k];
      buf[p++] = xs[i];
      buf[p++] = ys[i];
      buf[p++] = xs[j];
      buf[p++] = ys[j];
      len[k] = p;
    }
    for (var k = 0; k < buckets.length; k++) {
      if (len[k] == 0) continue;
      canvas.drawRawPoints(
        ui.PointMode.lines,
        Float32List.sublistView(buckets[k], 0, len[k]),
        cache.bucketPaints[k],
      );
    }

    if (na >= 0) {
      final pa = Offset(xs[na], ys[na]);
      final pb = Offset(xs[nb], ys[nb]);
      canvas
        ..drawLine(pa, pb, cache.newestEdgeOutline)
        ..drawLine(pa, pb, cache.newestEdge);
    }

    const r = _GraphCache.nodeRadius;
    final initials = cache.initials;
    for (var i = 0; i < layout.nodeCount; i++) {
      if (i == na || i == nb) continue;
      _paintNode(canvas, i, r, cache.nodeStroke, initials);
    }
    if (na >= 0) {
      _paintNode(canvas, na, r * 1.4, cache.hotStroke, initials);
      _paintNode(canvas, nb, r * 1.4, cache.hotStroke, initials);
    }
  }

  void _paintNode(
    Canvas canvas,
    int i,
    double r,
    Paint stroke,
    List<String> initials,
  ) {
    final c = Offset(layout.xs[i], layout.ys[i]);
    canvas
      ..drawCircle(c, r, cache.nodeFills[layout.clusters[i]])
      ..drawCircle(c, r, stroke);
    if (i < initials.length) {
      final t = cache.initialText(initials[i], 20);
      final scale = r / _GraphCache.nodeRadius;
      if (scale == 1) {
        t.paint(canvas, c - Offset(t.width / 2, t.height / 2));
      } else {
        canvas
          ..save()
          ..translate(c.dx, c.dy)
          ..scale(scale);
        t.paint(canvas, Offset(-t.width / 2, -t.height / 2));
        canvas.restore();
      }
    }
  }

  void _paintLabels(Canvas canvas, Size size) {
    const pad = 22.0;
    final labels = cache.clusterLabels;
    for (var k = 0; k < labels.length; k++) {
      final t = labels[k];
      final right = k.isOdd;
      final bottom = k >= 2;
      final dx = right ? size.width - pad - t.width : pad;
      final dy = bottom ? size.height - pad - t.height : pad;
      t.paint(canvas, Offset(dx, dy));
    }
  }

  @override
  bool shouldRepaint(_GraphPainter old) =>
      old.layout != layout || old.cache != cache;
}

class _RingPainter extends CustomPainter {
  new(
    this.layout,
    this.cache,
    this.ring,
    Listenable repaint, {
    required this.reduceMotion,
  }) : super(repaint: repaint);

  final ForceLayout layout;
  final _GraphCache cache;
  final Animation<double> ring;
  final bool reduceMotion;

  @override
  void paint(Canvas canvas, Size size) {
    final a = cache.newestA;
    final b = cache.newestB;
    if (a < 0 || a >= layout.nodeCount || b >= layout.nodeCount) return;
    final mid = Offset(
      (layout.xs[a] + layout.xs[b]) / 2,
      (layout.ys[a] + layout.ys[b]) / 2,
    );
    const base = 22.0;
    final t = reduceMotion ? 0.3 : Curves.easeOut.transform(ring.value);
    final radius = base * (0.8 + 1.4 * t);
    final opacity = reduceMotion ? 0.9 : 0.9 * (1 - t);
    cache.ringPaint.color = Palette.yellow.withValues(alpha: opacity);
    canvas.drawCircle(mid, radius, cache.ringPaint);
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.reduceMotion != reduceMotion;
}
