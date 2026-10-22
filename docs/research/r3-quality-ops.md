# R3: Kalite, Hata Yönetimi ve Operasyon

- **Tarih:** 2026-10-22
- **Kapsam:** NFR-04, NFR-05, NFR-06, NFR-12, NFR-14 ([01-requirements.md](../specs/01-requirements.md))
- **İlke:** 3 günlük iş. Her öneride "neyi atlıyoruz" açıkça yazılı.

> **Önce okunması gereken iki bulgu**
> 1. **Flutter sürümü:** Yereldeki 3.38.5 (Dart 3.10), güncel paketlerin çoğunu kuramıyor. `go_router 18.1.1` ve `sentry_flutter 10.2.0` Flutter ≥ 3.44, `freezed 4.0.3` ve `very_good_analysis 11.0.0` Dart ≥ 3.13 istiyor. Güncel stable **3.47.7** (2026-10-08, Dart 3.13.5). Kaynak: [Flutter releases manifest](https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json), pub.dev API (2026-10-22'de kontrol edildi).
> 2. **Auth hesap açma kotası:** Firebase Auth, **IP başına saatte 100 yeni hesap** sınırı uyguluyor ([Auth limits](https://firebase.google.com/docs/auth/limits), son güncelleme 2026-10-20). Salon Wi-Fi'ı NAT arkasında olduğu için 150 telefon tek IP'den görünebilir. Anonim girişte bu sınır etkinliği doğrudan kilitler. Ayrıntı ve önlem için §5 ve "Riskler" bölümüne bakın.

---

## 1. Flutter web'de crash ve hata raporlama

**Soru:** Crashlytics web'i destekliyor mu? Hangi aracı seçmeliyiz ve olaylara hangi bağlamı eklemeliyiz?

**Bulgular**
- **Crashlytics web'i desteklemiyor.** `firebase_crashlytics 6.0.0` yalnızca Android, iOS ve macOS'u listeliyor ([pub.dev](https://pub.dev/packages/firebase_crashlytics), 2026-10-22'de bakıldı).
- **`sentry_flutter 10.2.0`** web'i destekliyor (2026-10-22'de yayımlandı, Flutter ≥ 3.44) ([pub.dev](https://pub.dev/packages/sentry_flutter)). Sürüm 9 ile Flutter Web'e "native JS error" ve Release Health desteği geldi ([Sentry changelog, 2025-06-24](https://sentry.io/changelog/flutter-v9)).
- **Source map (dart2js):** `flutter build web --release --source-maps` ile derlenir, ardından `sentry_dart_plugin` ile yüklenir (`upload_source_maps: true`, `SENTRY_AUTH_TOKEN`). Plugin 3.x, source map'lere Debug ID gömüyor (SDK ≥ 9.1 gerekir). Stack trace sembolize oluyor ama issue başlıkları minified kalıyor ([Sentry Dart Plugin docs](https://docs.sentry.io/platforms/dart/guides/flutter/debug-symbols/dart-plugin/)).
- **Wasm:** pub.dev analizi `sentry_flutter` için "not compatible with runtime wasm" diyor. Sebebi `package_info_plus` üzerinden gelen `dart:io` importu ([pub.dev score](https://pub.dev/packages/sentry_flutter/score)). Flutter, `--wasm` derlemesinde `main.dart.wasm.map` üretebiliyor ([Flutter Wasm docs](https://docs.flutter.dev/platform-integration/web/wasm)). Ancak Sentry'nin wasm map'ini sembolize ettiğine dair resmi bir kaynak bulamadım.
- **Ücretsiz plan:** Sentry Developer planı ayda 5k hata, 1 kullanıcı, 30 gün saklama, 10 dashboard ve yalnızca e-posta alarmı veriyor ([Sentry pricing](https://sentry.io/pricing/), 2026-10-22).
- **Global hata yakalayıcılar:** Flutter dokümanının güncel önerisi `FlutterError.onError` + `PlatformDispatcher.instance.onError` (`true` döner) + `MaterialApp.builder` içinde `ErrorWidget.builder`. `runZonedGuarded` artık önerilmiyor ([Flutter: Handling errors](https://docs.flutter.dev/testing/errors), 2026-09-29, 3.47). Sentry'nin `appRunner`'ı Flutter ≥ 3.3'te bu iki hook'u kendisi bağlıyor.
- **Firebase'in kendi alternatifleri:** Analytics olayları canlı değil (gecikmeli) ve stack trace taşımıyor. Hataları Firestore'a yazmak da mümkün ama sembolizasyon, gruplama ve kota yönetimi o zaman bizde kalıyor.

**Öneri: Sentry (`sentry_flutter` + `sentry_dart_plugin`), dart2js derlemesi ile.**
```dart
await SentryFlutter.init((o) {
  o.dsn = Env.sentryDsn;               // --dart-define-from-file
  o.environment = Env.name;            // staging | prod
  o.release = 'baglanti-agi@${Env.version}';
  o.sendDefaultPii = false;
  o.beforeSend = scrubPii;             // isim, kısa kod, QR jetonu temizlenir
  o.sampleRate = 1.0; o.tracesSampleRate = 0; // performans izleme kapalı
}, appRunner: () => runApp(const ProviderScope(child: App())));
```
- **Eklenecek bağlam:**
  - `release` ve `dist` (git SHA)
  - `tags`: `surface` (player/projector/admin), `eventState` (lobby/live/…), `browser` (Sentry zaten ekliyor) ve `inAppBrowser` (bool)
  - `user.id`: Firebase uid'nin değil, `sha256(uid + eventSalt)` değerinin ilk 16 karakteri
  - Breadcrumb: sadece olay adları (`scan_started`, `scan_rejected:expired`)
- **Kullanıcıya gösterim:** Teknik hata metni gösterilmez. `ErrorWidget.builder` ve hata ekranları "Yenile / Kodla gir" gibi bir kurtarma yolu sunar (NFR-05).
- **Atlanacaklar:** Session Replay (ekranda isimler var, KVKK açısından risk), performance tracing, wasm sembolizasyonu.
- **Wasm kararı:** R1 wasm'ı seçerse iki seçenek var. Ya sembolizasyon olmadan yaşanır ya da Sentry JS'e düşülür. Ben **dart2js** öneriyorum (bkz. Spike).

**Güven:** Yüksek (Crashlytics'in web'de olmadığı ve Sentry kurulumu). Orta (Sentry'nin wasm uyumu ve bundle maliyeti).

**Spike gerekli mi:** Evet, 1 saat.
- Boş bir 3.47 projesine Sentry ekleyip `main.dart.js` boyutundaki artışı (gzip) ölç.
- Kasıtlı bir hata fırlatıp staging'de sembolize stack trace göründüğünü doğrula.
- R1 wasm seçtiyse `--wasm` ile de dene.

---

## 2. Etkinlik sırasında canlı izleme

**Soru:** NFR-06'yı (aktif oyuncu, bağlantı hızı, hata sayısı, reddedilen yazma) hafif ve KVKK'ya uygun şekilde nasıl karşılarız?

**Bulgular**
- Sentry ücretsiz planında 10 özel dashboard var. Issue akışı canlı ([pricing](https://sentry.io/pricing/)).
- Firestore aggregation sorguları (`count()`, `sum()`) ucuz. Ücretsiz günlük kota 50k okuma, 20k yazma, 20k silme ve Pasifik saatiyle gece yarısı sıfırlanıyor ([Firestore quotas](https://firebase.google.com/docs/firestore/quotas), 2026-10-21).
- Cloud Monitoring'de Firestore metrikleri var: aktif bağlantı, snapshot listener sayısı, rules değerlendirmelerinin ALLOW/DENY sonucu. Firebase konsolundaki Rules "Monitor" sekmesi de izin/ret sayısını gösteriyor. *(Metrik adlarını bu oturumda tek tek doğrulamadım, güven orta.)*

**Öneri: Yönetici panelinde tek bir "Sağlık" kartı.** Ayrı bir sistem kurmuyoruz.

| Gösterge | Kaynak | Maliyet |
|---|---|---|
| Aktif oyuncu | `players` üzerinde `count()` (`lastSeen > now-2dk`). Admin her 15 sn'de yoklar | ~1 okuma/sorgu |
| Bağlantı hızı | `connections` `count()` farkı / dakika | ~1 okuma/sorgu |
| Reddedilen tarama | İstemci, reddedilen her taramada `players/{uid}.rejected` alanını `increment(1)` ile artırır (kural yalnızca +1'e izin verir). Panel bunu `sum()` ile toplar | 1 yazma/ret |
| Rules DENY | Firebase konsolu > Firestore > Rules > Monitor (ikinci ekranda açık) | 0 |
| Hata sayısı | Sentry Issues akışı (ikinci sekme) ve e-posta alarmı | 0 |

- **Yapılandırılmış log sözleşmesi:**
  - Olay adları `snake_case` ve sabit bir enum'dan gelir (`AppEvent.scanRejected`).
  - Her olayda `surface`, `eventState`, `appVersion`, `uidHash` alanları bulunur.
  - Serbest metin yok. Kullanıcı girdisi loglanmaz.
  - Geliştirmede `package:logging` → console, prod'da → Sentry breadcrumb.
- **KVKK kuralları:**
  - Loglarda görünen ad, ilgi alanı kombinasyonu, QR jetonu ve kısa kod bulunmaz.
  - Sentry projesi **EU veri bölgesinde** açılır. Aydınlatma metnine "hata kayıtları yurt dışındaki hizmet sağlayıcıda (Sentry, Google) tutulur" ifadesi eklenir.
  - Sentry saklama süresi 30 gün. NFR-08'deki "≤ 30 gün" ile uyumlu.
- **Atlanacaklar:** Grafana, Cloud Monitoring dashboard kurulumu, custom metrics, OpenTelemetry.

**Güven:** Orta-yüksek.

**Spike gerekli mi:** Hayır. Rules Monitor sekmesinin gecikmesine prova sırasında bakılır.

---

## 3. Mimari standartlar

**Soru:** Tek uygulama mı, monorepo mu? State management, routing, modeller, hata modeli, katmanlar ve lint seçimleri neler olmalı?

**Bulgular (2026-10-22, pub.dev)**
- `flutter_riverpod 3.4.3` (2026-09-03)
- `flutter_bloc 9.1.1` (~17 ay önce yayımlandı, olgun ve sabit)
- `go_router 18.1.1` (2026-10-20, Flutter ≥ 3.44)
- `freezed 4.0.3` (2026-10-17). Hâlâ build_runner gerektiriyor. Dart 3.13'te primary constructors stable oldu ([freezed](https://pub.dev/packages/freezed)).
- `dart_mappable 4.10.0` (build_runner gerekiyor)
- `very_good_analysis 11.0.0` (Dart ≥ 3.13)
- Pub workspaces Dart ≥ 3.6 ile çalışıyor. Tek lock dosyası, tek çözümleme ([dart.dev](https://dart.dev/tools/pub/workspaces), 2026-05-15).

**Öneri**
- **Tek Flutter uygulaması, üç rota:** `/` (oyuncu), `/screen` (projeksiyon), `/admin`.
  - Projeksiyon ve admin için `deferred as` importları kullanılır. Böylece oyuncu bundle'ı küçük kalır (NFR-02).
  - Pub workspace monorepo'yu **atlıyoruz**. Cloud Functions (varsa) TypeScript olacak, Dart paylaşacak ikinci bir tüketici yok. Saflığı paket sınırıyla değil, klasör kuralıyla sağlıyoruz: `domain/` altında `package:flutter` ve `cloud_firestore` importu yasak. Bu kural CI'da bir grep adımıyla kontrol edilir.
- **State management: Riverpod 3.**
  - Firestore stream'leri doğrudan `StreamProvider` olur.
  - Testte `ProviderContainer(overrides: [...])` ile repository sahtesi takılır. Mock framework gerekmez.
  - `riverpod_generator` kullanılmaz, build_runner'a gerek kalmaz.
  - *İstisna:* Ekip (Q7) bloc'a belirgin şekilde daha hakimse `flutter_bloc` seçilir. Fark, tanıdıklık kadar önemli değil.
  - signals'ı atlıyoruz: ekosistem ve test örnekleri daha zayıf.
- **Routing:** `go_router`. Her yüzeyde bir `redirect` ile oturum ve rol kontrolü yapılır.
- **Modeller:** Elle yazılır.
  - Dart 3.13 primary constructors, `sealed` sınıflar ve elle yazılmış `fromJson`/`toJson` (~6 model: Player, Connection, EventConfig, Question, ScanToken, Badge).
  - `==` gereken yerde `equatable` ya da record kullanılır.
  - Gerekçe: build_runner'ın 3 günde getirdiği sürtünme (watch, conflict, CI süresi) birkaç modelin faydasından büyük. Model sayısı 12'yi aşarsa `dart_mappable`'a geçilir.
- **Hata modeli:** Sınırda `sealed class Result<T>` (`Ok` / `Err`) ve `sealed class GameFailure` kullanılır (`tokenExpired`, `alreadyConnected`, `selfScan`, `notLive`, `rateLimited`, `offline`, `unknown`).
  - Repository, `FirebaseException.code` değerini `GameFailure`'a çevirir.
  - Beklenen hatalar `Result` ile döner, programcı hataları exception olarak global handler'a gider.
  - `fpdart` ya da `dartz` kullanmıyoruz: tip kendimizin, ~25 satır.
- **Katmanlar (feature-first, yalın):** `presentation` → `application` (provider/notifier) → `domain` (saf Dart) ← `data` (Firestore repository).
- **Lint:** `very_good_analysis` (sıfır uyarı NFR-12 ile uyumlu, "kıdemli" görünüm). Yalnızca `public_member_api_docs` kapatılır.

```
lib/
  main.dart                 # Sentry init, ProviderScope, router
  app/                      # router.dart, theme/, env.dart, error_view.dart
  core/
    domain/                 # result.dart, failures.dart, scoring.dart, token.dart, game_state.dart  (saf Dart)
    data/                   # firestore_paths.dart, converters
    observability/          # logger.dart, scrub_pii.dart, app_event.dart
  features/
    join/      {presentation,application,data}
    scan/      {presentation,application,data}
    profile/   ...
    projector/ (deferred)  graph/, leaderboard/
    admin/     (deferred)  state_control/, health/, archive/
  l10n/                     # app_tr.arb, app_en.arb (NFR-13)
test/  (lib ile aynı ağaç)
firestore/  firestore.rules, firestore.indexes.json, rules-tests/ (Node)
tools/  loadtest/ (Node), seed_questions/
```

**Güven:** Yüksek (yapı), orta (Riverpod ve bloc arasındaki seçim Q7'ye bağlı).

**Spike gerekli mi:** Hayır. Day 0'da iskelet ve CI birlikte kurulur.

---

## 4. Test stratejisi (3 güne orantılı)

**Soru:** 3 günde hangi testler yazılmalı, hangileri atlanmalı?

**Bulgular**
- `@firebase/rules-unit-testing 6.0.0` (npm, 2026-10-07) Firestore emulator'a karşı çalışıyor.
- Web'de integration test `flutter drive` + ChromeDriver gerektiriyor. Headless için `-d web-server` kullanılıyor ([Flutter integration tests](https://docs.flutter.dev/testing/integration-tests), 2026-09-29).
- `flutter test --platform chrome` yalnızca web API'sine dokunan birim testleri için gerekli.

**Öneri (önem sırasıyla)**
1. **Security rules testleri (zorunlu, en yüksek değer).** FR-06 ve FR-11 "testle kanıtlı" olmalı. Kapsanacak senaryolar:
   - Kendinle bağlantı reddedilir.
   - İkinci bağlantı reddedilir.
   - `live` dışında yazma reddedilir.
   - Süresi geçmiş jeton reddedilir.
   - Puan serbestçe yazılamaz.
   - `rejected` alanı +1'den fazla artırılamaz.
   - Admin olmayan kullanıcı durum değiştiremez.
   - Archived durumda okuma yapılamaz.

   Araç: Vitest/Mocha + `firebase emulators:exec`. Toplam ~25 test.
2. **Domain birim testleri:** Puanlama (+10, +5 bonus), jeton penceresi (geçerli, önceki pencere, süresi geçmiş), soru seçimi (ikili havuz → genel havuza düşüş), durum makinesi geçişleri ve `FirebaseException` → `GameFailure` eşlemesi. Saf Dart olduğu için hızlı ve kesin.
3. **Widget testleri (4-6 adet):** Katılım formu doğrulaması, tarama sonucu durumları (başarılı / süresi geçmiş / zaten bağlı), kamera reddedilince elle girişe yönlendirme, hata ekranında kurtarma butonu. Repository sahteleri provider override ile verilir.
4. **Golden testleri: atlanıyor.** Font ve platform kaynaklı flakiness, kazandırdığından fazla zaman götürür.
5. **Web integration testleri: CI'da atlanıyor.** Yerine yazılı bir **manuel smoke checklist** var: iOS Safari ve Android Chrome'da katıl → okut → elle kod → yenile → projeksiyon. Zaman kalırsa tek bir `flutter drive -d web-server` happy-path testi yazılır, emulator'a karşı ve yalnızca yerelde.
6. **Coverage hedefi koymuyoruz.** `domain/` için ~%90 doğal olarak çıkar, raporlanır ama kapı yapılmaz.

**Güven:** Yüksek.

**Spike gerekli mi:** Hayır.

---

## 5. Yük ve soak testi (150 istemci)

**Soru:** 150 eşzamanlı oyuncuyu hangi araçla, nerede simüle etmeliyiz, neyi ölçmeliyiz ve kotayı nasıl korumalıyız?

**Bulgular**
- k6 (v2.3.0, 2026-09-21) ve Artillery (2.0.34, 2026-08-14), Firestore'un WebChannel/gRPC dinleyici protokolünü doğal olarak konuşmuyor. Artillery'nin Playwright motoru 150 tarayıcı için fazla ağır.
- `firebase` JS SDK 13.1.0 (npm), Node'da çok sayıda `initializeApp(config, name)` örneğiyle gerçek istemci davranışını (listener + yazma) birebir taklit ediyor.
- Emulator, gecikmeyi ve kotayı temsil etmiyor. Mantık için uygun, performans ölçümü için değil.
- **Auth: IP başına saatte 100 yeni hesap** ([Auth limits](https://firebase.google.com/docs/auth/limits)). Tek makineden 150 anonim girişin bir kısmı reddedilir.

**Öneri**
- **Araç:** `tools/loadtest/` altında bir Node script (firebase JS SDK). k6 ve Artillery'yi atlıyoruz.
  - Kullanıcılar önceden Admin SDK ile oluşturulur ve **custom token** ile giriş yapılır. Böylece anonim sign-up kotası tüketilmez.
  - Her sanal oyuncu kendi `player` dokümanını ve bağlantılarını dinler, 15-60 sn aralıkla rastgele bir hedefi "okutur". Bazı denemeler kasıtlı olarak hatalıdır: süresi geçmiş jeton, tekrar bağlantı.
  - 1 projeksiyon istemcisi tüm grafiği dinler.
- **Ortam:** Önce emulator (kural ve mantık doğruluğu), sonra **staging projesinde** tek bir 10 dakikalık koşu.
- **Ölçülecekler:**
  - Yazma onay gecikmesi (p50 ve p95; hedef ≤ 1 sn, G3)
  - Karşı tarafın görme gecikmesi (yazma zamanı → listener tetiklenme; p95 ≤ 2 sn)
  - Reddedilen yazma sayısı ve nedenleri (beklenenle eşleşmeli)
  - Projeksiyonun 1.500 kenarda fps'i (gözle ve DevTools ile)
  - Toplam okuma/yazma sayısı (konsol Usage sekmesi)
- **Kota hesabı ve kaçınılacaklar:**
  - **Listener fan-out** en büyük kalem. Örneğin 150 oyuncu "ilk 10" sorgusunu dinlerse, her puan değişikliği ~150 okuma eder. 1.500 bağlantıda bu 100k'yı aşan okuma demek ve ücretsiz kotayı (50k/gün) tek koşuda bitirir.
  - **Kural:** Oyuncular global sıralamayı dinlemez. Sıralama yalnızca projeksiyon ve admin'de gösterilir, oyuncu kendi dokümanını dinler.
  - Bu nedenle yük testi staging projesinde yapılır, prod kotasına dokunmaz. Koşu süresi ve sanal oyuncu sayısı script parametresiyle sınırlanır. Staging Blaze ise bütçe alarmı kurulur.

**Güven:** Orta-yüksek.

**Spike gerekli mi:** Evet. Script ~3 saat, koşu 1. günün sonunda yapılmalı ki sonuç mimariyi etkileyebilsin.

---

## 6. CI/CD

**Soru:** GitHub Actions'ta hangi kontroller zorunlu olmalı? Preview kanalları, live deploy ve secret yönetimi nasıl kurulmalı?

**Bulgular**
- `subosito/flutter-action` v2.23.0 (2026-03-25) SDK'yı cache'liyor (`cache: true`).
- `FirebaseExtended/action-hosting-deploy` v0.11.0 (2026-06-25). Bakımı Googler'larda ama "desteklenen ürün değil / Experimental". **Yalnızca service account JSON key** kabul ediyor. Workload Identity Federation isteği hâlâ açık issue ([repo](https://github.com/FirebaseExtended/action-hosting-deploy)). Preview kanalı PR başına otomatik açılıyor, varsayılan süresi 7 gün (`expires`).
- `google-github-actions/auth` v3 WIF destekliyor. `firebase-tools` 15.34.1 bu kimliği (ADC) kullanabiliyor.

**Öneri:** Tek bir workflow, üç job.
```yaml
on: { pull_request: {}, push: { branches: [main] }, workflow_dispatch: {} }
jobs:
  check:   # analyze + test
    steps: [checkout, subosito/flutter-action@v2 (flutter-version: 3.47.7, cache: true),
            "dart format --set-exit-if-changed .", "flutter analyze --fatal-infos",
            "flutter test", "grep: domain/ içinde flutter/firestore importu yok"]
  rules:   # npm ci && firebase emulators:exec --only firestore "npm test"
  deploy:  # needs [check, rules]; build web --release --source-maps --dart-define-from-file=env/staging.json
           # PR → action-hosting-deploy (staging projesi, preview kanalı, expires: 3d)
           # workflow_dispatch(target=prod) → firebase deploy --only hosting + sentry_dart_plugin
```
- **Branch koruması:** `check` ve `rules` zorunlu kontrol (NFR-12).
- **Secrets:** 3 gün için **service account key** pragmatik. Rolü yalnızca *Firebase Hosting Admin* olur, sadece staging ve prod projelerinde bulunur, GitHub Environment `prod` için manuel onay istenir. **Etkinlikten sonra key silinir** (checklist maddesi). WIF daha doğru, ancak action desteklemediği için 3 günde atlanıyor. ADR'ye "bilinçli borç" olarak yazılır.
- **Firestore rules deploy'u:** CI'dan değil, manuel ve tek komutla (`firebase deploy --only firestore:rules`) yapılır. Kural yanlış deploy edilirse etkisi büyük, insan onayı istiyoruz.

**Güven:** Yüksek.

**Spike gerekli mi:** Hayır. Day 0'da yarım günlük iş.

---

## 7. Ortamlar ve konfigürasyon

**Soru:** Kaç Firebase projesi gerekli? Konfigürasyon ve feature flag'ler nasıl yönetilmeli?

**Öneri**
- **Üç ortam, iki gerçek proje:**
  - `dev`: Firebase Emulator Suite, yerelde ve CI'da.
  - `baglanti-agi-staging`: PR preview'ları, yük testi, prova.
  - `baglanti-agi-prod`: Etkinlik günü.

  Tek proje yetmez: preview kanalları ayrı veri tabanına bakmaz, yük testi de prod kotasını yer.
- **Build zamanı konfigürasyonu:** `--dart-define-from-file=env/<env>.json` (3.38'de de var). İçerik: `ENV`, `SENTRY_DSN`, `USE_EMULATOR`, `APP_VERSION`. Firebase web config gizli değildir, `firebase_options_<env>.dart` dosyalarında tutulur.
- **Çalışma zamanı ayarları (NFR-14):** Firestore `events/{eventId}` dokümanındaki `config` alanı (`tokenTtlSec`, `scanRateLimit`, `suspiciousThresholds`, `liveStartsAt/EndsAt`) admin panelinden değişir. Bu ayarlar istemcide zaten dinlenen event dokümanıyla gelir, ek okuma maliyeti yoktur.
- **Remote Config kullanmıyoruz:** ikinci bir kaynak ve gecikmeli fetch demek. Feature flag yok. P1 özellikleri, aynı `config` içinde `features: {badges: true}` alanıyla açılıp kapatılır.

**Güven:** Yüksek.

**Spike gerekli mi:** Hayır.

---

## 8. Etkinlik günü yayın güvenliği

**Soru:** Etkinlik günü sürümleme, geri alma, cache ve dondurma nasıl yönetilmeli?

**Bulgular**
- Hosting'de live kanalı konsoldan "Roll back" ile önceki sürüme döndürülebilir. Preview kanalı `firebase hosting:clone SITE:CHANNEL SITE:live` ile live'a kopyalanabilir ([Manage hosting](https://firebase.google.com/docs/hosting/manage-hosting-resources)).
- **Flutter 3.38.5 varsayılan olarak `offline-first` service worker üretiyor** (`flutter build web --help` çıktısı, yerelde doğrulandı). Bu, eski sürümün telefonlarda takılı kalması demek. Flutter'ın güncel dokümanı (3.47) artık varsayılan olarak service worker üretilmediğini söylüyor ([Web initialization](https://docs.flutter.dev/platform-integration/web/initialization), 2026-09-08; [Web FAQ](https://docs.flutter.dev/platform-integration/web/faq)).

**Öneri**
- **Sürümleme:**
  - `pubspec.yaml` `version: 1.0.0+<build>` biçiminde tutulur. Sentry `release` değeri buradan, `dist` git SHA'sından gelir.
  - Uygulamanın köşesinde küçük bir sürüm etiketi gösterilir (destek sırasında "hangi sürümdesin?" sorusu için).
  - Deploy edilen commit'e `event-2026-10-25` tag'i atılır.
- **Cache:** 3.38'de kalınırsa derleme `--pwa-strategy=none` ile yapılır. `firebase.json` içinde:
  ```json
  "headers": [
    {"source": "/@(index.html|flutter_bootstrap.js|flutter_service_worker.js|version.json|manifest.json)",
     "headers": [{"key": "Cache-Control", "value": "no-cache"}]},
    {"source": "**/*.@(js|wasm|mjs)", "headers": [{"key": "Cache-Control", "value": "public, max-age=3600"}]}
  ]
  ```
  Asset adları içerik hash'i taşımadığı için uzun `immutable` cache **kullanmıyoruz**.
- **Rollback:** Etkinlik sabahı son sürüm önce staging'de bir preview kanalında doğrulanır, sonra `hosting:clone` ile prod'a alınır. Sorun çıkarsa konsoldan Roll back yapılır (~1 dk). Rules için önceki `firestore.rules` dosyası git tag'inde durur.
- **Dondurma checklist'i (etkinlikten T-12 saat önce):**
  1. Kod dondurulur: main'e merge yok, sadece P0 hotfix ve iki kişinin onayı.
  2. Prod'da rules ve indexler deploy edilmiş, `count()` sorgularının indexi hazır.
  3. Auth sign-up kotası (IP başına) etkinlik saatine zamanlanmış şekilde artırılmış ve konsolda görülmüş.
  4. Prova event'i (`eventId=rehearsal`) baştan sona oynanmış, sonra silinmiş. Prod event'i `draft` durumunda.
  5. Sentry alarmı açık, EU projesi, source map'ler bu release için yüklenmiş (tek bir test hatası ile doğrulanmış).
  6. Admin girişi iki cihazda test edilmiş. Projeksiyon laptopu şarjda, ekran uykusu kapalı.
  7. Gizli sekmede iOS Safari ve Android Chrome'da hızlı yükleme testi yapılmış. In-app tarayıcı uyarısı çalışıyor.
  8. Rollback adımları kâğıda yazılmış. Sorumlu kişi belli.
  9. Etkinlik sonrası yapılacaklar: veri arşiv/silme (FR-33), service account key'in silinmesi, Sentry verisinin silinmesi veya 30 gün sonra düşmesi.

**Güven:** Yüksek (rollback, header'lar). Orta (3.47'de service worker'ın tamamen kalktığı; derleme çıktısında kontrol edilmeli).

**Spike gerekli mi:** Küçük bir kontrol. 3.47 ile `flutter build web` çıktısında `flutter_service_worker.js` olup olmadığına ve yeni deploy'un açık bir sekmeye yenilemeyle geldiğine bakılır (15 dk).

---

## Özet karar önerileri

1. **Flutter 3.47.7'ye Day 0'da geçilir**, sürüm CI ve `.fvmrc`/README'de sabitlenir. 3.38.5 güncel paketleri kuramıyor. Geçilemezse paketlerin eski majörleri bilinçli olarak pinlenir.
2. **Hata raporlama:** Sentry (`sentry_flutter` 10.x, EU bölgesi, `sendDefaultPii=false`, `beforeSend` ile PII temizliği, hash'lenmiş uid) + dart2js source map'leri. Crashlytics web'de yok.
3. **İzleme:** Admin panelinde bir "Sağlık" kartı (`count()`/`sum()` sorguları) + Sentry Issues + Firestore Rules Monitor. Ek altyapı kurulmuyor.
4. **Mimari:** Tek uygulama, üç rota, admin ve projeksiyon için deferred import. Riverpod 3 (codegen'siz), go_router, elle yazılmış modeller ve `sealed Result/GameFailure`. Feature-first klasör yapısı, saf `domain/`. Lint: `very_good_analysis`.
5. **Test:** Önce rules testleri, sonra domain birim testleri, sonra 4-6 widget testi. Golden ve CI'da web integration testi yok, yerine manuel smoke checklist.
6. **Yük testi:** Node + Firebase JS SDK, custom token ile 150 sanal oyuncu, staging projesinde 10 dakika. Oyuncular global sıralamayı dinlemez.
7. **CI/CD:** Tek workflow (check, rules, deploy). PR'lar staging preview kanalına gider. Prod'a deploy manuel, onaylı ve `hosting:clone` ile yapılır. SA key etkinlikten sonra silinir. WIF bilinçli borç olarak kalır.
8. **Ortamlar:** Emulator + staging + prod. `--dart-define-from-file`. Çalışma zamanı ayarları Firestore event `config` dokümanında, Remote Config yok.
9. **Yayın:** `no-cache` header'ları, service worker kapalı (3.38'de kalınırsa `--pwa-strategy=none`), konsoldan rollback, T-12 saat dondurma checklist'i.

## Riskler

| Risk | Olasılık / Etki | Azaltma |
|---|---|---|
| **Auth IP başına 100 hesap/saat** sınırı: salon NAT'ı ve mobil CGNAT yüzünden katılımlar reddedilir | Yüksek / Oyunu durdurur | **Bugün** konsoldan sign-up kotası için zamanlanmış geçici artış istenir. Firebase "özel durumlar için 2 hafta önceden destekle görüşün" diyor, yani süre dar. Yedek plan: oyuncu kimliği için Cloud Function'ın verdiği custom token (Blaze gerekir, Q1) veya katılımın Wi-Fi ile mobil veriye yayılması. **R2/backend araştırmasıyla birlikte hemen karara bağlanmalı.** |
| Sentry'nin wasm'da sembolize etmemesi veya uyumsuz olması | Orta / Hatalar okunamaz | dart2js ile derlenir, spike yapılır |
| Listener fan-out'un ücretsiz kotayı bitirmesi | Orta / Yazmalar reddedilir | Oyuncu global sorgu dinlemez. Yük testinde okuma sayısı ölçülür. Blaze olursa bütçe alarmı kurulur |
| Eski service worker / cache yüzünden telefonların eski sürümde kalması | Orta / Hotfix ulaşmaz | `no-cache` header'ları, `--pwa-strategy=none`, etkinlik sabahından sonra deploy yok |
| `firebase_core 5.0.0` / `cloud_firestore 7.0.0` majörlerinin çok yeni olması (2026-10-15) | Düşük-orta / Web'de regresyon | Day 0'da smoke test. Sorun çıkarsa bir önceki majör pinlenir |
| Flutter 3.47 geçişinin ekipte zaman kaybettirmesi | Düşük / Yarım gün | Herkes aynı gün kurar. CI sürümü tek kaynaktan alır |
| `action-hosting-deploy`'un "experimental" olması | Düşük / Preview deploy kırılır | Yedek: CLI ile `firebase hosting:channel:deploy` |
