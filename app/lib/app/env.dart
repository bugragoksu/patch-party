/// Build-time configuration. Only APP_* keys from `.env.<env>` reach the bundle
/// (tools/env.mjs); never put a secret here.
abstract final class Env {
  static const name = String.fromEnvironment('APP_ENV', defaultValue: 'dev');
  static const eventId = String.fromEnvironment('APP_EVENT_ID');
  static const useEmulator = bool.fromEnvironment('APP_USE_EMULATOR');
  static const sentryDsn = String.fromEnvironment('APP_SENTRY_DSN');
  static const version = String.fromEnvironment(
    'APP_VERSION',
    defaultValue: '0.1.0',
  );
  static const recaptchaSiteKey = String.fromEnvironment(
    'APP_RECAPTCHA_SITE_KEY',
  );

  static const firebaseApiKey = String.fromEnvironment('APP_FIREBASE_API_KEY');
  static const firebaseAuthDomain = String.fromEnvironment(
    'APP_FIREBASE_AUTH_DOMAIN',
  );
  static const firebaseProjectId = String.fromEnvironment(
    'APP_FIREBASE_PROJECT_ID',
    defaultValue: 'demo-baglanti',
  );
  static const firebaseStorageBucket = String.fromEnvironment(
    'APP_FIREBASE_STORAGE_BUCKET',
  );
  static const firebaseMessagingSenderId = String.fromEnvironment(
    'APP_FIREBASE_MESSAGING_SENDER_ID',
  );
  static const firebaseAppId = String.fromEnvironment('APP_FIREBASE_APP_ID');

  static const functionsRegion = 'europe-west3';
}
