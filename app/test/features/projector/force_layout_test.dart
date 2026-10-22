import 'dart:math' as math;

import 'package:baglanti_agi/features/projector/graph/force_layout.dart';
import 'package:flutter_test/flutter_test.dart';

/// Random graph: [n] nodes over 4 clusters, [m] distinct edges.
({List<String> ids, List<int> clusters, List<(String, String)> edges})
randomGraph(int n, int m, {int seed = 7}) {
  final rng = math.Random(seed);
  final ids = [for (var i = 0; i < n; i++) 'p$i'];
  final clusters = [for (var i = 0; i < n; i++) i % 4];
  final seen = <String>{};
  final edges = <(String, String)>[];
  while (edges.length < m) {
    final a = rng.nextInt(n);
    final b = rng.nextInt(n);
    if (a == b) continue;
    final key = a < b ? '$a-$b' : '$b-$a';
    if (!seen.add(key)) continue;
    edges.add((ids[a], ids[b]));
  }
  return (ids: ids, clusters: clusters, edges: edges);
}

void runUntilSettled(ForceLayout layout, {int max = 1000}) {
  for (var i = 0; i < max && !layout.settled; i++) {
    layout.step();
  }
}

double dist(ForceLayout l, int i, int j) {
  final dx = l.xs[i] - l.xs[j];
  final dy = l.ys[i] - l.ys[j];
  return math.sqrt(dx * dx + dy * dy);
}

void main() {
  test('positions stay within bounds', () {
    final g = randomGraph(150, 600);
    final layout = ForceLayout(width: 1200, height: 900, seed: 3)
      ..setGraph(nodeIds: g.ids, nodeClusters: g.clusters, edges: g.edges);
    for (var step = 0; step < 400; step++) {
      layout.step();
      for (var i = 0; i < layout.nodeCount; i++) {
        expect(layout.xs[i], inInclusiveRange(layout.margin, 1200 - 28));
        expect(layout.ys[i], inInclusiveRange(layout.margin, 900 - 28));
        expect(layout.xs[i].isFinite && layout.ys[i].isFinite, isTrue);
      }
    }
  });

  test('connected nodes end up closer than unconnected ones', () {
    // 40 nodes in one cluster, connected in pairs (0-1, 2-3, ...).
    final ids = [for (var i = 0; i < 40; i++) 'p$i'];
    final edges = [for (var i = 0; i < 40; i += 2) (ids[i], ids[i + 1])];
    final layout = ForceLayout(width: 1200, height: 900, seed: 11)
      ..setGraph(nodeIds: ids, nodeClusters: List.filled(40, 0), edges: edges);
    runUntilSettled(layout);

    var connected = 0.0;
    for (var i = 0; i < 40; i += 2) {
      connected += dist(layout, i, i + 1);
    }
    connected /= 20;

    var unconnected = 0.0;
    var count = 0;
    for (var i = 0; i < 40; i++) {
      for (var j = i + 1; j < 40; j++) {
        if (i.isEven && j == i + 1) continue;
        unconnected += dist(layout, i, j);
        count++;
      }
    }
    unconnected /= count;

    expect(connected, lessThan(unconnected * 0.6));
  });

  test('nodes gather around their cluster anchor', () {
    final g = randomGraph(80, 0);
    final layout = ForceLayout(width: 1200, height: 900, seed: 5)
      ..setGraph(nodeIds: g.ids, nodeClusters: g.clusters, edges: g.edges);
    runUntilSettled(layout);
    for (var i = 0; i < layout.nodeCount; i++) {
      final own = layout.anchorOf(layout.clusters[i]);
      final dOwn = math.sqrt(
        math.pow(layout.xs[i] - own.$1, 2) + math.pow(layout.ys[i] - own.$2, 2),
      );
      for (var c = 0; c < 4; c++) {
        if (c == layout.clusters[i]) continue;
        final other = layout.anchorOf(c);
        final dOther = math.sqrt(
          math.pow(layout.xs[i] - other.$1, 2) +
              math.pow(layout.ys[i] - other.$2, 2),
        );
        expect(dOwn, lessThan(dOther), reason: 'node $i');
      }
    }
  });

  test('is deterministic for a seed', () {
    final g = randomGraph(60, 120);
    ForceLayout run() {
      final l = ForceLayout(width: 1000, height: 800, seed: 42)
        ..setGraph(nodeIds: g.ids, nodeClusters: g.clusters, edges: g.edges);
      for (var i = 0; i < 200; i++) {
        l.step();
      }
      return l;
    }

    final a = run();
    final b = run();
    expect(a.xs, b.xs);
    expect(a.ys, b.ys);
  });

  test('keeps positions of existing nodes and starts new ones near '
      'their anchor', () {
    final layout = ForceLayout(width: 1200, height: 900)
      ..setGraph(
        nodeIds: const ['a', 'b'],
        nodeClusters: const [0, 1],
        edges: const [('a', 'b')],
      );
    runUntilSettled(layout);
    final ax = layout.xs[0];
    final ay = layout.ys[0];

    layout.setGraph(
      nodeIds: const ['a', 'b', 'c'],
      nodeClusters: const [0, 1, 3],
      edges: const [('a', 'b'), ('b', 'c'), ('c', 'zz'), ('c', 'c')],
    );
    expect(layout.xs[0], ax);
    expect(layout.ys[0], ay);
    expect(layout.edgeCount, 2, reason: 'unknown and self edges skipped');
    expect(layout.settled, isFalse, reason: 'data change reheats');

    final anchor = layout.anchorOf(3);
    final dx = layout.xs[2] - anchor.$1;
    final dy = layout.ys[2] - anchor.$2;
    expect(math.sqrt(dx * dx + dy * dy), lessThanOrEqualTo(50));
  });

  test('settles and handles 150 nodes / 1500 edges quickly', () {
    final g = randomGraph(150, 1500);
    final layout = ForceLayout(width: 1220, height: 900)
      ..setGraph(nodeIds: g.ids, nodeClusters: g.clusters, edges: g.edges);
    final sw = Stopwatch()..start();
    var steps = 0;
    while (!layout.settled && steps < 2000) {
      layout.step();
      steps++;
    }
    sw.stop();
    expect(layout.settled, isTrue);
    // Generous bound for the debug VM; a frame budget is 33 ms at 30 fps.
    final perStepMs = sw.elapsedMicroseconds / steps / 1000;
    expect(perStepMs, lessThan(4), reason: '$steps steps, $perStepMs ms each');
  });

  test('resize scales positions into the new bounds', () {
    final g = randomGraph(30, 30);
    final layout = ForceLayout(width: 1200, height: 900)
      ..setGraph(nodeIds: g.ids, nodeClusters: g.clusters, edges: g.edges);
    runUntilSettled(layout);
    layout.resize(600, 450);
    for (var i = 0; i < layout.nodeCount; i++) {
      expect(layout.xs[i], inInclusiveRange(28, 600 - 28));
      expect(layout.ys[i], inInclusiveRange(28, 450 - 28));
    }
  });
}
