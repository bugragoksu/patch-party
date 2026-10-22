import 'package:baglanti_agi/core/domain/catalog.g.dart';

export 'package:baglanti_agi/core/domain/catalog.g.dart';

class InterestCluster {
  const new({required this.id, required this.label, required this.color});

  final String id;
  final String label;

  /// ARGB value; the UI layer turns it into a Color.
  final int color;
}

class Interest {
  const new({required this.id, required this.label, required this.clusterId});

  final String id;
  final String label;
  final String clusterId;
}

abstract final class Catalog {
  static final Map<String, Interest> _byId = {
    for (final i in catalogInterests) i.id: i,
  };
  static final Map<String, InterestCluster> _clusters = {
    for (final c in catalogClusters) c.id: c,
  };

  static Interest? interest(String id) => _byId[id];

  static InterestCluster clusterOf(String interestId) {
    final interest = _byId[interestId];
    return _clusters[interest?.clusterId] ?? catalogClusters.first;
  }

  static bool isValidPick(List<String> ids) =>
      ids.length >= catalogMinPick &&
      ids.length <= catalogMaxPick &&
      ids.toSet().length == ids.length &&
      ids.every(_byId.containsKey);

  static String labelOf(String id) => _byId[id]?.label ?? id;
}
