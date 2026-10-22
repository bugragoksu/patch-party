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
