import 'dart:math' as math;
import 'dart:typed_data';

/// Pure force simulation for the projector network (ADR-0008). No Flutter
/// imports so it can be unit-tested and stepped by any clock.
///
/// Nodes repel each other (O(n²), fine for ~150), edges act as springs, each
/// node is weakly pulled toward its cluster anchor, velocities are damped and
/// positions stay inside the bounds. A cooling factor ([alpha]) makes the
/// simulation settle; [setGraph] reheats it when the data changes.
class ForceLayout {
  new({
    required this._width,
    required this._height,
    int seed = 1,
    this.clusterCount = 4,
    this.margin = 28,
    double? marginY,
    this.nodeRadius = 20,
  }) : marginY = marginY ?? margin,
       _rng = math.Random(seed);

  final int clusterCount;

  /// Distance kept between node centers and the left/right bounds.
  final double margin;

  /// Distance kept from the top/bottom bounds (room for labels).
  final double marginY;

  /// Drawn node radius; nodes closer than two radii are pushed apart.
  final double nodeRadius;

  final math.Random _rng;
  double _width;
  double _height;

  static const _damping = 0.82;
  static const _maxSpeed = 24.0;
  static const _alphaDecay = 0.985;
  static const _alphaMin = 0.015;
  static const _energyMin = 0.004;

  final List<String> _ids = [];
  final Map<String, int> _index = {};
  Float64List _x = Float64List(0);
  Float64List _y = Float64List(0);
  Float64List _vx = Float64List(0);
  Float64List _vy = Float64List(0);
  Float64List _fx = Float64List(0);
  Float64List _fy = Float64List(0);
  Int32List _cluster = Int32List(0);
  Int32List _edgeA = Int32List(0);
  Int32List _edgeB = Int32List(0);
  Float64List _edgeK = Float64List(0);
  int _edgeCount = 0;

  double _alpha = 1;
  double _energy = double.infinity;

  double get width => _width;
  double get height => _height;
  int get nodeCount => _ids.length;
  int get edgeCount => _edgeCount;
  double get alpha => _alpha;

  /// Mean squared speed after the last [step].
  double get energy => _energy;

  /// True once the layout has cooled down; stop ticking until [setGraph].
  bool get settled =>
      _ids.isEmpty || _alpha <= _alphaMin || _energy < _energyMin;

  /// Node positions, indexed like the `nodeIds` passed to [setGraph].
  Float64List get xs => _x;
  Float64List get ys => _y;
  Int32List get clusters => _cluster;

  /// Endpoints of edge `i` are `edgeA[i]` and `edgeB[i]` (`i < edgeCount`).
  Int32List get edgeA => _edgeA;
  Int32List get edgeB => _edgeB;

  int indexOf(String id) => _index[id] ?? -1;

  /// Rest length of an edge and the typical node spacing, from the area.
  double get _spacing {
    final n = math.max(_ids.length, 24);
    return math.sqrt(_width * _height / n) * 0.62;
  }

  /// Anchor of cluster [c]: one per quadrant, row by row.
  (double, double) anchorOf(int c) {
    final col = c % 2;
    final row = (c ~/ 2) % 2;
    return (
      _width * (col == 0 ? 0.27 : 0.73),
      _height * (row == 0 ? 0.32 : 0.70),
    );
  }

  /// Replaces the graph. Existing nodes keep their position and velocity;
  /// new nodes start near their cluster anchor. Edges with unknown or equal
  /// endpoints are skipped.
  void setGraph({
    required List<String> nodeIds,
    required List<int> nodeClusters,
    required List<(String, String)> edges,
  }) {
    assert(nodeIds.length == nodeClusters.length, 'one cluster per node');
    final n = nodeIds.length;
    final x = Float64List(n);
    final y = Float64List(n);
    final vx = Float64List(n);
    final vy = Float64List(n);
    final cluster = Int32List(n);
    var added = 0;
    for (var i = 0; i < n; i++) {
      final c = nodeClusters[i].clamp(0, clusterCount - 1);
      cluster[i] = c;
      final old = _index[nodeIds[i]];
      if (old != null) {
        x[i] = _x[old];
        y[i] = _y[old];
        vx[i] = _vx[old];
        vy[i] = _vy[old];
      } else {
        final (ax, ay) = anchorOf(c);
        final angle = _rng.nextDouble() * math.pi * 2;
        final r = 8 + _rng.nextDouble() * 40;
        x[i] = _clampX(ax + math.cos(angle) * r);
        y[i] = _clampY(ay + math.sin(angle) * r);
        added++;
      }
    }
    _ids
      ..clear()
      ..addAll(nodeIds);
    _index
      ..clear()
      ..addAll({for (var i = 0; i < n; i++) nodeIds[i]: i});
    _x = x;
    _y = y;
    _vx = vx;
    _vy = vy;
    _fx = Float64List(n);
    _fy = Float64List(n);
    _cluster = cluster;

    final a = Int32List(edges.length);
    final b = Int32List(edges.length);
    var m = 0;
    for (final (from, to) in edges) {
      final i = _index[from];
      final j = _index[to];
      if (i == null || j == null || i == j) continue;
      a[m] = i;
      b[m] = j;
      m++;
    }
    final edgesChanged = m != _edgeCount;
    _edgeA = a;
    _edgeB = b;
    _edgeCount = m;

    // Spring strength per edge = 1 / smaller endpoint degree, so hubs and
    // dense graphs do not collapse into a ball (as in d3-force).
    final degree = Int32List(n);
    for (var e = 0; e < m; e++) {
      degree[a[e]]++;
      degree[b[e]]++;
    }
    final k = Float64List(m);
    for (var e = 0; e < m; e++) {
      k[e] = 1 / math.max(1, math.min(degree[a[e]], degree[b[e]]));
    }
    _edgeK = k;

    if (added > 0 || edgesChanged) {
      _alpha = math.max(_alpha, added > 0 ? 0.8 : 0.5);
      _energy = double.infinity;
    }
  }

