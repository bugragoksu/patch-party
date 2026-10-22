# Mimari Karar Kayıtları (ADR)

Şablon: `0000-template.md`. Bir karar değişirse eski ADR silinmez, durumu "Yerine geçildi (ADR-XXXX)" olur.

| ADR | Karar | Durum |
|---|---|---|
| [0001](0001-flutter-web-single-app-dart2js.md) | Flutter web, tek uygulama, dart2js, Flutter 3.47.7 | Kabul (S2'ye bağlı yedek) |
| [0002](0002-blaze-callable-functions-only-writes.md) | Blaze, bütün yazmalar callable fonksiyonlardan, `europe-west3` | Kabul |
| [0003](0003-identity-custom-token-and-staff-claims.md) | Oyuncu: `join()` + custom token. Ekip: Google + custom claims | Kabul (S1'e bağlı) |
| [0004](0004-rotating-totp-tokens-and-shared-vectors.md) | TOTP tabanlı dönen jetonlar, QR içeriği URL, ortak test vektörleri | Kabul |
| [0005](0005-client-architecture-riverpod-feature-first.md) | Feature-first katmanlar, Riverpod 3, go_router, elle modeller, `Result` | Kabul |
| [0006](0006-qr-scanning-custom-web-layer.md) | QR okuma için Flutter dışında ince web katmanı | Kabul (S2'ye bağlı) |
| [0007](0007-error-reporting-sentry.md) | Sentry, `ErrorReporter` arayüzü arkasında | Kabul |
| [0008](0008-projector-graph-custom-painter.md) | Projeksiyon grafiği kendi `CustomPainter`'ımız, Flame yok | Kabul (S6'ya bağlı) |
| [0009](0009-animation-flutter-baseline-rive-enhancement.md) | Önce sade Flutter animasyonları, Rive yükseltme | Kabul (S4'e bağlı) |
| [0010](0010-environments-ci-cd-release.md) | Emülatör/staging/prod, GitHub Actions, WIF, yayın dondurma | Kabul |
| [0011](0011-read-fanout-projector-only-leaderboard.md) | Global sıralama yalnızca projeksiyonda | Kabul (oyuncu tarafı 0014 ile değişti) |
| [0012](0012-abuse-controls-app-check-headers.md) | App Check, hız sınırları, bütçe, güvenlik başlıkları | Kabul |
| [0013](0013-mutual-confirmation-request-flow.md) | Karşılıklı onay: `requestConnection` + `respondToRequest` | Kabul |
| [0014](0014-server-computed-player-rank.md) | Oyuncu sırası sunucuda, dakikada bir | Kabul |
