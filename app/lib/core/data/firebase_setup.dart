import 'package:baglanti_agi/app/env.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

/// Web config comes from APP_FIREBASE_* (it is not secret); nothing is
/// committed as firebase_options.dart.
Future<void> initFirebase() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: Env.firebaseApiKey == '' ? 'demo-key' : Env.firebaseApiKey,
      appId: Env.firebaseAppId == '' ? 'demo-app' : Env.firebaseAppId,
      // Staff Google sign-in (popup) fails without it. The value is set at
      // build time, so the analyzer sees only the empty default.
      // ignore: avoid_redundant_argument_values
      authDomain: Env.firebaseAuthDomain == '' ? null : Env.firebaseAuthDomain,
      messagingSenderId: Env.firebaseMessagingSenderId,
      projectId: Env.firebaseProjectId,
    ),
  );
  if (Env.useEmulator) {
    const host = '127.0.0.1';
    FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instance.useAuthEmulator(host, 9099);
    FirebaseFunctions.instanceFor(region: Env.functionsRegion)
        .useFunctionsEmulator(host, 5001);
  }
}

/// Staff (admin / projector) use their own Firebase app, so their Google
/// session is stored apart from a player's custom-token session: joining as
/// a player in another tab no longer signs the admin out.
const staffAppName = 'staff';

FirebaseApp get staffApp => Firebase.app(staffAppName);

/// Called before a staff surface loads; safe to call more than once.
Future<void> initStaffFirebase() async {
  if (Firebase.apps.any((a) => a.name == staffAppName)) return;
  final app = await Firebase.initializeApp(
    name: staffAppName,
    options: Firebase.app().options,
  );
  if (Env.useEmulator) {
    const host = '127.0.0.1';
    FirebaseFirestore.instanceFor(app: app).useFirestoreEmulator(host, 8080);
    await FirebaseAuth.instanceFor(app: app).useAuthEmulator(host, 9099);
    FirebaseFunctions.instanceFor(
      app: app,
      region: Env.functionsRegion,
    ).useFunctionsEmulator(host, 5001);
  }
}
