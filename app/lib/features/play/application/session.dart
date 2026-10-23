import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The signed-in player of this event, or null if this browser has not joined.
class PlayerSession {
  const new({required this.uid, required this.eventId, required this.seed});

  final String uid;
  final String eventId;
  final String seed;
}

/// The session handed back by `join` in this tab. It lets the game start
/// without re-reading claims and the seed from Firestore (NFR-02).
final joinedSessionProvider = NotifierProvider<JoinedSession, PlayerSession?>(
  JoinedSession.new,
);

class JoinedSession extends Notifier<PlayerSession?> {
  @override
  PlayerSession? build() => null;

  // A method, not a setter: it reads as an action at the call site.
  // ignore: use_setters_to_change_properties
  void set(PlayerSession session) => state = session;
}

final playerSessionProvider = FutureProvider<PlayerSession?>((ref) async {
  final user = ref.watch(authUserProvider).value;
  if (user == null) return null;
  final joined = ref.watch(joinedSessionProvider);
  if (joined != null && joined.uid == user.uid) return joined;
  final claims = await ref.watch(claimsProvider.future);
  final eventId = ref.watch(eventIdProvider);
  if (claims['eventId'] != eventId) return null;
  final seed = await ref
      .read(gameRepositoryProvider)
      .readSeed(eventId, user.uid);
  if (seed == null) return null;
  return PlayerSession(uid: user.uid, eventId: eventId, seed: seed);
});

final myPlayerProvider = StreamProvider<Player?>((ref) {
  final session = ref.watch(playerSessionProvider).value;
  if (session == null) return Stream.value(null);
  return ref
      .watch(gameRepositoryProvider)
      .watchPlayer(session.eventId, session.uid);
});

final incomingRequestsProvider = StreamProvider<List<ConnectionRequest>>((ref) {
  final session = ref.watch(playerSessionProvider).value;
  if (session == null) return Stream.value(const []);
  return ref
      .watch(gameRepositoryProvider)
      .watchIncoming(session.eventId, session.uid);
});

final myConnectionsProvider = StreamProvider<List<Connection>>((ref) {
  final session = ref.watch(playerSessionProvider).value;
  if (session == null) return Stream.value(const []);
  return ref
      .watch(gameRepositoryProvider)
      .watchConnections(session.eventId, session.uid);
});

/// Watches my own open outgoing request so the "waiting" screen reacts to
/// accept / decline / expiry from the other phone.
final outgoingRequestProvider = StreamProvider<ConnectionRequest?>((ref) {
  final session = ref.watch(playerSessionProvider).value;
  final id = ref.watch(
    myPlayerProvider.select((p) => p.value?.outgoingRequest?.requestId),
  );
  if (session == null || id == null) return Stream.value(null);
  return ref.watch(gameRepositoryProvider).watchRequest(session.eventId, id);
});
