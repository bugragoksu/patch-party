import 'package:baglanti_agi/core/data/firebase_setup.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Staff-only reads for the projector (rules: `isStaff()`). The projector is
/// the single listener of the full players and connections collections;
/// ranking and counters are derived on the client (ADR-0011).
class ProjectorRepository {
  new({FirebaseFirestore? firestore})
    : _db = firestore ?? FirebaseFirestore.instanceFor(app: staffApp);

  final FirebaseFirestore _db;

  Stream<List<Player>> watchPlayers(String eventId) => _db
      .collection('events/$eventId/players')
      .snapshots()
      .map((q) => [for (final d in q.docs) Player.fromJson(d.id, d.data())]);

  Stream<List<Connection>> watchConnections(String eventId) => _db
      .collection('events/$eventId/connections')
      .snapshots()
      .map(
        (q) => [for (final d in q.docs) Connection.fromJson(d.id, d.data())],
      );

  /// Seed for the rotating join code (02-architecture §7.2); read once.
  Future<String?> readJoinSeed(String eventId) async {
    final snap = await _db.doc('events/$eventId/private/joinSecret').get();
    return snap.data()?['joinSeed'] as String?;
  }
}