  /// Scales positions to new bounds (e.g. the panel was resized).
  void resize(double width, double height) {
    if (width == _width && height == _height) return;
    final sx = width / _width;
    final sy = height / _height;
    _width = width;
    _height = height;
    for (var i = 0; i < _ids.length; i++) {
      _x[i] = _clampX(_x[i] * sx);
      _y[i] = _clampY(_y[i] * sy);
    }
  }

  /// Advances one tick and returns the mean squared speed.
  double step() {
    final n = _ids.length;
    if (n == 0) {
      _energy = 0;
      return 0;
    }
    final spacing = _spacing;
    final repulsion = spacing * spacing * 1.2;
    const springK = 0.06;
    final rest = spacing * 0.9;
    const anchorK = 0.012;
    final minDist2 = (spacing * 0.15) * (spacing * 0.15);
    final collide = nodeRadius * 2 + 6;

    final x = _x;
    final y = _y;
    final fx = _fx..fillRange(0, n, 0);
    final fy = _fy..fillRange(0, n, 0);

    for (var i = 0; i < n; i++) {
      final xi = x[i];
      final yi = y[i];
      for (var j = i + 1; j < n; j++) {
        var dx = xi - x[j];
        var dy = yi - y[j];
        var d2 = dx * dx + dy * dy;
        if (d2 < 1e-6) {
          // Deterministic nudge for coincident nodes.
          dx = (i - j).toDouble() * 0.01;
          dy = 0.01;
          d2 = dx * dx + dy * dy;
        }
        if (d2 < minDist2) d2 = minDist2;
        final d = math.sqrt(d2);
        var f = repulsion / d2;
        if (d < collide) f += (collide - d) * 0.5;
        final ux = dx / d * f;
        final uy = dy / d * f;
        fx[i] += ux;
        fy[i] += uy;
        fx[j] -= ux;
        fy[j] -= uy;
      }
    }

    for (var e = 0; e < _edgeCount; e++) {
      final i = _edgeA[e];
      final j = _edgeB[e];
      final dx = x[j] - x[i];
      final dy = y[j] - y[i];
      final d = math.max(math.sqrt(dx * dx + dy * dy), 0.01);
      final f = springK * _edgeK[e] * (d - rest);
      final ux = dx / d * f;
      final uy = dy / d * f;
      fx[i] += ux;
      fy[i] += uy;
      fx[j] -= ux;
      fy[j] -= uy;
    }

    var sum = 0.0;
    for (var i = 0; i < n; i++) {
      final (ax, ay) = anchorOf(_cluster[i]);
      fx[i] += (ax - x[i]) * anchorK;
      fy[i] += (ay - y[i]) * anchorK;

      var vx = (_vx[i] + fx[i] * _alpha) * _damping;
      var vy = (_vy[i] + fy[i] * _alpha) * _damping;
      final speed2 = vx * vx + vy * vy;
      if (speed2 > _maxSpeed * _maxSpeed) {
        final k = _maxSpeed / math.sqrt(speed2);
        vx *= k;
        vy *= k;
      }
      var nx = x[i] + vx;
      var ny = y[i] + vy;
      final cx = _clampX(nx);
      final cy = _clampY(ny);
      if (cx != nx) {
        nx = cx;
        vx = 0;
      }
      if (cy != ny) {
        ny = cy;
        vy = 0;
      }
      x[i] = nx;
      y[i] = ny;
      _vx[i] = vx;
      _vy[i] = vy;
      sum += vx * vx + vy * vy;
    }

    _alpha = math.max(_alpha * _alphaDecay, _alphaMin);
    return _energy = sum / n;
  }

  double _clampX(double v) =>
      v.clamp(margin, math.max(margin, _width - margin)).toDouble();
  double _clampY(double v) =>
      v.clamp(marginY, math.max(marginY, _height - marginY)).toDouble();
}
