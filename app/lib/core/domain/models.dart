// Firestore documents as immutable domain models. Hand-written (ADR-0005);
// field names match functions/src/data/model.ts. Timestamps are epoch ms.

enum EventState {
  draft,
  lobby,
  live,
  ended,
  archived;

  static EventState parse(Object? raw) =>
      EventState.values.firstWhere((s) => s.name == raw, orElse: () => draft);
}

class EventSettings {
  const new({
    this.displayName = 'Bağlantı Ağı',
    this.subtitle = '',
    this.prizes = const [],
    this.tokenWindowSec = 30,
    this.joinWindowSec = 300,
    this.requestTtlSec = 45,
    this.cooldownSec = 15,
    this.maxConnPerPlayer = 60,
    this.maxPlayers = 200,
    this.appCheckEnforce = false,
    this.badges = true,
    this.playerRank = true,
  });

  factory fromJson(Map<String, Object?> j) {
    final features = (j['features'] as Map?)?.cast<String, Object?>() ?? {};
    return EventSettings(
      displayName: j['displayName'] as String? ?? 'Bağlantı Ağı',
      subtitle: j['subtitle'] as String? ?? '',
      prizes: (j['prizes'] as List?)?.cast<String>() ?? const [],
      tokenWindowSec: _int(j['tokenWindowSec'], 30),
      joinWindowSec: _int(j['joinWindowSec'], 300),
      requestTtlSec: _int(j['requestTtlSec'], 45),
      cooldownSec: _int(j['cooldownSec'], 15),
      maxConnPerPlayer: _int(j['maxConnPerPlayer'], 60),
      maxPlayers: _int(j['maxPlayers'], 200),
      appCheckEnforce: j['appCheckEnforce'] as bool? ?? false,
      badges: features['badges'] as bool? ?? true,
      playerRank: features['playerRank'] as bool? ?? true,
    );
  }

  final String displayName;
  final String subtitle;
  final List<String> prizes;
  final int tokenWindowSec;
  final int joinWindowSec;
  final int requestTtlSec;
  final int cooldownSec;
  final int maxConnPerPlayer;
  final int maxPlayers;
  final bool appCheckEnforce;
  final bool badges;
  final bool playerRank;
}

class EventInfo {
  const new({
    required this.id,
    required this.name,
    required this.state,
    required this.settings,
    this.liveStartAt,
    this.liveEndAt,
    this.summary,
  });

  factory fromJson(String id, Map<String, Object?> j) => EventInfo(
    id: id,
    name: j['name'] as String? ?? '',
    state: EventState.parse(j['state']),
    liveStartAt: _intOrNull(j['liveStartAt']),
    liveEndAt: _intOrNull(j['liveEndAt']),
    settings: EventSettings.fromJson(
      (j['settings'] as Map?)?.cast<String, Object?>() ?? {},
    ),
    summary: (j['summary'] as Map?)?.cast<String, Object?>(),
  );

  final String id;
  final String name;
  final EventState state;
  final int? liveStartAt;
  final int? liveEndAt;
  final EventSettings settings;
  final Map<String, Object?>? summary;

  bool isLiveAt(int nowMs) =>
      state == EventState.live &&
      (liveStartAt == null || nowMs >= liveStartAt!) &&
      (liveEndAt == null || nowMs < liveEndAt!);

  bool get canJoin => state == EventState.lobby || state == EventState.live;
}

class OutgoingRequest {
  const new({
    required this.requestId,
    required this.toUid,
    required this.expiresAt,
  });

  final String requestId;
  final String toUid;
  final int expiresAt;
}

class Player {
  const new({
    required this.uid,
    required this.displayName,
    required this.interests,
    required this.playerCode,
    this.nameHidden = false,
    this.score = 0,
    this.connectionCount = 0,
    this.bridgeCount = 0,
    this.badges = const [],
    this.rank,
    this.rankTotal,
    this.rankedAt,
    this.lastConnectionAt,
    this.outgoingRequest,
    this.disqualified = false,
    this.joinedAt = 0,
  });

