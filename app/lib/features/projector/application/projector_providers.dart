import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/core/data/staff_auth.dart';
import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/projector/data/projector_repository.dart';
import 'package:baglanti_agi/features/projector/leaderboard/leaderboard.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final projectorRepositoryProvider = Provider<ProjectorRepository>(
  (ref) => ProjectorRepository(),
);

final staffAuthProvider = Provider<StaffAuth>((ref) => StaffAuth());

enum ProjectorAccess { signedOut, denied, granted }

/// Staff gate: Google sign-in plus a `projector` or `admin` custom claim.
/// Keyed on the uid only: `claims()` refreshes the ID token, which must not
/// re-trigger this provider through `idTokenChanges`.
final projectorAccessProvider = FutureProvider<ProjectorAccess>((ref) async {
  final uid = ref.watch(authUserProvider.select((a) => a.value?.uid));
  if (uid == null) return ProjectorAccess.signedOut;
  final claims = await ref.watch(staffAuthProvider).claims();
  final ok = claims['projector'] == true || claims['admin'] == true;
  return ok ? ProjectorAccess.granted : ProjectorAccess.denied;
});

final StreamProvider<List<Player>> projectorPlayersProvider =
    StreamProvider.autoDispose<List<Player>>(
      (ref) => ref
          .watch(projectorRepositoryProvider)
          .watchPlayers(ref.watch(eventIdProvider)),
    );

final StreamProvider<List<Connection>> projectorConnectionsProvider =
    StreamProvider.autoDispose<List<Connection>>(
      (ref) => ref
          .watch(projectorRepositoryProvider)
          .watchConnections(ref.watch(eventIdProvider)),
    );

final FutureProvider<String?> joinSeedProvider =
    FutureProvider.autoDispose<String?>(
      (ref) => ref
          .watch(projectorRepositoryProvider)
          .readJoinSeed(ref.watch(eventIdProvider)),
    );

/// Non-disqualified players; stable instance while the stream value is
/// unchanged, so the graph only resyncs on real data changes.
final Provider<List<Player>?> activePlayersProvider =
    Provider.autoDispose<List<Player>?>((ref) {
      final all = ref.watch(projectorPlayersProvider.select((a) => a.value));
      return all?.where((p) => !p.disqualified).toList(growable: false);
    });

/// Full ranking computed on the client (ADR-0011).
final Provider<List<Player>?> rankedPlayersProvider =
    Provider.autoDispose<List<Player>?>((ref) {
      final all = ref.watch(projectorPlayersProvider.select((a) => a.value));
      return all == null ? null : rankPlayers(all);
    });
