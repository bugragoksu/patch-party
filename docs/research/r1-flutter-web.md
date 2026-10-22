# R1: Flutter web ile Bağlantı Ağı, nasıl iyi yapılır ve riskler

- **Tarih:** 2026-10-22
- **Kapsam:** Derleme hedefi, ilk yükleme, kamera ile QR okuma, QR çizimi, Rive, projeksiyon grafiği, uygulama içi tarayıcılar, etkinlik tuzakları
- **Yöntem:** Resmî dokümanlar, pub.dev, GitHub issue'ları, paket kaynak kodu (mobile_scanner 7.4.2, rive_native 0.1.11) ve yerelde Flutter 3.38.5 ile derlenmiş hello-world üzerinde ölçüm. "Ölçtük" yazan sayılar bize ait, brotli `-q 11` ve gzip `-9` ile.

## 0. Flutter sürüm durumu

- Güncel stable: **3.47.7** (2026-10-08, Dart 3.13.5). Beta: 3.50.0-0.1.pre (2026-10-14). Yereldeki 3.38.5 (2025-12-12); 3.38 hattının son hotfix'i **3.38.10** (2026-02-11). Kaynak: [releases_macos.json](https://storage.googleapis.com/flutter_infra_release/releases/releases_macos.json) (2026-10-22'de okundu).
- 3.41 → 3.47 arası web için önemli değişiklikler: HTML renderer'ın kalan izleri kaldırıldı, font fallback servisi yenilendi, `autocapitalize` text input'a uygulandı, iOS Chrome autofill düzeltmesi ([3.47.0 release notes](https://docs.flutter.dev/release/release-notes/release-notes-3.47.0), 2026-08-12). Wasm hâlâ opt-in. Wasm için deferred loading deneysel ve 3.50'de bekleniyor ([Wasm dokümanı](https://docs.flutter.dev/platform-integration/web/wasm), 2026-08-18). 3.47'de `material_ui`/`cupertino_ui` ayrı paketler oldu (opt-in, `dart fix` ile göç) ([3.47 blog](https://flutter.dev/blog/whats-new-in-flutter-3-47), 2026-08).
- **Kritik bulgu:** mobile_scanner [#1655](https://github.com/juliansteenbakker/mobile_scanner/issues/1655) (2026-02, açık): iOS Safari'de kamera önizlemesi Flutter **3.42.0**'da yarı veya tamamen siyah, 3.38.10'da sorunsuz. Platform view (HtmlElementView) bileşimiyle ilgili bir motor regresyonu gibi duruyor.
- **Öneri:** Etkinlik için **3.38.10**'a geç (3.38.5'ten hotfix, risksiz). 3.47.7'ye geçmeyi ancak iPhone kamera spike'ı orada da temiz geçerse düşün. 3 günlük teslimde SDK göçü kazanç getirmez. **Güven:** orta.

---

## 1. Derleme hedefi: dart2js + CanvasKit mı, `--wasm` (skwasm) mı?

**Soru:** Hangi derleme hedefini telefonlara göndermeliyiz? HTML renderer hâlâ var mı?

**Bulgular**
- HTML renderer kaldırıldı. 3.47'de kalan referanslar da temizlendi ([3.47.0 notes](https://docs.flutter.dev/release/release-notes/release-notes-3.47.0)). Seçenekler artık CanvasKit (dart2js) ve skwasm (dart2wasm).
- `flutter build web --wasm` **iki çıktı birden** üretir. 3.38.5 ile ürettiğimiz `flutter_bootstrap.js` içinde `builds: [{dart2wasm, skwasm}, {dart2js, canvaskit}]` var. Loader'da tarayıcı allowlist'i `blink:true, gecko:false, webkit:false` (ölçtük). Sonuç olarak skwasm yalnızca Chromium tabanlı tarayıcılarda (Android Chrome dahil) çalışır. Safari, tüm iOS tarayıcıları ve Firefox otomatik olarak JS + CanvasKit'e düşer ([startdebugging, 2026-09-17](https://startdebugging.net/2026/09/canvaskit-vs-skwasm-for-flutter-web-in-2026/)).
- iOS: Safari 18.2'den beri WasmGC var, ama Flutter/Wasm [WebKit bug 267291](https://bugs.webkit.org/show_bug.cgi?id=267291) yüzünden çalışmıyor. iOS'taki bütün tarayıcılar WebKit kullanmak zorunda olduğundan **hiçbir iOS tarayıcısı Wasm yolunu kullanmaz** ([Flutter Wasm docs](https://docs.flutter.dev/platform-integration/web/wasm), 2026-08-18).
- skwasm, CanvasKit'ten hem küçük hem hızlı: ilk frame yaklaşık 90 ms daha erken, ağır sahnede yaklaşık %36 daha fazla fps. Ancak 3.47.x'te çok iş parçacıklı skwasm takılıyor. `forceSingleThreadedSkwasm: true` önerilmiş ([startdebugging](https://startdebugging.net/2026/09/canvaskit-vs-skwasm-for-flutter-web-in-2026/), flutter#190039). COOP/COEP başlıkları yoksa skwasm zaten tek iş parçacığında çalışır.
- Wasm derlemesi `dart:html` ve `package:js` kabul etmez. `package:web` ile `dart:js_interop` gerekir.
- Rive ile çakışma var (bkz. §5): [rive-flutter#593](https://github.com/rive-app/rive-flutter/issues/593) (açık, 2025-12) raporuna göre `--wasm` altında ViewModel ve StateMachine input API'leri `JavaScriptError` atıyor.

**Öneri**
- Varsayılan: `flutter build web --release --wasm`, COOP/COEP başlıkları **olmadan**. Böylece skwasm tek iş parçacığında çalışır ve `credentialless` başlığı Firebase/Rive CDN isteklerini bozmaz. Android Chrome skwasm, iPhone CanvasKit alır.
- **Koşul:** Rive data binding `--wasm` altında spike'ta çalışmazsa, düz `flutter build web` (dart2js + CanvasKit) gönder. Fark Android'de yaklaşık 0.4 MB ve biraz frame süresi, kabul edilebilir.
- NFR-10 taban sürümleri: iOS Safari 17+ (yani iOS 17, 18 ve 26) ile Android Chrome'un son iki ana sürümü. CanvasKit WebGL2 istiyor. Bütün bu sürümlerde var.

**Güven:** yüksek (tarayıcı yönlendirmesi kaynak koddan doğrulandı), orta (Rive etkileşimi).
**Spike:** Aynı build'i Android Chrome'da (`const bool.fromEnvironment('dart.tool.dart2wasm')` ile hangi yolda olduğunu logla) ve iPhone Safari'de aç. Rive data binding ile QR ekranını iki yolda da çalıştır.

---

## 2. İlk yükleme boyutu ve süresi

**Soru:** Gerçekçi aktarım boyutu nedir, etkileşime geçme süresi nasıl kısalır, NFR-02 için bayt bütçesi ne olmalı?

**Bulgular (ölçtük: Flutter 3.38.5, varsayılan sayaç uygulaması, `--wasm`)**

| Dosya | Ham | brotli | gzip |
|---|---|---|---|
| `main.dart.js` (iOS yolu) | 1.68 MB | **387 KB** | 492 KB |
| `main.dart.wasm` + `.mjs` (Android yolu) | 1.43 MB | **411 KB** | 517 KB |
| `canvaskit/canvaskit.wasm` (tam, Safari) | 7.08 MB | **2.21 MB** | 2.85 MB |
| `canvaskit/chromium/canvaskit.wasm` | 5.71 MB | 1.62 MB | 2.16 MB |
| `canvaskit/skwasm.wasm` | 3.55 MB | **1.19 MB** | 1.51 MB |
| `MaterialIcons` (tree-shaken, 1.6 MB'tan) | 7.7 KB | 3 KB | 4 KB |
| Rive `rive_native.wasm` 44.0.0 + js | 2.86 MB | **~815 KB** | ~1.1 MB |
| zxing-wasm reader 3.1.3 (yalnızca iOS'ta okuma için) | 1.09 MB | 357 KB | 456 KB |

- Firebase Hosting `.wasm` ve `.js` dosyalarını otomatik brotli ile sunuyor. `dartpad.dev` üzerinde `content-encoding: br` ve `application/wasm` gördük (2026-10-22). Duyuru: [Firebase blog, 2020-08](https://firebase.blog/posts/2020/08/firebase-hosting-new-features). Elle `.br` dosyası koymaya gerek yok.
- CanvasKit varsayılan olarak `www.gstatic.com/flutter-canvaskit/<engineRevision>/` adresinden geliyor (brotli, 1 yıl cache). Tarayıcılar HTTP cache'i siteye göre bölümlediği için "başka siteden cache'te vardır" avantajı yok. Yalnızca ek bir DNS + TLS bağlantısı maliyeti getiriyor. `--no-web-resources-cdn` bayrağı motoru kendi origin'imizden sunar.
- Service worker: Flutter artık varsayılan olarak service worker üretmiyor ([initialization docs](https://docs.flutter.dev/platform-integration/web/initialization)). Bu iyi bir şey, çünkü bayat build riski yok.
- Wasm'da deferred import şu an bölünmüyor (3.50'de deneysel). dart2js'te `deferred as` çalışıyor.
- Font: CanvasKit'te uygulamada olmayan glifler `fonts.gstatic.com` adresinden fallback olarak indirilir. Renkli emoji fontu çok büyük ([flutter#119536](https://github.com/flutter/flutter/issues/119536)'da yaklaşık 24 MB deniyor, monokrom Noto Emoji varsayılan). **Kullanıcı adlarında emoji** fallback indirmesini tetikler.

**Öneri: bayt bütçesi (NFR-02, kritik yol, brotli)**

| Yol | Bütçe | İçerik |
|---|---|---|
| Android Chrome (skwasm) | **≤ 1.9 MB** | skwasm 1.19 + app wasm ≤ 0.55 + font ≤ 0.08 + diğer ≤ 0.05 |
| iOS Safari (CanvasKit) | **≤ 2.9 MB** | canvaskit 2.21 + main.dart.js ≤ 0.55 + font ≤ 0.08 + diğer |
| Etkileşimden sonra (lazy) | ≤ 1.2 MB | Rive wasm (~0.8) + .riv dosyaları (≤ 0.15) + zxing (iOS, ~0.36) |

Hesap: 4G'de kalabalık salon için 6–8 Mbps efektif hız varsayıldı. 1.9 MB yaklaşık 2–2.5 sn, wasm derleme ve ilk frame için yaklaşık 0.5–1 sn ekleniyor. Android'de p75 4 sn tutar. iPhone'lar genelde daha güçlü CPU ile bunu telafi eder, yine de iOS yolunda pay daha az.

Teknikler, öncelik sırasıyla:
1. **Rive'ı kritik yoldan çıkar.** `RiveNative.init()` çağrısını ilk frame'den sonra yap (rive_native wasm'ı runtime'da `<script>` ile yüklüyor) ve katılım formunu Rive olmadan çiz. Rive yüklenmeden animasyon yerine statik görsel göster.
2. `--no-web-resources-cdn` ile her şeyi tek origin'den (Firebase) sun. Rive için `--dart-define=RIVE_NATIVE_WASM_HOST=/rive/` kullan ve `@rive-app/flutter-native-wasm@44.0.0/wasm/*` dosyalarını `web/rive/` altına kopyala (rive_native 0.1.11 kaynağında `wasmVersion = '44.0.0'`, `_wasmHost()` bu define'ı okuyor; doğrulandı).
3. Tek, alt kümelenmiş font: Latin + Latin Extended (Türkçe için ğ, ş, ı, İ), 2 ağırlık, `.ttf` olarak yaklaşık 40–80 KB. Material Icons tree-shaking release'te varsayılan olarak açık. `cupertino_icons` kullanılmıyorsa kaldır.
4. `index.html` içinde saf HTML/CSS açılış ekranı: logo + "Yükleniyor…" + aşama metni (`onEntrypointLoaded` → `initializeEngine` → `runApp`), ilk frame'de kaldırılır ([initialization docs](https://docs.flutter.dev/platform-integration/web/initialization)). Beyaz ekran görünmez ve ağ yavaşken insanlar sayfayı kapatmaz.
5. Cache başlıkları: `index.html` ve `flutter_bootstrap.js` için `no-cache`, `canvaskit/**` ve `*.wasm` için kısa ama uzun ömürlü cache (dosya adları hash'li değil, bu yüzden 1 saat + ETag). Etkinlik sırasında deploy yok (NFR-14), dolayısıyla risk düşük.
6. `<link rel="preconnect">` gerekmez (tek origin). Motor dosyası tarayıcıya göre değiştiği için koşulsuz `preload` kullanma, yanlış dosya iki kez iner.
7. dart2js tarafında `-O4` (varsayılan release `-O2`/`-O4`; ölçüp karar ver). Admin ve projeksiyon ekranlarını `deferred as` ile ayır. Bu yalnızca iOS yolunda kazanç getirir.

Operasyonel öneri: 150 telefon × 2.5 MB = yaklaşık 375 MB. Salon Wi-Fi'ı 50 Mbps ise toplu yükleme yaklaşık 1 dakika sürer. Linki konuşmanın başında paylaş ve "mobil veriyle açın" de.

**Güven:** yüksek (boyutlar ölçüldü), orta (süre tahmini).
**Spike:** Firebase'e boş iskelet deploy et. Chrome DevTools'ta "Fast 4G" + 4x CPU yavaşlatmayla ve gerçek bir orta segment Android'de (ör. Galaxy A-serisi) TTI ölç. iPhone'da Web Inspector ile toplam transferi kontrol et.

---

## 3. Kamerayla QR okuma

**Soru:** `mobile_scanner` web'de güvenilir mi, iOS tuzakları neler, alternatifler neler?

**Bulgular**
- `mobile_scanner` **7.4.2** (2026-09-10). Web arka uçları: `auto` (BarcodeDetector varsa onu, yoksa zxing-wasm), `barcodeDetector`, `zxingWasm`, `zxingJs` ([changelog](https://pub.dev/packages/mobile_scanner/changelog)).
- **Runtime'da CDN'den script yüklüyor** (kaynak kodda doğrulandı): zxing-wasm JS `https://cdn.jsdelivr.net/npm/zxing-wasm@3.1.3/dist/iife/reader/index.js`, wasm binary ise ayrıca `fastly.jsdelivr.net` üzerinden geliyor. `setBarcodeLibraryScriptUrl` yalnızca JS URL'ini değiştiriyor, wasm `locateFile` override'ı yok. zxing-js ise `unpkg.com` üzerinden geliyor. Sonuç olarak CSP ve offline için üçüncü taraf bağımlılık var.
- **BarcodeDetector iOS Safari'de yok:** 17.0–26.x arasında varsayılan olarak kapalı (yalnızca flag ile) ([caniuse](https://caniuse.com/mdn-api_barcodedetector_detect), [WebKit 281848](https://bugs.webkit.org/show_bug.cgi?id=281848)). README'deki "Safari 17+" ifadesi yanıltıcı. iPhone'da `auto` her zaman zxing-wasm'a düşer. Android Chrome'da BarcodeDetector var.
- **Engelleyici hata:** [mobile_scanner#1785](https://github.com/juliansteenbakker/mobile_scanner/issues/1785) (2026-09-01, açık, PR yok). `<video>` elemanında `playsinline` ve `muted` yok, bu yüzden iOS'ta önizleme yerel tam ekran oynatıcıya atlıyor ve siyah görünüyor. Kaynakta doğruladık: 7.4.2'de `playsInline` hiç geçmiyor. Video DOM'a eklenmeden `play()` çağrıldığı için dışarıdan MutationObserver ile düzeltilemiyor. Ek olarak #1655 (Flutter ≥ 3.42'de Safari'de siyah yarım önizleme).
- iOS genel kurallar: HTTPS şart (Firebase tamam). İzin, kullanıcı hareketinden sonra `getUserMedia` ile istenir. Arka kamera `facingMode: 'environment'` ile seçilir. iOS her sayfa yüklemesinde izni tekrar sorabilir. Uygulama içi WKWebView'lerde getUserMedia ancak host uygulamanın kamera izni varsa çalışır ([WebKit blog](https://webkit.org/blog/11353/mediarecorder-api/)).

**Öneri: kendi ince tarayıcı katmanımızı yazalım**
- Kamerayı **Flutter canvas'ının dışında**, `position:fixed` bir `<video playsinline muted autoplay>` elemanında göster. JS interop ile oluşturulur, Flutter UI'ı üstte şeffaf bir tarama çerçevesi çizer. Böylece platform view regresyonları (#1655) ve `playsinline` hatası (#1785) tamamen devre dışı kalır. Yaklaşık 150 satırlık bir `package:web` katmanı yeterli.
- Çözücü:
  - `'BarcodeDetector' in window` doğruysa (Android Chrome) yerel API'yi kullan. Ek indirme yok ve en hızlısı.
  - Değilse (iOS) **zxing-wasm reader 3.1.3**'ü self-host et: `prepareZXingModule({ overrides: { locateFile } })` ile wasm'ı `/zxing/` altından al (yaklaşık 357 KB br). Okuma ekranı açılınca önden yükle.
  - Kareleri yaklaşık 150–200 ms aralıkla, merkezdeki ~640 px kırpılmış bölgeden çöz. Aynı jetonu 2 sn içinde tekrar gönderme.
- Fallback: izin reddi, hata veya 10 sn içinde okunamama durumunda doğrudan FR-05 kısa kod girişi. Bu her zaman bir dokunuş uzakta olmalı.
- Plan B (zaman yetmezse): `mobile_scanner`'ı `dependency_overrides` ile git fork'una yönlendir ve `..playsInline = true ..muted = true` iki satırını ekle. Yine de 3.38.10'da kal.

**Güven:** yüksek (sorun kaynakta doğrulandı), orta (kendi katmanımızın iOS davranışı).
**Spike (en yüksek öncelik):** iPhone (iOS 18 ve 26) Safari + Chrome, bir Android Chrome ve Instagram in-app'te yaklaşık 3 cm boyundaki dönen QR'ı 30–50 cm'den okut. Okuma süresi ve kare başına CPU ölç. İzin reddi akışını da test et.

---

## 4. QR çizimi

**Bulgular:** `qr_flutter` 4.1.0 (2023-05-14, verified publisher, 2.3k beğeni). Eski ama kararlı. `CustomPainter` tabanlı, web'de sorunsuz. Altındaki `qr` paketi 4.0.0 (2026-05). Alternatif olarak `qr` ile kendi `CustomPainter`'ımızı yazmak yaklaşık 40 satır.

**Öneri:** `qr_flutter` kullan. Hata düzeltme seviyesi `M`, quiet zone 4 modül, en az ~240 px ve beyaz zemin üzerine siyah (karanlık temada da) çiz. Jeton kısa tutulursa (ör. 12–16 karakter) QR sürümü küçük kalır ve okuma kolaylaşır. Projeksiyondaki büyük katılım QR'ı (FR-22) için aynı widget `RepaintBoundary` içinde kullanılabilir.
**Güven:** yüksek. **Spike:** Yok, §3 spike'ı bunu da kapsıyor.

---

## 5. Rive

**Soru:** Güncel runtime ne, web'de maliyeti ve riskleri ne, rozet ve kutlama için uygun mu?

**Bulgular**
- `rive` **0.14.11** (2026-08-03), yanında `rive_native` 0.1.11. 0.14 ile Dart runtime tamamen bırakıldı ve C++ runtime'a geçildi. `RiveNative.init()` zorunlu ([changelog](https://pub.dev/packages/rive/changelog), [migration](https://dev.to/uianimation/migrating-to-rive-flutter-0140-5d74)). 0.15.0-dev sürümü var, kullanma.
- Web'de wasm varsayılan olarak `cdn.jsdelivr.net/npm/@rive-app/flutter-native-wasm@44.0.0/` adresinden yükleniyor. `RIVE_NATIVE_WASM_HOST` define'ı ile self-host edilebiliyor (kaynakta doğruladık). Ek indirme yaklaşık **815 KB brotli** (ölçtük).
- State machine ve data binding (`DataBind.auto/byName`, ViewModel) destekleniyor ([Rive Flutter docs](https://rive.app/docs/runtimes/flutter/flutter)).
- İki renderer var. `Factory.rive` her widget için ayrı bir WebGL context açıyor ve tarayıcı sınırı yaklaşık 16. Çok widget varsa `RivePanel` ile paylaşılan texture kullanılmalı. `Factory.flutter` Flutter canvas'ına çizer ve context açmaz.
- Açık web sorunları ([rive-flutter issues](https://github.com/rive-app/rive-flutter/issues), 2026-10):
  - #593: `--wasm`'da ViewModel/input API'leri `JavaScriptError` atıyor (0.14.0'da raporlandı, yanıt yok).
  - #638: `Factory.rive` ile çok sayıda animasyon web'de boş görünüyor, `Factory.flutter` ile görünmüyor.
  - #628: Döngüdeki animasyonda bellek büyümesi.
  - #615: Yükleme bitmeden dispose edilince `file_loader.dart:91` null hatası (tüm platformlar).
  - #664: `advanceAndApply` hiç durmuyor, sürekli 60 fps çiziyor.

**Öneri**
- Uygun: "bağlantı kuruldu" kutlaması (tek, kısa, tam ekran overlay) ve rozet açılışı. **Hover/tilt** telefonda yok. Bunun yerine sürükleme ile eğme (pointer → data binding ile `tiltX/tiltY`) kullan. DeviceOrientation iOS'ta ayrı izin istediği için kullanma.
- Kurallar:
  - Ekranda aynı anda en fazla 2–3 Rive widget olsun ve `Factory.flutter` kullanılsın. `Factory.rive` yalnızca tek tam ekran kutlamada ve gerekirse.
  - Animasyon bitince widget'ı ağaçtan kaldır (#628, #664).
  - Yüklemeyi bir servis üzerinden tek sefer yap ve `File` nesnesini cache'le (#615'ten kaçınmak için widget içinde yükleme yapma).
  - `prefers-reduced-motion` açıksa animasyonu doğrudan son kareye atla (NFR-11).
- Hafif UI hareketleri (buton basma, liste girişi) için Rive değil, Flutter implicit animasyonları kullan. Daha ucuz ve daha az riskli.
- Rive P1 (FR-12). Rive yüklenemezse oyun aynen devam etmeli, yerine statik rozet görseli gösterilmeli.

**Güven:** orta.
**Spike:** Tek bir `.riv` (bir state machine, bir ViewModel ile `tilt` ve `trigger`) dosyasını Android Chrome'da `--wasm` ile ve iPhone'da dart2js ile çalıştır. Kutlamayı 20 kez art arda tetikle, bellek ve context logunu (`RiveNative.debugRenderTextureLogging`) izle.

---

## 6. Projeksiyon grafiği (150 düğüm, 1.500 kenar, ≥ 30 fps)

**Bulgular**
- `graphview` 1.5.1 (2025-10-17): Fruchterman-Reingold var, ancak dokümanı "küçük grafiklerde mükemmel" diyor. Düğümler widget olduğu için 1.500 kenarda pahalı.
- `flutter_force_directed_graph` 1.0.8 (2025-09-11): dinamik ekleme var, 20 beğeni, benchmark yok.
- `force_graph`: Forge2D tabanlı, doğrulanmamış yayıncı.
- Hesap: 150 düğümde naif O(n²) itme kuvveti tick başına 11.175 çift eder. Buna 1.500 yay kuvveti eklenince JS'te bile < 1 ms tutar. Barnes-Hut veya worker gerekmez. Çizim tek bir `Path` (bütün kenarlar) ve düğümler için `drawCircle` ya da `drawRawAtlas` ile iki üç draw call. skwasm ve CanvasKit bunu rahatça 60 fps çizer.
- Web'de `Isolate` gerçek iş parçacığı değil (`compute` web'de ana thread'de çalışır). Worker ancak ayrı JS dosyasıyla mümkün, burada gereksiz.

**Öneri:** Özel `CustomPainter` + `Ticker` + basit kuvvet simülasyonu (Verlet, alpha soğuması, yeni kenar gelince alpha'yı ısıt).
- Yeni düğüm, bağlı olduğu düğümün yanında doğar.
- Kenarlar `ValueNotifier` ile repaint edilir, `setState` ağacı kullanılmaz.
- İsim etiketleri yalnızca ilk 10 ve son bağlanan için `TextPainter` cache'iyle çizilir. 150 etiketin her karede yeniden layout'u en pahalı kalem olur.
- Projeksiyon dizüstünde Chrome ile `--wasm` (skwasm) yolunu kullan.

**Güven:** yüksek.
**Spike:** Sentetik veriyle 150/1.500'ü saniyede 5 kenar ekleyerek koş. Projeksiyon dizüstünde DevTools performans kaydı ile fps ≥ 30 ve frame build+raster < 16 ms olmalı.

---

## 7. Uygulama içi tarayıcı tespiti

**Bulgular**
- Tespit UA ile yapılıyor: Instagram `Instagram \d+`, Facebook `FBAN|FBAV|FB_IAB`, LinkedIn `LinkedInApp`, WhatsApp `WhatsApp` ([inapp-spy README](https://cdn.jsdelivr.net/npm/inapp-spy@5.0.10/README.md), [u2l.ai](https://u2l.ai/blog/instagram-in-app-browser)). %100 doğru değil.
- WhatsApp iOS'ta bazı linkleri uygulama içinde açmaya başladı. Genel in-app tarayıcı 2026-10'da hâlâ beta ([WABetaInfo](https://wabetainfo.com/whatsapp-is-testing-an-in-app-browser-for-chats-on-ios/)). Android'de WhatsApp linkleri normalde Chrome Custom Tabs ile açar (gerçek Chrome, kamera çalışır; yaygın davranış, kaynakla doğrulanmadı).
- Dışarı kaçış:
  - Android: `intent://host/path#Intent;scheme=https;package=com.android.chrome;end` çoğu WebView'de Chrome'u açar.
  - iOS: `x-safari-https://` şeması bazı uygulamalarda çalışıyor, garantisi yok ([Textpattern forum](https://forum.textpattern.com/viewtopic.php?id=52541)).

**Öneri:** Tespiti `index.html` içinde Flutter yüklenmeden önce yapan küçük bir inline script yaz (2 KB). In-app tespit edilirse üstte bir şerit göster: "En iyi deneyim için Chrome/Safari'de aç". Android'de `intent://` butonu, iOS'ta "Linki kopyala" + "••• → Safari'de aç" görseli. **Engelleme yapma**, oyun devam edebilsin (FR-05 kısa kod her yerde çalışır). Tespit sonucunu NFR-05 hata bağlamına ekle. Katılım QR'ı kamera uygulamasıyla açılacağı için çoğu kişi zaten Safari/Chrome'a düşer, ana risk WhatsApp/Instagram ile paylaşılan link.
**Güven:** orta. **Spike:** Linki Instagram DM ve WhatsApp üzerinden iPhone ve Android'de aç. Kamera izni ve `intent://` davranışını not et.

---

## 8. Etkinliğe özel Flutter web tuzakları

- **Metin girişi ve klavye:** Flutter web gizli bir `<input>` ile çalışır. iOS'ta klavye içeriği iter ve görsel viewport küçülür, layout viewport küçülmez ([flutter#110284](https://github.com/flutter/flutter/issues/110284), [WebKit tartışması](https://lists.w3.org/Archives/Public/public-webapps-github/2020Aug/0443.html)). Katılım formunu tek ekranda kısa tut ve `Scaffold.resizeToAvoidBottomInset` ile kaydırılabilir yap. İsim alanında `autocorrect: false` ve `textCapitalization.words` kullan (3.47'de `autocapitalize` web'e geldi, 3.38'de etkisi olmayabilir). Türkçe karakter girişini (ğ, ş, İ) ve tahmin çubuğunu gerçek cihazda test et.
- **Emoji ve özel karakter:** İsimlerde emoji fallback font indirmesini tetikler. İsmi `[\p{L}\p{N} .'-]` ile sınırla. Bu NFR-08 için de iyi.
- **Yenileme ve oturum:** `localStorage` + Firebase anonim auth (FR-02). iOS özel sekmede `localStorage` çalışır ama sekme kapanınca silinir, kısa kod ile geri dönüş akışı düşün.
- **URL stratejisi:** Hash (`/#/`) en güvenlisi, ek ayar istemez. Path URL kullanılırsa Firebase `rewrites: ** → /index.html` şart. Katılım linki kısa ve büyük harfsiz olsun (`/j` gibi). Derin link gerekmez.
- **Arka plan ve ekran kilidi:** Telefon kilitlenince ya da sekme arka plana gidince WebGL context kaybolabilir ve Firestore dinleyicileri durur. `visibilitychange` olayında QR jetonunu ve dinleyicileri yenile. QR ekranında Screen Wake Lock API kullan (iOS 16.4+ ve Chrome destekliyor), desteklenmiyorsa sessizce geç.
- **Düşük bellekli Android:** CanvasKit/skwasm + Rive + kamera aynı anda yaklaşık 300–400 MB tutabilir. Okuma ekranında Rive'ı dispose et ve okuma bitince kamera track'lerini `stop()` et. WebGL context sınırına (~16) dikkat.
- **Erişilebilirlik:** Flutter web semantics varsayılan olarak kapalı. Gerekirse `SemanticsBinding.instance.ensureSemantics()` ile aç (maliyetli). Metin ölçekleme için `MediaQuery.textScaler` ile tasarımı 1.3x'te test et.
- **Hata bağlamı:** `FlutterError.onError` ve `PlatformDispatcher.onError` yanında `index.html`'de `window.onerror` kullan; yükleme hataları Flutter başlamadan olur. `--source-maps` ile build alıp source map'leri yalnızca hata servisine yükle.
- **Önbellek ve deploy:** Service worker yok. Etkinlik sabahı son deploy'dan sonra hiç deploy yapma. Bayat `index.html` riskine karşı `no-cache`.

---

## Özet karar önerileri

1. Flutter **3.38.10** stable'da kal (3.47.7'ye yalnızca iPhone kamera spike'ı geçerse geç).
2. `flutter build web --release --wasm` kullan, COOP/COEP koyma. Android'e skwasm, iOS'a CanvasKit gider. Rive data binding wasm'da çalışmazsa dart2js'e dön.
3. Her şeyi Firebase Hosting'den sun: `--no-web-resources-cdn`, Rive için `RIVE_NATIVE_WASM_HOST`, zxing-wasm self-host. Brotli otomatik geliyor.
4. Bütçe (brotli, kritik yol): Android ≤ 1.9 MB, iOS ≤ 2.9 MB. Rive ve zxing ilk frame'den sonra yüklensin.
5. Saf HTML açılış ekranı + in-app tarayıcı şeridi `index.html` içinde, Flutter'dan önce.
6. QR okuma için `mobile_scanner` kullanma. Flutter dışında `<video playsinline muted>` + BarcodeDetector (Android) / self-host zxing-wasm (iOS) katmanı yaz. Plan B: `playsInline` yamalı fork.
7. QR çizimi `qr_flutter` 4.1.0 ile. Kısa jeton, EC seviyesi M.
8. Rive 0.14.11'i yalnızca kutlama ve rozet için kullan, `Factory.flutter`, aynı anda ≤ 3 widget. Hafif hareket Flutter animasyonlarıyla.
9. Projeksiyon için özel `CustomPainter` + O(n²) kuvvet simülasyonu, paket yok.
10. Kısa kod girişi (FR-05) her ekranda bir dokunuşla erişilebilir olsun. Kamera ile ilgili her sorunun sigortası bu.

## Riskler

| Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|
| iPhone'da kamera önizlemesi siyah/tam ekran (mobile_scanner #1785, #1655) | Yüksek (paket kullanılırsa) | Yüksek | Kendi video katmanı, 3.38.10, FR-05 |
| Rive API'leri `--wasm`'da hata (#593) | Orta | Orta | Spike; olmazsa dart2js build ya da Rive'sız statik rozet |
| Salon ağı + 4G'de ilk yükleme > 4 sn | Orta | Yüksek | Bütçe, lazy Rive, açılış ekranı, mobil veri anonsu |
| Üçüncü taraf CDN (jsDelivr, gstatic) erişilemez veya yavaş | Düşük | Yüksek | Tümünü self-host |
| In-app tarayıcıda kamera yok | Orta | Orta | Tespit şeridi + kısa kod |
| Düşük bellekli Android'de WebGL context kaybı | Düşük-Orta | Orta | Kamera/Rive dispose, `webglcontextlost` sonrası yenileme yönergesi |
| iOS klavye/IME tuhaflıkları katılım formunda | Orta | Orta | Tek alan + çip seçimi, gerçek cihaz testi |
| Kullanıcı adlarında emoji ile büyük font indirmesi | Düşük | Düşük | İsim karakter filtresi |