  factory fromJson(String uid, Map<String, Object?> j) {
    final out = (j['outgoingRequest'] as Map?)?.cast<String, Object?>();
    return Player(
      uid: uid,
      displayName: j['displayName'] as String? ?? '',
      nameHidden: j['nameHidden'] as bool? ?? false,
      interests: (j['interests'] as List?)?.cast<String>() ?? const [],
      playerCode: j['playerCode'] as String? ?? '',
      score: _int(j['score'], 0),
      connectionCount: _int(j['connectionCount'], 0),
      bridgeCount: _int(j['bridgeCount'], 0),
      badges: (j['badges'] as List?)?.cast<String>() ?? const [],
      rank: _intOrNull(j['rank']),
      rankTotal: _intOrNull(j['rankTotal']),
      rankedAt: _intOrNull(j['rankedAt']),
      lastConnectionAt: _intOrNull(j['lastConnectionAt']),
      outgoingRequest: out == null
          ? null
          : OutgoingRequest(
              requestId: out['requestId'] as String? ?? '',
              toUid: out['toUid'] as String? ?? '',
              expiresAt: _int(out['expiresAt'], 0),
            ),
      disqualified: j['disqualified'] as bool? ?? false,
      joinedAt: _int(j['joinedAt'], 0),
    );
  }

  final String uid;
  final String displayName;
  final bool nameHidden;
  final List<String> interests;
  final String playerCode;
  final int score;
  final int connectionCount;
  final int bridgeCount;
  final List<String> badges;
  final int? rank;
  final int? rankTotal;
  final int? rankedAt;
  final int? lastConnectionAt;
  final OutgoingRequest? outgoingRequest;
  final bool disqualified;
  final int joinedAt;

  /// What the projector shows; hidden names fall back to a neutral label.
  String get publicName => nameHidden ? 'Oyuncu' : displayName;
}

enum RequestStatus {
  pending,
  accepted,
  declined,
  expired,
  cancelled;

  static RequestStatus parse(Object? raw) => RequestStatus.values.firstWhere(
    (s) => s.name == raw,
    orElse: () => expired,
  );
}

class ConnectionRequest {
  const new({
    required this.id,
    required this.fromUid,
    required this.toUid,
    required this.fromName,
    required this.fromInterests,
    required this.toName,
    required this.toInterests,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
  });

  factory fromJson(String id, Map<String, Object?> j) => ConnectionRequest(
    id: id,
    fromUid: j['fromUid'] as String? ?? '',
    toUid: j['toUid'] as String? ?? '',
    fromName: j['fromName'] as String? ?? '',
    fromInterests: (j['fromInterests'] as List?)?.cast<String>() ?? const [],
    toName: j['toName'] as String? ?? '',
    toInterests: (j['toInterests'] as List?)?.cast<String>() ?? const [],
    status: RequestStatus.parse(j['status']),
    createdAt: _int(j['createdAt'], 0),
    expiresAt: _int(j['expiresAt'], 0),
  );

  final String id;
  final String fromUid;
  final String toUid;
  final String fromName;
  final List<String> fromInterests;
  final String toName;
  final List<String> toInterests;
  final RequestStatus status;
  final int createdAt;
  final int expiresAt;

  bool isOpenAt(int nowMs) =>
      status == RequestStatus.pending && expiresAt > nowMs;
}

class Connection {
  const new({
    required this.id,
    required this.participants,
    required this.names,
    required this.points,
    required this.bonus,
    required this.questionKey,
    required this.questionSeed,
    required this.createdAt,
  });

  factory fromJson(String id, Map<String, Object?> j) => Connection(
    id: id,
    participants: (j['participants'] as List?)?.cast<String>() ?? const [],
    names: (j['names'] as Map?)?.cast<String, String>() ?? const {},
    points: _int(j['points'], 0),
    bonus: _int(j['bonus'], 0),
    questionKey: j['questionKey'] as String? ?? '',
    questionSeed: _int(j['questionSeed'], 0),
    createdAt: _int(j['createdAt'], 0),
  );

  final String id;
  final List<String> participants;
  final Map<String, String> names;
  final int points;
  final int bonus;
  final String questionKey;
  final int questionSeed;
  final int createdAt;

  String otherThan(String uid) =>
      participants.firstWhere((p) => p != uid, orElse: () => '');
}

int _int(Object? v, int fallback) => v is num ? v.toInt() : fallback;
int? _intOrNull(Object? v) => v is num ? v.toInt() : null;
