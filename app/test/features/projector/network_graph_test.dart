import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/projector/graph/network_graph.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _interests = [
  ['flutter', 'web'],
  ['ai', 'data'],
  ['design', 'product'],
  ['security', 'ai'],
];

List<Player> players(int n) => [
  for (var i = 0; i < n; i++)
    Player(
      uid: 'u$i',
      displayName: 'İsim $i',
      interests: _interests[i % 4],
      playerCode: 'C$i',
    ),
];

List<Connection> connections(int n, int m) => [
  for (var e = 0; e < m; e++)
    Connection(
      id: 'c$e',
      participants: ['u${e % n}', 'u${(e * 7 + 1) % n}'],
      names: const {},
      points: 10,
      bonus: 0,
      questionKey: 'q',
      questionSeed: 0,
      createdAt: e,
    ),
];

Widget host(List<Player> p, List<Connection> c, {bool reduce = false}) =>
    MediaQuery(
      data: MediaQueryData(
        size: const Size(1220, 880),
        disableAnimations: reduce,
      ),
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 1220,
            height: 880,
            child: NetworkGraph(players: p, connections: c),
          ),
        ),
      ),
    );

void main() {
  test('cluster index follows the first interest', () {
    expect(clusterIndexOf(players(4)[0]), 0);
    expect(clusterIndexOf(players(4)[1]), 1);
    expect(clusterIndexOf(players(4)[2]), 2);
    expect(clusterIndexOf(players(4)[3]), 3);
    expect(trUpper('Yapay Zekâ & Veri'), 'YAPAY ZEKÂ & VERİ');
  });

  testWidgets('paints 150 nodes / 1500 edges and updates', (tester) async {
    final p = players(150);
    await tester.pumpWidget(host(p, connections(150, 1500)));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    // New data: one more player and edge.
    final p2 = [...p, ...players(151).skip(150)];
    await tester.pumpWidget(host(p2, connections(151, 1501)));
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('reduced motion settles without a running ticker', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(players(40), connections(40, 80), reduce: true),
    );
    await tester.pump();
    expect(tester.hasRunningAnimations, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('empty graph paints', (tester) async {
    await tester.pumpWidget(host(const [], const []));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
