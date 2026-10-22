import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/projector/leaderboard/leaderboard.dart';
import 'package:flutter_test/flutter_test.dart';

Player player(
  String uid, {
  int score = 0,
  int? last,
  bool dq = false,
  int joinedAt = 0,
}) => Player(
  uid: uid,
  displayName: uid,
  interests: const ['flutter', 'ai'],
  playerCode: 'ABC',
  score: score,
  lastConnectionAt: last,
  disqualified: dq,
  joinedAt: joinedAt,
);

Connection conn(String id, int createdAt) => Connection(
  id: id,
  participants: const ['a', 'b'],
  names: const {},
  points: 10,
  bonus: 5,
  questionKey: '',
  questionSeed: 0,
  createdAt: createdAt,
);

void main() {
  test('orders by score descending', () {
    final ranked = rankPlayers([
      player('a', score: 10, last: 1),
      player('b', score: 30, last: 1),
      player('c', score: 20, last: 1),
    ]);
    expect(ranked.map((p) => p.uid), ['b', 'c', 'a']);
  });

  test('ties go to whoever reached the score first', () {
    final ranked = rankPlayers([
      player('late', score: 20, last: 500),
      player('early', score: 20, last: 100),
      player('never'),
      player('zero', last: 50),
    ]);
    expect(ranked.map((p) => p.uid), ['early', 'late', 'zero', 'never']);
  });

  test('excludes disqualified players and applies the limit', () {
    final ranked = rankPlayers([
      player('cheat', score: 999, last: 1, dq: true),
      for (var i = 0; i < 15; i++) player('p$i', score: i, last: i),
    ], limit: 10);
    expect(ranked, hasLength(10));
    expect(ranked.first.uid, 'p14');
    expect(ranked.any((p) => p.uid == 'cheat'), isFalse);
  });

  test('counters skip disqualified players', () {
    final counts = ProjectorCounts.of(
      [player('a'), player('b', dq: true)],
      [conn('x', 1), conn('y', 2)],
    );
    expect(counts.players, 1);
    expect(counts.connections, 2);
  });

  test('newest connection and latest joiners', () {
    expect(
      newestConnection([conn('x', 5), conn('y', 9), conn('z', 3)])?.id,
      'y',
    );
    expect(newestConnection(const []), isNull);
    final joiners = latestJoiners([
      player('a', joinedAt: 1),
      player('b', joinedAt: 3),
      player('c', joinedAt: 2, dq: true),
    ], 5);
    expect(joiners.map((p) => p.uid), ['b', 'a']);
  });
}
