# R4: Oyun hissi ve asset'ler

- **Tarih:** 2026-10-22 (etkinliğe 3 gün)
- **Bağlı gereksinimler:** FR-12, FR-20–23, NFR-02, NFR-11, §8 tasarım ilkeleri
- **Yöntem:** Fiyat, sürüm ve lisanslar 2026-10-22'de web'den doğrulandı. Rive WASM boyutu, npm paketi indirilip ölçüldü. "Tahmin" yazan süreler ve boyutlar ekibin kendi ölçümüyle teyit edilmeli.

Hedef: tarayıcıda çalışan bir oyun gibi hissettirmek ve bunu ilk yüklemeyi şişirmeden yapmak. Bunun için açılışta neredeyse hiç asset yüklenmiyor. Oyun hissini kod (CustomPainter, implicit animasyonlar) taşıyor. Rive ve ses ise ilk dokunuştan sonra, ödül anına kadar sessizce yükleniyor.

---

## 1. Asset envanteri

**Soru:** Oyun hissi veren bir sürüm için hangi asset'ler gerekir? Hangi yüzeyde, hangi öncelikle?

**Bulgular:**
- Gereksinimlerde rozetler P1 (FR-12), kazananlar ekranı P0 (FR-23). Oyun hissinin asıl taşıyıcısı "okut → bağlandın" anı (FR-07, p95 ≤ 1 sn). En çok emeği bu an hak ediyor.
- İlgi alanı listesi sabit (FR-01). Bu yüzden ilgi alanı amblemleri sınırlı ve önceden çizilebilir bir set: tahminen 8–12 adet.
- Emoji kullanırsak Flutter web (CanvasKit) eksik glifler için Google'ın sunucusundan Noto yedek fontlarını indirir. Emoji fontu büyük. Bu nedenle arayüzde emoji kullanmamayı öneriyoruz. İsimlerde emoji kısıtlaması R1 ile birlikte değerlendirilmeli. (Güven: orta. Flutter web font fallback davranışına dayanıyor, ölçülmedi.)

**Öneri (P0 = Pazar için şart, P1 = olursa iyi, P2 = sonra):**

| Yüzey | P0 | P1 | P2 |
|---|---|---|---|
| **Kimlik (ortak)** | Wordmark "Bağlantı Ağı" (font + kodla çizilen düğüm işareti). Renk token'ları. 2 font (display + UI), Türkçe alt kümeli | Animasyonlu logo (Rive, lobide) | Favicon/PWA ikon seti |
| **Oyuncu telefonu** | İsimden üretilen avatar (CustomPainter: hash → şekil + renk + baş harfler). İlgi alanı amblemleri (SVG/CustomPainter, 8–12 adet). QR "kart" çerçevesi (kod; rotasyon için geri sayım halkası). Okutma vizörü çerçevesi. Bağlantı kutlaması v0 (Flutter: scale-pop + iki avatarın birleşmesi + kodla parçacık patlaması). "+10 / +5 bonus" uçan puan sayısı. Haptik (yalnızca Android) | Bağlantı kutlaması v1 (Rive). 4 rozet (Rive, tek "rozet kabuğu" dosyası). Seviye/puan eşiği kutlaması | Oyun sonu özet kartı paylaşımı (görsel olarak) |
| **Projeksiyon** | Ağ grafiği: düğüm = avatar dairesi + ilgi rengi halkası. Kenar = ince çizgi, yeni kenarda ışık darbesi ("pulse"). Ortam: yavaş dalgalanan arka plan ızgarası (kod). Lobi: büyük QR + canlı sayaç + katılan isimler "düşer". Kazananlar: ilk 3 kürsüsü + konfeti (kod) | Ses (yalnızca projeksiyon): yeni bağlantı "tık", liderlik değişimi, geri sayım, kazanan fanfarı. Fragment shader arka plan (ör. hafif noise/aurora) | Rive kürsü animasyonu |
| **Yönetici** | Hiçbir özel asset yok. Sade, tema token'larını kullanan arayüz | — | — |

