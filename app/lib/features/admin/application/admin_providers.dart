import 'package:baglanti_agi/app/providers.dart';
import 'package:baglanti_agi/core/data/staff_auth.dart';
import 'package:baglanti_agi/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final staffAuthProvider = Provider<StaffAuth>((ref) => StaffAuth());

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(),
);

enum AdminAccess { signedOut, notAdmin, admin }

/// Who is looking at the panel. Only the `admin` custom claim counts
/// (SEC-40); claims are read with a forced token refresh so a freshly
/// granted role shows up without signing out.
final adminAccessProvider = FutureProvider<AdminAccess>((ref) async {
  // Keyed on uid: token refreshes must not re-run (and re-refresh) this.
  final uid = await ref.watch(authUserProvider.selectAsync((u) => u?.uid));
  if (uid == null) return AdminAccess.signedOut;
  final claims = await ref.read(staffAuthProvider).claims();
  return claims['admin'] == true ? AdminAccess.admin : AdminAccess.notAdmin;
});

/// Players plus failure counters; refreshed by invalidation (manual button or
/// after a moderation action), not streamed, to keep reads predictable.
final reviewDataProvider = FutureProvider<ReviewData>(
  (ref) =>
      ref.watch(adminRepositoryProvider).readReview(ref.watch(eventIdProvider)),
);

final auditLogProvider = StreamProvider<List<AuditEntry>>(
  (ref) =>
      ref.watch(adminRepositoryProvider).watchAudit(ref.watch(eventIdProvider)),
);

final adminJoinSeedProvider = FutureProvider<String?>(
  (ref) => ref
      .watch(adminRepositoryProvider)
      .readJoinSeed(ref.watch(eventIdProvider)),
);
