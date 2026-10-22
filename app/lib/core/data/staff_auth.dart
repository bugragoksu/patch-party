import 'package:firebase_auth/firebase_auth.dart';

/// Staff (admin / projector) sign in with Google; their role comes only from
/// custom claims set by tools/admin/setup-event.mjs (SEC-40).
class StaffAuth {
  new({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  Future<void> signInWithGoogle() =>
      _auth.signInWithPopup(GoogleAuthProvider());

  Future<void> signOut() => _auth.signOut();

  /// Forces a token refresh so freshly assigned claims are visible.
  Future<Map<String, Object?>> claims() async {
    final result = await _auth.currentUser?.getIdTokenResult(true);
    return result?.claims?.cast<String, Object?>() ?? const {};
  }
}
