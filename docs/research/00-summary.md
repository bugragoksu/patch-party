# Araştırma Özeti ve Karar Önerileri

- **Tarih:** 2026-10-22
- **Kaynaklar:** `r1-flutter-web.md`, `r2-firebase.md`, `r3-quality-ops.md`, `r4-game-assets.md`
- **Not (2026-10-22):** Tasarım incelemesinden sonra `connect` fonksiyonu, karşılıklı onay için `requestConnection` + `respondToRequest` olarak ikiye ayrıldı (ADR-0013). Oyuncuya sıralama sunucuda hesaplanıyor (ADR-0014).
- **Amaç:** Dört raporu tek yerde birleştirmek, aralarındaki çelişkileri çözmek, kalan kararları ve spike'ları sıralamak. Onaylanan maddeler mimari dokümanda (`../specs/02-architecture.md`) ve ADR'larda kalıcılaşır.

## 1. Raporlar arası çelişkiler ve önerilen çözüm

| # | Konu | Çelişki | Önerilen çözüm |
|---|---|---|---|
| C1 | Flutter sürümü | R3: güncel paketler (go_router, sentry_flutter, freezed, very_good_analysis) Flutter ≥ 3.44 / Dart ≥ 3.13 istiyor, 3.47.7'ye geç. R1: iPhone kamera önizlemesi 3.42+ sürümlerde siyah (mobile_scanner #1655), 3.38.10'da kal. | **3.47.7.** R1'in kendi önerisi zaten `mobile_scanner` yerine kamerayı Flutter canvas'ının dışında, düz bir `<video>` elemanında göstermek. Bu, #1655'teki platform view sorununu tamamen bypass ediyor. Spike S2 iPhone'da başarısız olursa yedek: 3.38.10 ve paketlerin eski ana sürümleri. |
| C2 | Derleme hedefi | R1: `--wasm` (Android'de skwasm daha küçük ve hızlı). R3: `sentry_flutter` wasm uyumlu değil. R1: Rive data binding wasm altında hata atıyor (rive-flutter #593). | **Yalnızca dart2js + CanvasKit.** iOS zaten her durumda bu yolu kullanıyor. Tek derleme yolu, tek source map hattı, Sentry ve Rive sorunsuz. Bedeli: Android ilk yükleme yaklaşık 1 MB artıyor (yaklaşık 1,6 MB yerine 2,6 MB, brotli). |
| C3 | CI'dan deploy kimliği | R3: `action-hosting-deploy` yalnızca servis hesabı JSON anahtarı kabul ediyor. R2: anahtarsız Workload Identity Federation. | **Anahtarsız (WIF) + `firebase-tools` doğrudan.** Preview kanalları için hazır action'ı kullanmıyoruz. Zaman yetmezse: yalnızca Hosting Admin rolüne sahip, etkinlikten sonra silinen bir anahtar (SEC-42 kabul edilen risk olarak not edilir). |
| C4 | Hesap açma limiti çözümü | R3: konsoldan geçici artış iste. R2: artış iki hafta önceden destek talebiyle mümkün, yetişmez. | **R2'nin `join()` + custom token tasarımı.** Limitin custom token'a da uygulanıp uygulanmadığı spike S1 ile kesinleşir. |

## 2. Önerilen teknik omurga

| Alan | Öneri | Kaynak |
|---|---|---|
| SDK | Flutter 3.47.7, fvm ile projede sabit, CI'da aynı sürüm | C1 |
| Derleme | `flutter build web --release` (dart2js + CanvasKit), `--no-web-resources-cdn` ile her şey kendi alan adımızdan | C2, R1 |
| Uygulama yapısı | Tek uygulama, üç rota: oyuncu `/`, projeksiyon `/screen`, yönetici `/admin`. Projeksiyon ve yönetici `deferred` import ile ayrı yüklenir | R3, R4 |
| Mimari | Feature-first klasörler, saf Dart `domain/` katmanı, Riverpod 3 (kod üretimsiz), go_router, elle yazılmış modeller, sealed `Result`/`GameFailure` | R3 |
| Lint | `very_good_analysis`, sıfır uyarı CI'da zorunlu | R3 |
| Backend | Blaze. İstemci Firestore'a hiç yazmaz. Callable fonksiyonlar: `join`, `connect`, yönetici işlemleri. Kurallar yalnızca okumayı ve sorgu boyutunu sınırlar | R2 |
| Kimlik | `join()` etkinlik kodunu doğrular, custom token verir. Yönetici ve projeksiyon için Google girişi + custom claims + 2FA | R2 |
| QR jetonu | Sunucunun ürettiği gizli tohumdan 30 sn'lik pencerelerle HMAC (TOTP benzeri). Rotasyon yazma gerektirmez. Kısa kod biçimi `K7M-4821` | R2 |
| Bölge | `europe-west3` (Frankfurt), Firestore + Functions. `connect()` için etkinlik günü `minInstances: 1`, `maxInstances: 10` | R2 |
| QR okuma | Kendi ince katmanımız: canvas dışında `<video playsinline muted>`, Android'de yerel BarcodeDetector, iOS'ta kendi sunucumuzdan zxing-wasm. Her zaman elle kısa kod girişi | R1 |
| QR çizimi | `qr_flutter` 4.1.0, hata düzeltme seviyesi M | R1 |
| Projeksiyon grafiği | Kendi `CustomPainter` + basit kuvvet simülasyonu. Paket yok, Flame yok | R1, R4 |
| Animasyon | Önce sade Flutter animasyonları. Rive (0.14.x) üstüne yükseltme olarak, oyuncu katıldıktan sonra arka planda yüklenir, ayarla kapatılabilir | R4 |
| Hata raporlama | Sentry (Crashlytics web'i desteklemiyor). AB bölgesi, `sendDefaultPii=false`, hash'lenmiş uid, dart2js source map yükleme | R3 |
| Canlı izleme | Yönetici panelinde "Sağlık" kartı (Firestore `count()`/`sum()`), Sentry, Firestore Rules Monitor | R3 |
| Test | Önce ~25 güvenlik kuralı ve fonksiyon testi (emülatör), sonra domain birim testleri, 4-6 widget testi. Golden ve web entegrasyon testi yok, manuel smoke listesi var | R3 |
| Yük testi | Node + Firebase JS SDK, 150 sanal oyuncu, önce emülatör sonra staging | R3 |
| Ortamlar | Geliştirme için emülatör, ayrı staging ve prod projeleri. Çalışma zamanı ayarları Firestore `config` belgesinde | R3 |
| Güvenlik | Bütçe uyarıları (otomatik faturalama kapatma yok), App Check önce izleme modunda, CSP önce report-only | R2 |

## 3. İlk yükleme bütçesi (NFR-02 için öneri)

| Platform | Kritik yol (brotli) | Sonradan yüklenen |
|---|---|---|
| Android Chrome | ≤ 2,9 MB (CanvasKit 2,21 + uygulama ~0,4 + fontlar ≤ 0,08) | Rive ~0,8 MB (katılımdan sonra) |
| iPhone Safari | ≤ 2,9 MB (aynı) | Rive ~0,8 MB, zxing-wasm ~0,36 MB (okuma ekranı açılınca) |

`index.html` içinde Flutter yüklenene kadar görünen düz HTML açılış ekranı. Linkin konuşmanın başında paylaşılması önerilir.

## 4. Spike'lar (Cuma sabahı, öncelik sırasıyla)

| # | Spike | Neyi kesinleştirir | Süre | Başarısız olursa |
|---|---|---|---|---|
| S1 | Ayrı bir test projesinde aynı IP'den ~110 custom token girişi | Katılım akışı (C4) | 30 dk | Mobil veriyle katılım + girişleri lobiye yayma |
| S2 | iPhone (iOS 18, 26) Safari/Chrome, Android Chrome, Instagram in-app: kendi kamera katmanımızla dönen QR okutma, 3.47.7'de | QR okuma yaklaşımı, Flutter sürümü (C1) | 2-3 sa | Kendi katmanı 3.38.10'da dene. Olmazsa mobile_scanner fork'u |
| S3 | Gerçek telefonda Fast 4G ile ilk yükleme süresi | NFR-02 | 1 sa | Font, ikon, açılış ekranı optimizasyonu |
| S4 | Rive rozet kabuğu gerçek iPhone ve orta seviye Android'de. `RiveNative.init()` ne zaman indiriyor | Rive'ın kapsamı | 2 sa | Sade Flutter animasyonlarıyla devam |
| S5 | `connect()` gecikmesi Adana'dan, sıcak ve soğuk | G3 (p95 ≤ 1 sn) | 1 sa | `minInstances`, istemcide iyimser arayüz |
| S6 | Projeksiyon grafiği 150 düğüm / 1.500 kenar | FR-20 | 1 sa | Kenar çizimini sadeleştir |
| S7 | Sentry dart2js source map ile okunur stack trace ve paket boyutu etkisi | NFR-05 | 1 sa | Hataları Firestore'a yazan basit kayıtçı |

## 5. Senden beklenen kararlar

| # | Karar | Öneri |
|---|---|---|
| D1 | Flutter 3.47.7'ye geçiş | **Onaylandı (2026-10-22).** S2'ye bağlı yedek: 3.38.10 |
| D2 | Yalnızca dart2js derleme | **Onaylandı (2026-10-22)** |
| D3 | Rive Cadet planı (kişi başı aylık 9 $) | **Ertelendi (2026-10-22).** İlk sürüm Rive'sız. Rive dönünce yeniden değerlendirilecek |
| D4 | Sanat yönü | **Onaylandı (2026-10-22):** A, "Çıkartma Atölyesi" (bkz. R4 §7) |
| D5 | Ayrı staging ve prod Firebase projeleri | **Onaylandı (2026-10-22)** |
| D6 | Sentry hesabı (ücretsiz plan, AB bölgesi) | **Onaylandı (2026-10-22).** Crashlytics web'i desteklemiyor (`firebase_crashlytics` 6.0.0: android, ios, macos). Google Cloud Error Reporting değerlendirildi, okunur stack trace olmadığı için elendi. Hata raporlama `ErrorReporter` arayüzü arkasında, sağlayıcı değiştirmek tek dosya |
| D7 | Gereksinimlerdeki açık sorular Q2-Q7 | `../specs/01-requirements.md` §10 |
