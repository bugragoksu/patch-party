# ADR-0007: Hata raporlama Sentry ile, `ErrorReporter` arayüzünün arkasında

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** NFR-05, NFR-06, NFR-08, SEC-22, R3, D6

## Bağlam

Etkinlik sırasında bir hata çıkarsa nerede olduğunu dakikalar içinde görebilmeliyiz. Crashlytics web'i desteklemiyor (`firebase_crashlytics` 6.0.0: yalnızca android, ios, macos; pub.dev'de 2026-10-22'de doğrulandı).

## Seçenekler

1. **Sentry** (`sentry_flutter` + `sentry_dart_plugin`): dart2js source map ile okunur stack trace, gruplama, e-posta alarmı. Ücretsiz plan ayda 5 bin hata.
2. **Google Cloud Error Reporting:** Hataları bir fonksiyon aracılığıyla Cloud Logging'e yazmak. Veri Google'da kalır, ama stack trace'ler küçültülmüş isimlerle okunaksız gelir. Ayrıca yarım gün ek iş ve dışarıya açık yeni bir uç nokta demek.
3. Hataları Firestore'a yazmak: gruplama ve sembolizasyon bizde kalır.

## Karar

**Sentry**, AB veri bölgesinde. `sendDefaultPii = false`, `beforeSend` içinde ad, kod, jeton ve URL fragment'ı temizlenir. Kullanıcı kimliği hash'lenir. Session Replay ve performance tracing kapalı. Global yakalama `SentryFlutter.init(appRunner:)` ile (`FlutterError.onError` + `PlatformDispatcher.onError`). Uygulama kodu Sentry'yi doğrudan değil, `ErrorReporter` arayüzünü kullanır.

## Sonuçlar

- Sentry projesi EU bölgesinde açıldı (2026-10-22). DSN repoda tutulmaz (`../ops/accounts.md`).
- Sağlayıcı değiştirmek tek dosya.
- Aydınlatma metnine "hata kayıtları yurt dışındaki hizmet sağlayıcıda tutulur" ifadesi eklenir.
- Release başına source map yükleme CI'da bir adım. S7 spike'ı sembolizasyonu ve paket boyutu etkisini doğrular.
