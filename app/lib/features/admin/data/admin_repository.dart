import 'dart:async';

import 'package:baglanti_agi/app/env.dart';
import 'package:baglanti_agi/core/data/firebase_setup.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;

/// `events/{e}/rateLimits/{uid}` (functions/src/data/model.ts RateLimitDoc).
class RateLimitInfo {
  const new({
    required this.uid,
    required this.totalFailures,
    this.blockedUntil,
    this.lastFailureReason,
  });

  factory fromJson(String uid, Map<String, Object?> j) => RateLimitInfo(
    uid: uid,
    totalFailures: (j['totalFailures'] as num?)?.toInt() ?? 0,
    blockedUntil: (j['blockedUntil'] as num?)?.toInt(),
    lastFailureReason: j['lastFailureReason'] as String?,
  );

  final String uid;
  final int totalFailures;
  final int? blockedUntil;
  final String? lastFailureReason;
}

/// `events/{e}/auditLog/{id}`.
class AuditEntry {
  const new({
    required this.id,
    required this.action,
    required this.at,
    this.target,
  });

  factory fromJson(String id, Map<String, Object?> j) => AuditEntry(
    id: id,
    action: j['action'] as String? ?? '',
    target: j['target'] as String?,
    at: (j['at'] as num?)?.toInt() ?? 0,
  );

  final String id;
  final String action;
  final String? target;
  final int at;
}

/// One round of the health card's aggregate queries (NFR-06).
class HealthSample {
  const new({
    required this.players,
    required this.activePlayers,
    required this.connections,
    required this.totalFailures,
    required this.blockedPlayers,
    required this.atMs,
  });

  final int players;
  final int activePlayers;
  final int connections;
  final int totalFailures;
  final int blockedPlayers;
  final int atMs;
}

/// Players and their failure counters, read once for the review list.
class ReviewData {
  const new({required this.players, required this.rateLimits});

  final List<Player> players;
  final Map<String, RateLimitInfo> rateLimits;
}

/// An [Err] that keeps the raw server reason, for admin-only reasons
/// (`invalid_transition`, `invalid_argument`) that [GameFailure] folds into
/// [Unknown].
class AdminErr<T> extends Err<T> {
  const new(super.failure, this.reason);
  final String? reason;
}

/// The single boundary to Firebase for the admin panel. Writes are callables
/// guarded by the `admin` claim on the server (SEC-40); reads are allowed to
/// admins by firestore.rules.
class AdminRepository {
  new({FirebaseFirestore? firestore, FirebaseFunctions? functions})
    : _db = firestore ?? FirebaseFirestore.instanceFor(app: staffApp),
      _functions =
          functions ??
          FirebaseFunctions.instanceFor(
            app: staffApp,
            region: Env.functionsRegion,
          );

  final FirebaseFirestore _db;
  final FirebaseFunctions _functions;

  CollectionReference<Map<String, dynamic>> _col(String e, String name) =>
      _db.collection('events/$e/$name');

  // ---- reads ---------------------------------------------------------------

  /// Staff may read it (rules); the join code is derived from it locally.
  Future<String?> readJoinSeed(String eventId) async {
    final snap = await _db.doc('events/$eventId/private/joinSecret').get();
    return snap.data()?['joinSeed'] as String?;
  }

  Future<ReviewData> readReview(String eventId) async {
    final results = await Future.wait([
      _col(eventId, 'players').get(),
      _col(eventId, 'rateLimits').get(),
    ]);
    return ReviewData(
      players: [
        for (final d in results[0].docs) Player.fromJson(d.id, d.data()),
      ],
      rateLimits: {
        for (final d in results[1].docs)
          d.id: RateLimitInfo.fromJson(d.id, d.data()),
      },
    );
  }

  Stream<List<AuditEntry>> watchAudit(String eventId, {int limit = 20}) =>
      _col(eventId, 'auditLog')
          .orderBy('at', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (q) => [
              for (final d in q.docs) AuditEntry.fromJson(d.id, d.data()),
            ],
          );

  /// Aggregate queries only: each costs one read per 1000 index entries.
  Future<HealthSample> readHealth(
    String eventId, {
    required int nowMs,
    Duration activeWindow = const Duration(minutes: 5),
  }) async {
    final players = _col(eventId, 'players');
    final limits = _col(eventId, 'rateLimits');
    final results = await Future.wait([
      players.count().get(),
      players
          .where(
            'lastConnectionAt',
            isGreaterThanOrEqualTo: nowMs - activeWindow.inMilliseconds,
          )
          .count()
          .get(),
      _col(eventId, 'connections').count().get(),
      limits.aggregate(sum('totalFailures')).get(),
      limits.where('blockedUntil', isGreaterThan: nowMs).count().get(),
    ]);
    return HealthSample(
      players: results[0].count ?? 0,
      activePlayers: results[1].count ?? 0,
      connections: results[2].count ?? 0,
      totalFailures: results[3].getSum('totalFailures')?.round() ?? 0,
      blockedPlayers: results[4].count ?? 0,
      atMs: nowMs,
    );
  }

  // ---- callables -----------------------------------------------------------

  Future<Result<EventState>> setEventState(
    String eventId,
    EventState state, {
    int? liveDurationMin,
  }) => _guard(() async {
    final d = await _call('setEventState', {
      'eventId': eventId,
      'state': state.name,
      'liveDurationMin': ?liveDurationMin,
    });
    return EventState.parse(d['state']);
  });

  Future<Result<void>> updateEventConfig(
    String eventId,
    Map<String, Object?> settings,
  ) => _guard(() async {
    await _call('updateEventConfig', {
      'eventId': eventId,
      'settings': settings,
    });
  });

  Future<Result<void>> moderatePlayer(
    String eventId,
    String uid,
    ModerationAction action, {
    String? displayName,
  }) => _guard(() async {
    await _call('moderatePlayer', {
      'eventId': eventId,
      'uid': uid,
      'action': action.name,
      'displayName': ?displayName,
    });
  });

  Future<Result<int>> purgeEvent(String eventId, String confirm) =>
      _guard(() async {
        final d = await _call('purgeEvent', {
          'eventId': eventId,
          'confirm': confirm,
        }, timeout: const Duration(seconds: 120));
        return (d['deletedUsers'] as num?)?.toInt() ?? 0;
      });

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data, {
    Duration timeout = const Duration(seconds: 20),
  }) async {
    final result = await _functions
        .httpsCallable(name, options: HttpsCallableOptions(timeout: timeout))
        .call<Map<String, dynamic>>(data);
    return result.data.cast<String, Object?>();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on FirebaseFunctionsException catch (e) {
      final details = (e.details as Map?)?.cast<String, Object?>();
      final reason = details?['reason'] as String?;
      if (reason == null &&
          (e.code == 'unavailable' || e.code == 'deadline-exceeded')) {
        return AdminErr<T>(const Offline(), null);
      }
      if (reason == null && e.code == 'permission-denied') {
        return AdminErr<T>(const NotAllowed(), null);
      }
      return AdminErr<T>(GameFailure.fromReason(reason, details), reason);
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return AdminErr<T>(const Offline(), null);
      rethrow;
    } on TimeoutException {
      return AdminErr<T>(const Offline(), null);
    }
  }
}

enum ModerationAction { disqualify, restore, hideName, showName, rename }