**Rozet önerisi** (oyunun mekaniğine bağlı, hepsi sunucuda türetilebilir):
1. **İlk Bağlantı:** ilk bağlantı (altın madalya)
2. **Köprü:** ortak ilgi alanı olmayan biriyle bağlantı (FR-11 bonusunu ödüllendirir)
3. **Kaşif:** N farklı ilgi alanından insanla tanışma
4. **Sosyal Kelebek:** 10 bağlantı
5. (P2) **Alev Serisi:** 5 dakikada 3 bağlantı. **Efsane:** ilk 3 sıra (kazananlar ekranında)

**Ses ve haptik:**
- Konuşma sırasında 100 telefondan ses çıkması kötü bir deneyim. Ayrıca iOS'ta Web Audio, sessiz modda varsayılan olarak susuyor (`navigator.audioSession` varsayılanı "ambient") ([WebKit 237322](https://bugs.webkit.org/show_bug.cgi?id=237322), erişim 2026-10-22). Bu yüzden telefonda ses yok. Ses yalnızca projeksiyonda.
- `navigator.vibrate` Android Chrome'da çalışıyor, iOS Safari'de 2026 itibarıyla hâlâ yok ([web-haptics browser support](https://www.mintlify.com/lochie/web-haptics/advanced/browser-support), [SWM blog](https://swmansion.com/blog/haptic-feedback-on-the-web-why-the-web-deliberately-refuses-to-be-as-tactile-as-native-apps), erişim 2026-10-22). iOS'ta `<input type=checkbox switch>` hilesi var. Ancak bir test sitesi bunun iOS 26.5'te kapatıldığını iddia ediyor (doğrulanamadı) ([kimsal.com, 2026-03-20](https://kimsal.com/blog/2026/03/20/a-bit-of-feedback/)). Bu yüzden haptiği "varsa bonus" sayalım. Bağlantı anı haptiğe dayanmamalı, görsel geri bildirim tek başına yetmeli.

**Güven:** orta (envanter muhakemeye dayanıyor, platform davranışları yüksek güvenle doğrulandı).

---

## 2. Flutter web'de oyun hissi: düz Flutter + Rive mi, Flame mi?

**Soru:** Flame eklemeli miyiz? Hangi yüzeyde?

**Bulgular:**
- `flame` 1.38.2 pub.dev'de en güncel kararlı sürüm. 2.0.0-dev.1 önsürüm olarak yayımlanmış. Bağımlılıkları hafif ve saf Dart, web destekleniyor ([pub.dev/packages/flame](https://pub.dev/packages/flame), erişim 2026-10-22, "56 gün önce").
- Flame web'de CanvasKit önerir. Bir dağıtım platformunun dokümanı, bazı Flutter 3.41 engine hash'lerinde `--wasm` derlemesinin bozuk olduğunu yazıyor ([Wavedash Flame docs](https://docs.wavedash.com/engines/flame), erişim 2026-10-22). Flame'in ek bayt maliyeti için yayımlanmış bir ölçüm bulamadık.
- Bizim "oyun" ihtiyaçlarımız sprite, fizik, çarpışma ya da tilemap değil. İhtiyacımız şunlar: bir graf yerleşimi (force-directed), parçacıklar ve geçişler. Bunların hepsi `CustomPainter` + `Ticker` ile yapılabiliyor. Grafik ayrıca R1 kapsamında (FR-20: 150 düğüm / 1.500 kenarda ≥ 30 fps).

**Öneri:**
- **Telefon:** Flame yok. Düz Flutter widget'ları + implicit/explicit animasyonlar + CustomPainter. Rive yalnızca ödül anlarında, ertelenmiş yüklemeyle.
- **Projeksiyon:** P0'da da Flame yok. Graf, tek bir `CustomPainter` içinde çiziliyor: ana döngü `Ticker`, kenarlar tek bir `Path` batch'i, düğüm avatarları önbelleğe alınmış `Picture` olarak. Flame burada da gereksiz bir öğrenme maliyeti getirir. İleride istenirse yalnızca projeksiyonda, ayrı bir entrypoint ya da `deferred as` import ile eklenmeli, böylece oyuncu paketine girmez.
- **Hibrit kural:** Projeksiyon kodu oyuncu bundle'ına girmemeli. Yönetici ve projeksiyon rotalarını `deferred` import ile ayırın (R1 ile uyumlu).

**Güven:** yüksek (sürüm doğrulandı). Flame'in boyut etkisi ölçülmedi: düşük.

---

## 3. Rive üretim yolu

**Soru:** Plan ve fiyat, export, öğrenme eğrisi, data binding, marketplace lisansı. Gönüllü bir ekip 4–6 rozet + bağlantı kutlamasını ne kadar sürede çıkarır?

**Bulgular:**
- **Fiyatlar** ([rive.app/pricing](https://rive.app/pricing), erişim 2026-10-22):

  | Plan | Fiyat | Notlar |
  |---|---|---|
  | Free | $0 | ".riv export with a splash screen", 3 ortak dosya |
  | Cadet | $9/koltuk/ay | Splash yok, sınırsız dosya, en fazla 3 koltuk |
  | Voyager | $32 | Library, embed |
  | Enterprise | $120 | Yıllık geliri 10 milyon dolar üstü kurumlar için |

  Ekim 2025 duyurusu ve dokümanlar ise "runtime export'u ücretli planlarda" diyor ([rive.app/blog/new-pricing](https://rive.app/blog/new-pricing), [exporting docs](https://rive.app/docs/editor/exporting/exporting-for-runtime), erişim 2026-10-22). Kaynaklar çelişiyor. Export edilmiş dosyalar plan bitse de çalışmaya devam ediyor. Runtime'lar MIT lisanslı.
- **Flutter runtime:** `rive` 0.14.11, `rive_native` 0.1.11'e bağlı. Web'de hem Flutter hem Rive renderer destekleniyor ([pub.dev/packages/rive](https://pub.dev/packages/rive), erişim 2026-10-22). API `RiveWidget` + `RiveWidgetController`. Data binding için `controller.dataBind(DataBind.auto()/byName())` ile ViewModel örneği alınıyor ([Rive Flutter docs](https://rive.app/docs/runtimes/flutter/flutter.md), erişim 2026-10-22).
- **Web'e özgü kritik not:** Tarayıcılar canlı WebGL context sayısını yaklaşık 16 ile sınırlıyor ve bu sınırı CanvasKit ile paylaşıyorlar. `Factory.rive` ile her widget kendi context'ini açıyor. Çok sayıda rozeti aynı anda göstermek için `RivePanel` kullanılmalı (tek context) ya da `Factory.flutter` seçilmeli (aynı kaynak).
- **Marketplace lisansı:** "Marketplace files are all shared under a CC BY license" ([Rive marketplace docs](https://rive.app/docs/community/marketplace-overview.md), erişim 2026-10-22). Ticari kullanım serbest ama yazar atfı zorunlu. "Remix" ile kopyalanıp düzenlenebiliyor.

**Öneri:**
- **Cadet planı alınsın ($9, 1 ay, 1 koltuk).** Free plandaki splash'in runtime'da nasıl göründüğünü doğrulayacak zamanımız yok, bu maliyet riski kapatıyor.
- **Tek "rozet kabuğu" stratejisi:** Tek bir artboard hazırlanır: çerçeve, parlama süpürmesi, kıvılcımlar, joystick ile tilt ve `idle → unlock → celebrate` durum makinesi. Rozet farkları ViewModel'den gelir: `badgeType` (enum veya sayı; ikon katmanını ve rengi seçer) ve `label` (metin). 4 rozet, yaklaşık 1,3 rozetlik emekle çıkar. Görüntü (image) binding'e güvenmeyin, ikonları dosyanın içine gömün.
- **Marketplace'i referans ve iskelet için kullanın**, bitmiş görünümü kopyalamak için değil. Kullanılan her remix için oyun sonu ekranına "Credits" satırı eklenmeli (CC BY).
- **Tilt etkileşimi:** iOS'ta `DeviceOrientation` izin istiyor. Tilt'i parmakla sürüklemeye (pointer → joystick girdisi) bağlayın, cihaz sensörünü kullanmayın.

**Gerçekçi süre tahminleri** (Figma/AE deneyimi olan ama Rive'a yeni biri için; düşük–orta güven):

| İş | Süre |
|---|---|
| Rive temelleri (araç, timeline, state machine, data binding) | 3–5 saat |
| Rozet kabuğu (çizim + 3 durum + tilt + parlama) | 5–8 saat |
| 4 varyant (ikon + renk) | 2–3 saat |
| Bağlantı kutlaması (iki düğümün birleşmesi + patlama, isimler data-bound) | 3–5 saat |
| Flutter entegrasyonu ve gerçek telefonda test (dev ile birlikte) | 2–4 saat |
| **Toplam** | **~15–25 saat**, yani tek kişinin 2 tam günü |

Bu, takvimin sınırında. Bu yüzden aşağıdaki yedek planlar (§6) zorunlu.

**Güven:** fiyatlar ve lisans yüksek, süreler düşük–orta.

---

## 4. Diğer üretim yolları ve lisansları

**Bulgular ve değerlendirme:**

| Kaynak | Lisans (erişim 2026-10-22) | Bizim için |
|---|---|---|
| **Gemini/Imagen (API)** | "Google won't claim ownership". Ücretsiz katmanda girdi/çıktı eğitimde kullanılabilir ve insanlar tarafından okunabilir ([Gemini API terms](https://ai.google.dev/gemini-api/terms), son güncelleme 2026-04-28). Görsellere SynthID görünmez filigranı ekleniyor ([DeepMind](https://deepmind.google/discover/blog/identifying-ai-generated-images-with-synthid/)). Saf AI çıktısının telif koruması tartışmalı | Yalnızca moodboard ve keşif için. Seri tutarsızlığı (4 rozet aynı elden çıkmış gibi durmaz) ve "AI slop" görünümü riski yüksek. Kullanılırsa vektöre çevrilip (ör. `vtracer`, Illustrator Image Trace) elle sadeleştirilmeli ve stil token'larına oturtulmalı |
| **Kenney** (görsel + ses paketleri) | CC0, atıf gerekmez ([kenney.nl/support](https://kenney.nl/support)) | UI sesleri ("Interface Sounds", "Digital Audio") için ideal. Görselleri fazla tanınır, kullanmayın |
| **game-icons.net** | CC BY 3.0, yazar atfı şart ([about](https://game-icons.net/about.html)) | ~4.000 tek renk SVG. İlgi alanı amblemleri ve rozet ikonları için iyi bir başlangıç. Credits ekranı gerekli |
| **LottieFiles (ücretsiz)** | Lottie Simple License: ticari kullanım serbest, atıf gerekmiyor, dosyaların ayrı dağıtımı yasak ([help, 2026-01-16](https://help.lottiefiles.com/animation-licensing-basics-)). Bazı dosyaların kendi lisansı var | Önerilmez. Ek `lottie` paketi ve ikinci bir animasyon sistemi getirir, ayrıca stil tutarsızlığı yaratır |
| **OpenGameArt** | Dosya başına değişiyor (CC0/CC BY/GPL) | Zaman kaybı riski var. Yalnızca CC0 olanlar |
| **Freesound** | CC0 / CC BY / CC BY-NC (+ eski Sampling+) ([FAQ](https://freesound.org/help/faq/)) | Yalnızca CC0 filtresiyle. NC lisanslıları kullanmayın |
| **ChipTone** | Üretilen sesler CC0 ([sfbgames.itch.io/chiptone](https://sfbgames.itch.io/chiptone)) | Kendi "tık/pop/fanfar" seslerimiz için en hızlı yol. jsfxr'ın çıktı lisansı doğrulanamadı |
| **Kodla üretilen (procedural)** | Kendi kodumuz | Avatarlar, parçacıklar, konfeti, QR çerçevesi, graf. 0 bayt asset, her ekranda tutarlı |
| **Fragment shader (`FragmentProgram`)** | — | Flutter 3.10'dan beri web'de destekleniyor ([What's new in 3.10](https://flutter.dev/blog/whats-new-in-flutter-3-10)). `ImageFilter.shader` yalnızca Impeller'da çalışıyor, web'de yok ([shader docs](https://docs.flutter.dev/ui/design/graphics/fragment-shaders)). Projeksiyon arka planı için P1. Telefonda gereksiz |
| **İkon fontu** | Material Symbols (Apache 2.0) | Yalnızca yönetici arayüzünde. Release derlemede `--tree-shake-icons` sayesinde kullanılan glifler kalıyor. Oyuncu arayüzünde jenerik Material görünümü istemiyoruz |

**"AI slop" görünümünden kaçınma kuralları:**
1. Tek bir stil sözleşmesi: çizgi kalınlığı, köşe yarıçapı, gölge yönü ve 6 renkli palet yazılı olarak sabitlenir.
2. Gradyan yerine düz renk + tek sert gölge.
3. Her ikon aynı grid'de (24 px, 2 px stroke).
4. Rastgele parlama ve "glassmorphism" yok.
5. Tipografi karakterli bir display font ile taşınır.
6. Hareket ödül anlarında yoğun, geri kalanında sakin.

**Güven:** yüksek (lisanslar birincil kaynaktan).

---

## 5. Web ağırlık bütçesi

**Bulgular:**
- **Rive web WASM** (`@rive-app/flutter-native-wasm@47.0.0`, ölçüldü 2026-10-22):

  | Dosya | Ham | gzip -9 | brotli |
  |---|---|---|---|
  | `rive_native.wasm` | 2.966 KB | ~1.060 KB | ~805 KB |
  | `rive_native.js` | ~203 KB | | |

  Bu, Flutter'ın kendi CanvasKit'ine ek bir yük. Rive JS runtime tablosu (Ocak 2026) da "boyutun çoğu WASM" diyor ([runtime sizes](https://rive.app/docs/runtimes/runtime-sizes.md)).
- **WASM'ın kaynağı:** `rive_native`, WASM'ı varsayılan olarak jsDelivr CDN'den çalışma anında indiriyor. `--dart-define=RIVE_NATIVE_WASM_HOST=https://.../` ile kendi sunucumuzdan sunulabiliyor ([rive-native docs](https://rive.app/docs/runtimes/flutter/rive-native.md)). Modülün tam olarak ne zaman indirildiği (açılışta mı, `RiveNative.init()` çağrısında mı) dokümanda yazmıyor, ölçülmeli.
- **Fontlar:** Aday fontların hepsinde `latin-ext` alt kümesi var, yani ç ğ ı İ ö ş ü glifleri tam (Google Fonts metadata, erişim 2026-10-22). Flutter web, pubspec'teki fontları açılışta yükler. Bu yüzden font sayısı ve boyutu doğrudan TTI'ı etkiliyor. `google_fonts` paketiyle çalışma anında font çekmek ilk ekranda FOUT ve ek istek getirir.

**Öneri (bütçe):**

| Kalem | Format | İlk yükleme | Ertelenmiş |
|---|---|---|---|
| Fontlar | 2 aile, `pyftsubset` ile Basic Latin + Türkçe + rakam/noktalama alt kümesi. TTF, statik ağırlık veya tek variable dosya | ≤ 80 KB toplam | — |
| Logo, avatar, amblem, QR çerçevesi | CustomPainter veya inline SVG path (`flutter_svg` yerine path verisini koda gömmek) | ≤ 20 KB | — |
| Rive runtime | WASM + JS | **0** | ~0,8–1,1 MB, ilk başarılı katılımdan sonra arka planda |
| `.riv` dosyaları | Rozet kabuğu + kutlama. Gömülü raster yok, font yerine path'e çevrilmiş metin veya data-bound metin için tek font | 0 | ≤ 60 KB toplam (hedef) |
| Projeksiyon sesleri | Kısa sesler: 1 kanal, 48–64 kbps. iOS/Safari uyumu için AAC (`.m4a`) veya MP3, Opus yedek | — | ≤ 150 KB (yalnızca projeksiyon) |
| Telefon sesleri | Yok | 0 | 0 |

**Yükleme stratejisi:**
1. Açılış ekranı ve katılım formu yalnızca kod ve fontla açılır.
2. Katılım tamamlanınca arka planda `RiveNative.init()` ve `.riv` ön yüklemesi başlar.
3. İlk bağlantıya kadar Rive hazır değilse Flutter v0 kutlaması oynar (aynı bileşen arayüzü, iki uygulama). Rozet bildirimi kuyruğa alınır ve Rive yüklenince gösterilir.
4. `prefers-reduced-motion` açıksa Rive yüklenmez, statik rozet + kısa fade kullanılır (NFR-11).
5. WASM'ı kendi Firebase Hosting'imizden sunmak tek bir origin demek. Salon Wi-Fi'ında DNS/TLS el sıkışmasını azaltır. Ancak CDN önbelleği avantajını kaybettirir. R1'in ölçümüne göre karar verilmeli.

**Güven:** Rive boyutu yüksek (ölçüldü). Yükleme zamanlaması orta (spike gerekiyor).

---

## 6. 3 günlük üretim planı

**Roller:** **D** = tasarım/motion (Rive), **F1** = oyuncu uygulaması, **F2** = projeksiyon/grafik, **İ** = içerik ve ses (soru havuzuyla aynı kişi olabilir).

| Zaman | D | F1 | F2 | İ |
|---|---|---|---|---|
| **Per 22 akşam** | Sanat yönü kararı (en fazla 1 saat). Palet token'ları ve font seçimi. Cadet alımı. Rive temelleri | Tema token'ları, font alt kümeleri, avatar CustomPainter | Graf CustomPainter iskeleti, 150 sahte düğümle fps ölçümü | ChipTone/Kenney ile 5 ses taslağı |
| **Cum 23 ÖÖ** | Rozet kabuğu v1 (tek rozet, 3 durum) | QR kartı, okutma vizörü, **Flutter v0 bağlantı kutlaması** (her durumda kalacak) | Düğüm/kenar görseli, kenar ışık darbesi | Amblem seti (game-icons tabanlı, yeniden renklendirilmiş) |
| **Cum 12:00: Kapı 1** | Rozet kabuğu gerçek iOS ve Android telefonda Flutter web derlemesinde oynuyor mu? Data binding çalışıyor mu? | | | |
| **Cum ÖS** | 4 varyant, ardından bağlantı kutlaması (Rive) | Rive ertelenmiş yükleme, rozet kuyruğu, puan uçuşu | Lobi ekranı (büyük QR + "düşen" isimler) | Credits listesi, ses sıkıştırma |
| **Cmt 24 ÖÖ** | Cila, `reduced-motion` varyantı | Entegrasyon, 3 gerçek orta seviye Android + 2 iPhone testi | Kazananlar ekranı + konfeti, sesler | Kabul testi senaryosu |
| **Cmt 14:00: Kapı 2** | Rive akışı iki platformda sorunsuz değilse **yedek plan** devreye girer: statik SVG rozet + `AnimatedScale`/`AnimatedRotation` + `ShaderMask` parlama süpürmesi + CustomPainter kıvılcım. Rive özellik bayrağıyla kapatılır, kod kalır | | | |
| **Cmt akşam** | — | Performans ve bayt bütçesi ölçümü, prova | Projeksiyonda 150 düğüm / 1.500 kenar provası | — |
| **Paz 25** | Dondurma. Deploy yok (NFR-14) | | | |

**Yedek planın ilkesi:** Her Rive anının bir Flutter v0 karşılığı **önce** yapılır. Rive bir iyileştirmedir, bağımlılık değildir. Kapı 1'de rozet kabuğu çalışmıyorsa D, Rive'ı yalnızca bağlantı kutlamasına daraltır ve rozetleri SVG olarak çizer.

**Güven:** orta (gönüllü ekip uygunluğu bilinmiyor, Q7).

---

## 7. Sanat yönü önerisi

Kaçındığımız klişeler: mor gradyan, siyah üstüne neon, krem + serif. GDG bağlamı Google'ın 4 rengini meşru kılıyor ama kurumsal Google görünümüne düşmemeliyiz. Resmî GDG logosu/lockup'ı varsa yeniden çizilmeden chapter kitinden alınmalı (doğrulanmadı).

**A. "Çıkartma Atölyesi" (sticker / arcade)** ⭐ önerilen
- **Palet:** sıcak koyu asfalt `#1C1B1F` zemin, kağıt beyazı `#F6F4EE` çıkartmalar, 3 px koyu kontur + sert ofset gölge. Aksanlarda GDG mavi/kırmızı/sarı/yeşil tam doygunlukta, her ilgi alanına bir renk.
- **Tipografi:** **Unbounded** (display: geniş, oyunsu, latin-ext) + **Google Sans Flex** (UI; Google Fonts'ta açık kaynak, latin-ext, `ROND` ekseniyle yuvarlaklık ayarı var). Kısa kod ve puanlar için **Google Sans Code**.
- **Hareket:** "damga" karakteri. Hızlı giriş, kısa overshoot, çıkartmanın yapışması (scale 1.15 → 0.95 → 1). Rozetler parlayan madalya-çıkartma. Referanstaki glow ve sparkle, koyu zeminde yalnızca ödül anlarında kullanılır.
- **Neden:** Düz vektör küçük ve hızlı üretiliyor. Kontur ve sert gölge kuralı tutarlılığı zorluyor ve AI görünümünü zorlaştırıyor. Hem telefonda hem projeksiyonda okunuyor.

**B. "Adana Sıcağı"**
- **Palet:** kiremit `#D9481C`, güneş sarısı `#F2B705`, pamuk beyazı, derin petrol `#0F3A40` (projeksiyon zemini).
- **Tipografi:** **Bricolage Grotesque** (opsz/wdth eksenleri, karakterli) + **Onest**.
- **Hareket:** sıcak, yumuşak yaylanma (squash & stretch), ısı dalgası gibi yavaş ortam hareketi.
- **Değerlendirme:** Yerel kimliği güçlü ama "game" hissi A'dan zayıf.

**C. "Metro Haritası"**
- **Fikir:** Ağ, bir metro hattı haritası gibi.
- **Palet:** lacivert-mürekkep `#0B1B2B` zemin, hat renkleri olarak GDG 4 rengi.
- **Tipografi:** **Space Grotesk** + **JetBrains Mono**.
- **Hareket:** çizgilerin çizilmesi, istasyonda sinyal darbeleri, hassas ease-out.
- **Değerlendirme:** Projeksiyon için çok güçlü ama telefonda oyunsuluğu düşük ve koyu lacivert zemin jenerikleşme riski taşıyor.

**Öneri:** A. Projeksiyon grafiğine C'nin "hat çizilmesi" kenar animasyonu ödünç alınabilir.
**Güven:** orta (zevk kararı; font kapsamları yüksek güvenle doğrulandı).

---

## Özet karar önerileri

1. Açılış yükü asset'siz: avatar, amblem, QR çerçevesi, konfeti ve graf kodla çiziliyor. Yalnızca 2 alt kümeli font (≤ 80 KB).
2. Flame kullanılmıyor (telefonda da projeksiyonda da). CustomPainter + Ticker + Rive yeterli.
3. Rive Cadet ($9) alınsın. Tek "rozet kabuğu" + data binding ile 4 rozet ve 1 bağlantı kutlaması. Rive ilk katılımdan sonra ertelenmiş yükleniyor (+~0,8–1,1 MB).
4. Her Rive anının bir Flutter v0 karşılığı önce yapılıyor. Kapılar Cuma 12:00 ve Cumartesi 14:00.
5. Telefonda ses yok. Haptik yalnızca Android'de bonus. Ses yalnızca projeksiyonda (ChipTone/Kenney, CC0).
6. Lisans: CC0'ı tercih edin (Kenney, ChipTone, Freesound CC0). CC BY (game-icons, Rive Marketplace) kullanılırsa Credits ekranı şart. AI görselleri yalnızca keşif için.
7. Sanat yönü A: "Çıkartma Atölyesi", Unbounded + Google Sans Flex.

## P0 asset kontrol listesi

| Asset | Araç/kaynak | Lisans | Boyut bütçesi | Sahip | Yedek |
|---|---|---|---|---|---|
| Renk token'ları + tema | Kod | Kendi | ~0 | F1 | — |
| Display + UI fontu (Türkçe alt küme) | Google Fonts → `pyftsubset` | OFL | ≤ 80 KB | F1 | Tek font (yalnızca UI) |
| Wordmark/logo | Font + CustomPainter düğüm işareti | Kendi / OFL | ~0 | D | Sadece yazı |
| İsimden avatar | CustomPainter (hash → şekil/renk/baş harf) | Kendi | 0 | F1 | Renkli daire + baş harf |
| İlgi alanı amblemleri (8–12) | game-icons.net SVG → path, yeniden renk | CC BY 3.0 (atıf) | ≤ 15 KB | İ/D | Renkli nokta + metin |
| QR kart çerçevesi + rotasyon halkası | Kod | Kendi | 0 | F1 | Düz kart |
| Okutma vizörü | Kod | Kendi | 0 | F1 | Kamera önizlemesi |
| Bağlantı kutlaması v0 | Flutter animasyon + CustomPainter parçacık | Kendi | 0 | F1 | — (bu zaten yedek) |
| Puan uçuşu "+10 / +5" | Flutter | Kendi | 0 | F1 | Snackbar |
| Graf düğüm/kenar görseli + darbe | CustomPainter | Kendi | 0 | F2 | Statik çizgi |
| Lobi ekranı (büyük QR, sayaç) | Kod | Kendi | 0 | F2 | — |
| Kazananlar kürsüsü + konfeti | Kod | Kendi | 0 | F2 | Statik ilk 3 |
| Credits ekranı | Kod | — | 0 | İ | Footer satırı |

(Rive rozetleri ve kutlaması P1. Ertelenmiş bütçe ≤ 60 KB `.riv` + runtime. Projeksiyon sesleri P1, ≤ 150 KB.)

## Riskler

| Risk | Etki | Azaltma |
|---|---|---|
| Rive işi gecikir | Ödül anı sönük kalır | v0 önce yapılıyor, iki karar kapısı, özellik bayrağı |
| WebGL context sınırı (~16) | Rozet ızgarası boş kalır ya da çöker | `RivePanel` veya `Factory.flutter`. Aynı anda tek Rive sahnesi |
| Rive WASM jsDelivr'den gelir, salon ağı yavaş | Rozet hiç görünmez | Ertelenmiş yükleme + v0 yedeği. Gerekirse `RIVE_NATIVE_WASM_HOST` ile kendi hosting'imiz |
| Emoji veya eksik glif, büyük fallback font indirmesine yol açar | TTI ve veri artar | Arayüzde emoji yok. İsimlerde emoji politikası (R1) |
| CC BY atfı unutulur | Lisans ihlali | Credits ekranı P0 |
| iOS haptik/ses çalışmaz | Beklenen his eksik | Görsel geri bildirim tek başına yeterli tasarlanıyor |
| Free/Cadet export belirsizliği | Splash görünür | Cadet alınıyor |

## Doğrulanması gerekenler (spike)

1. `RiveNative.init()` WASM'ı ne zaman indiriyor? Açılışta mı, çağrıda mı? (DevTools Network, Cuma sabahı.)
2. Rozet kabuğu + data binding, iOS Safari ve orta seviye Android'de `Factory.rive` ve `Factory.flutter` ile çalışıyor mu? Hangisi daha akıcı?
3. Font alt kümeleriyle release derlemede ilk yükleme farkı (R1 ölçüm düzeneğiyle).
4. Android Chrome'da `HapticFeedback` veya `navigator.vibrate` gerçekten titreşiyor mu?
