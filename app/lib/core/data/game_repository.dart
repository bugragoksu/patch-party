import 'dart:async';

import 'package:baglanti_agi/app/env.dart';
import 'package:baglanti_agi/core/domain/failures.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart' hide Result;
import 'package:firebase_auth/firebase_auth.dart';

class JoinOutcome {
  const new({
    required this.uid,
    required this.playerCode,
    required this.totpSeed,
    required this.serverTime,
  });

  final String uid;
  final String playerCode;
  final String totpSeed;
  final int serverTime;
}

class RequestOutcome {
  const new({
    required this.requestId,
    required this.accepted,
    required this.expiresAt,
    required this.targetName,
    required this.targetInterests,
    this.connection,
  });

  final String requestId;
  final bool accepted;
  final int expiresAt;
  final String targetName;
  final List<String> targetInterests;
  final ConnectionOutcome? connection;
}

class ConnectionOutcome {
  const new({
    required this.connectionId,
    required this.points,
    required this.bonus,
    required this.questionKey,
    required this.questionSeed,
  });

  factory fromJson(Map<String, Object?> j) => ConnectionOutcome(
    connectionId: j['connectionId'] as String? ?? '',
    points: (j['points'] as num?)?.toInt() ?? 0,
    bonus: (j['bonus'] as num?)?.toInt() ?? 0,
    questionKey: j['questionKey'] as String? ?? '',
    questionSeed: (j['questionSeed'] as num?)?.toInt() ?? 0,
  );

  final String connectionId;
  final int points;
  final int bonus;
  final String questionKey;
  final int questionSeed;
}

/// The single boundary to Firebase for the player surface. Reads are live
/// streams; every write is a callable (ADR-0002). Errors become [GameFailure].
class GameRepository {
  new({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    FirebaseFunctions? functions,
  }) : _db = firestore ?? FirebaseFirestore.instance,
       _auth = auth ?? FirebaseAuth.instance,
       _functions =
           functions ??
           FirebaseFunctions.instanceFor(region: Env.functionsRegion);

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;
  final FirebaseFunctions _functions;

  DocumentReference<Map<String, dynamic>> _event(String e) =>
      _db.doc('events/$e');

  Stream<EventInfo?> watchEvent(String eventId) =>
      _event(eventId)
          .snapshots()
          .map((s) => s.exists ? EventInfo.fromJson(s.id, s.data()!) : null);

  Stream<Player?> watchPlayer(String eventId, String uid) => _db
      .doc('events/$eventId/players/$uid')
      .snapshots()
      .map((s) => s.exists ? Player.fromJson(s.id, s.data()!) : null);

  Stream<List<ConnectionRequest>> watchIncoming(String eventId, String uid) =>
      _db
          .collection('events/$eventId/connectionRequests')
          .where('toUid', isEqualTo: uid)
          .where('status', isEqualTo: 'pending')
          .limit(3)
          .snapshots()
          .map(
            (q) => q.docs
                .map((d) => ConnectionRequest.fromJson(d.id, d.data()))
                .toList(),
          );

  Stream<ConnectionRequest?> watchRequest(String eventId, String requestId) =>
      _db
          .doc('events/$eventId/connectionRequests/$requestId')
          .snapshots()
          .map(
            (s) =>
                s.exists ? ConnectionRequest.fromJson(s.id, s.data()!) : null,
          );

  Stream<List<Connection>> watchConnections(String eventId, String uid) => _db
      .collection('events/$eventId/connections')
      .where('participants', arrayContains: uid)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map(
        (q) => q.docs.map((d) => Connection.fromJson(d.id, d.data())).toList(),
      );

  Future<String?> readSeed(String eventId, String uid) async {
    final s = await _db.doc('events/$eventId/playerSecrets/$uid').get();
    return s.data()?['totpSeed'] as String?;
  }

  Future<Result<JoinOutcome>> join({
    required String eventId,
    required String joinCode,
    required String displayName,
    required List<String> interests,
  }) => _guard(() async {
    final data = await _call('join', {
      'eventId': eventId,
      'joinCode': joinCode,
      'displayName': displayName,
      'interests': interests,
    });
    await _auth.signInWithCustomToken(data['customToken']! as String);
    return JoinOutcome(
      uid: data['uid']! as String,
      playerCode: data['playerCode']! as String,
      totpSeed: data['totpSeed']! as String,
      serverTime: (data['serverTime']! as num).toInt(),
    );
  });

  Future<Result<RequestOutcome>> requestConnection(
    String eventId,
    String code,
  ) => _guard(() async {
    final d = await _call('requestConnection', {
      'eventId': eventId,
      'code': code,
    });
    final target = (d['target']! as Map).cast<String, Object?>();
    final conn = (d['connection'] as Map?)?.cast<String, Object?>();
    return RequestOutcome(
      requestId: d['requestId']! as String,
      accepted: d['status'] == 'accepted',
      expiresAt: (d['expiresAt']! as num).toInt(),
      targetName: target['name']! as String,
      targetInterests: (target['interests']! as List).cast<String>(),
      connection: conn == null ? null : ConnectionOutcome.fromJson(conn),
    );
  });

  Future<Result<ConnectionOutcome?>> respond(
    String eventId,
    String requestId, {
    required bool accept,
  }) => _guard(() async {
    final d = await _call('respondToRequest', {
      'eventId': eventId,
      'requestId': requestId,
      'accept': accept,
    });
    final conn = (d['connection'] as Map?)?.cast<String, Object?>();
    return conn == null ? null : ConnectionOutcome.fromJson(conn);
  });

  Future<Result<void>> cancel(String eventId, String requestId) =>
      _guard(() async {
        await _call('cancelRequest', {
          'eventId': eventId,
          'requestId': requestId,
        });
      });

  Future<Map<String, Object?>> _call(
    String name,
    Map<String, Object?> data,
  ) async {
    final result = await _functions
        .httpsCallable(
          name,
          options: HttpsCallableOptions(timeout: const Duration(seconds: 12)),
        )
        .call<Map<String, dynamic>>(data);
    return result.data.cast<String, Object?>();
  }

  Future<Result<T>> _guard<T>(Future<T> Function() body) async {
    try {
      return Ok(await body());
    } on FirebaseFunctionsException catch (e) {
      final details = (e.details as Map?)?.cast<String, Object?>();
      final reason = details?['reason'] as String?;
      // Only a missing reason means the server never answered.
      if (reason == null &&
          (e.code == 'unavailable' || e.code == 'deadline-exceeded')) {
        return Err<T>(const Offline());
      }
      return Err<T>(GameFailure.fromReason(reason, details));
    } on FirebaseException catch (e) {
      if (e.code == 'unavailable') return Err<T>(const Offline());
      rethrow;
    } on TimeoutException {
      return Err<T>(const Offline());
    }
  }
}
