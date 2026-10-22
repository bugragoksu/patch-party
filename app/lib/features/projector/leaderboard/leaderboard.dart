import 'package:baglanti_agi/core/domain/models.dart';

/// Client-side ranking from the players stream (ADR-0011), same order as the
/// server's computeRanks (02-architecture §6.3): disqualified players out,
/// score descending, then whoever reached the score first.
List<Player> rankPlayers(Iterable<Player> players, {int? limit}) {
  final ranked = players.where((p) => !p.disqualified).toList()
    ..sort(compareForRank);
  if (limit != null && ranked.length > limit) {
    return ranked.sublist(0, limit);
  }
  return ranked;
}

int compareForRank(Player a, Player b) {
  final byScore = b.score.compareTo(a.score);
  if (byScore != 0) return byScore;
  final at = a.lastConnectionAt;
  final bt = b.lastConnectionAt;
  if (at != bt) {
    if (at == null) return 1;
    if (bt == null) return -1;
    return at.compareTo(bt);
  }
  final byJoin = a.joinedAt.compareTo(b.joinedAt);
  if (byJoin != 0) return byJoin;
  return a.uid.compareTo(b.uid);
}

/// Counters for the projector header.
class ProjectorCounts {
  const new({required this.players, required this.connections});

  factory of(List<Player> players, List<Connection> connections) =>
      ProjectorCounts(
        players: players.where((p) => !p.disqualified).length,
        connections: connections.length,
      );

  final int players;
  final int connections;
}

/// The most recent connection (max createdAt), or null.
Connection? newestConnection(List<Connection> connections) {
  Connection? best;
  for (final c in connections) {
    if (best == null || c.createdAt > best.createdAt) best = c;
  }
  return best;
}

/// Most recently joined players first.
List<Player> latestJoiners(List<Player> players, int count) {
  final list = players.where((p) => !p.disqualified).toList()
    ..sort((a, b) => b.joinedAt.compareTo(a.joinedAt));
  return list.length > count ? list.sublist(0, count) : list;
}
