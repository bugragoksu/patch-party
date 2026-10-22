# R2: Firebase (kimlik, jeton doğrulama, kurallar, Blaze, kotalar, güvenlik)

- **Tarih:** 2026-10-22
- **Bağlı gereksinimler:** FR-03, FR-06, FR-07, FR-11, FR-30, FR-33, NFR-01, NFR-07, NFR-08, NFR-09
- **Karar girdisi:** Blaze planı onaylandı (2026-10-22), sıkı güvenlik duruşu isteniyor. Bu yüzden Spark karşılaştırması kısa tutuldu.
- **Not:** Fiyat ve limitler aşağıdaki kaynaklardan 2026-10-22'de okundu. "Doğrulanmadı" diye işaretlenenler bilgi birikimine dayanıyor.

---

## 0. En kritik bulgu: aynı IP'den saatte 100 yeni hesap

Firebase Auth ve Identity Platform, yeni hesap oluşturmayı **"100 accounts/hour for each IP address"** ile sınırlıyor. Anonim girişte `signInAnonymously()` yeni hesap oluşturur ([Auth limits](https://firebase.google.com/docs/auth/limits), son güncelleme 2026-10-20; [Identity Platform quotas](https://docs.cloud.google.com/identity-platform/quotas), 2026-10-21). Limit artışı için **"contact Google Cloud support at least two weeks in advance"** deniyor. Etkinliğe 3 gün kaldığı için bu yol kapalı.

Salon Wi-Fi'ı tek bir genel IP arkasında NAT yapıyorsa, ~100 oyuncu + prova + yeniden katılımlar bu sınırı aşabilir. Anonim auth ile 101. kişi `auth/too-many-requests` alır. G1'i (%80 katılım) doğrudan tehdit ediyor.

**Öneri:** Katılımı bir `join()` callable function'ı üzerinden yapın. Function oyuncuyu doğrular, Admin SDK ile `createCustomToken(uid)` üretir, istemci de `signInWithCustomToken` ile giriş yapar. Custom token girişi için proje limiti **"45,000 sign-ins/minute"** (aynı kaynak). Per-IP "new account creation" limitinin `signInWithCustomToken` için de geçerli olup olmadığı dokümanda açık değil. **Spike (30 dk, şart):** Ayrı bir test projesinde tek IP'den 110 anonim kayıt ve 110 custom token girişi deneyin, hangisinin 429 döndüğünü görün. Yedek plan: oyunculardan mobil veriyle katılmalarını istemek (operatör CGNAT'ı IP'leri dağıtır) ve katılımı lobby boyunca yaymak.

---

## 1. Kimlik

**Soru:** Anonim kimlik yenilemede korunuyor mu, Safari gizli mod ve uygulama içi tarayıcılarda nasıl davranıyor, kötüye kullanım nasıl sınırlanır, yönetici kimliği nasıl olmalı?

**Bulgular**
- Web'de varsayılan kalıcılık `browserLocalPersistence`, yani IndexedDB. Hem anonim hem custom token oturumu yenilemeden ve sekme kapanıp açılmasından sonra korunur. FR-02 karşılanır.
- Safari gizli sekme: IndexedDB çalışır ama sekme kapanınca silinir. Kullanıcı geri döndüğünde yeni oyuncu olur ve puanı kaybolur. Uygulama içi tarayıcılar (Instagram, WhatsApp) Safari/Chrome'dan ayrı depolama kullanır. Link önce birinde sonra ötekinde açılırsa iki ayrı kimlik oluşur. (Doğrulanmadı, platform davranışı. R1 kapsamında test edilmeli.)
- Per-IP limit ve 100 milyon anonim hesap tavanı: §0.
- Yönetici: e-posta allowlist'i kurallara gömülebilir: `request.auth.token.email == '__ADMIN_EMAIL__' && request.auth.token.email_verified`.

**Öneri**
- Oyuncu: `join()` + custom token (§0). Uygulama içi tarayıcı ve gizli mod algılanınca uyarı gösterin (NFR-10).
- Yönetici: Google ile giriş + **custom claim** `admin: true`. Claim, Admin SDK script'iyle bir kez atanır (`setCustomUserClaims`). Projeksiyon dizüstüsü için ayrı bir Google hesabı ve salt okunur `projector: true` claim'i. Böylece salondaki dizüstünde admin oturumu açık kalmaz. E-posta kurallara gömülmez, repo'ya da girmez.
- **Güven:** Yüksek (kalıcılık, claim). Orta (Safari/in-app davranışı).
- **Spike:** §0'daki per-IP testi. iOS Safari gizli sekme ve Instagram webview'da oturum koruma, R1 ile birlikte.

---

## 2. Dönen jeton doğrulaması (Spark, rules-only): kısa değerlendirme

**Soru:** Oyuncu her N saniyede özel bir dokümana nonce yazar, tarayan da batched write ile bağlantı oluşturur, kurallar `get()`/`getAfter()` ile doğrular. Sağlam mı?

**Bulgular**
- Mantıken sağlam. Kurallardaki `get()` okuma kurallarına tabi değil, yani tarayan `tokens/{uid}` dokümanını doğrudan okuyamasa da kural okuyabilir. Ancak bu okumalar faturalanır, reddedilen istekte bile ([rules-conditions](https://firebase.google.com/docs/firestore/security/rules-conditions)).
- Erişim çağrısı limiti: tek doküman isteğinde **10**, transaction/batch'te **20**. "The previous limit of 10 also applies to each operation." Bazı çağrılar cache'lenir ([quotas](https://firebase.google.com/docs/firestore/quotas), 2026-10-21). Bağlantı + iki oyuncu güncellemesinden oluşan bir batch, event, token, iki oyuncu, iki `getAfter` ve pair `existsAfter` ile limitin altında kalır, ama sınıra yakın.
- Puan kurallarla zorlanabilir: `request.resource.data.score == resource.data.score + (a.interests.hasAny(b.interests) ? 10 : 15)`. Hız sınırı da yazılabilir: `request.time > resource.data.lastConnectionAt + duration.value(15, 's')`. Pair benzersizliği deterministik ID ile sağlanır: `min(uid)_max(uid)` + `!exists()`.
- Zayıf yanlar: (1) Başkasının oyuncu dokümanına yazma izni açmak gerekir (`getAfter` ile koşullu). Bu, saldırı yüzeyini ve test matrisini büyütür. (2) Nonce yazma maliyeti: 150 × 2/dk × 60 dk (lobby dahil) = **18.000 yazma**. Bu, Spark'ın 20.000/gün yazma kotasına dayanır. (3) §0'daki per-IP sorununun sunucusuz çözümü yok, çünkü custom token üretmek için sunucu gerekir. (4) Batch boyutu: 500 yazma (dokümanda bu sayfada yok, doğrulanmadı).

**Öneri:** Blaze onaylandığı için bu tasarımı **kullanmayın**. Alınacak ders "her kural testle kanıtlı" kültürü.
**Güven:** Yüksek. **Spike:** Gerekmez.

---

## 3. Blaze: callable `connect()` (önerilen tasarım)

**Soru:** Tüm kurallar tek bir function transaction'ında uygulanırsa p95 ≤ 1 sn tutar mı? Maliyeti, test edilebilirliği nasıl?

**Bulgular**
- 2nd gen varsayılan concurrency **80** (1-1000 arası ayarlanabilir). `minInstances` ile sıcak tutulan instance'lar "billed at idle rates". `maxInstances` dolunca istekler 30 sn kuyrukta bekler, sonra 429 döner ([manage-functions](https://firebase.google.com/docs/functions/manage-functions), 2026-10-22). 150 oyuncu için 1-2 instance yeter.
- Ücretsiz kota (Blaze): 2M çağrı/ay, 400K GB-sn, 200K CPU-sn ([pricing](https://firebase.google.com/pricing)). Etkinlikte ~5.000 çağrı olur, yani **$0**. `minInstances: 1` ile etkinlik günü birkaç saat boşta beklemenin maliyeti tahminen < $1 (doğrulanmadı, Cloud Run idle fiyatına göre).
- Cold start için resmi bir sayı yok. Dokümanda "can take significant amounts of time" deniyor ([tips](https://firebase.google.com/docs/functions/tips)). Topluluk deneyimine göre Node.js'te 1-3 sn (doğrulanmadı). `minInstances: 1` ile bu yol devre dışı kalır.
- Sıcak yol tahmini: istemci→europe-west3 RTT ~40-60 ms + TLS/HTTP2 (bağlantı açıksa yok) + transaction (5 okuma, 3 yazma, aynı bölge) ~50-150 ms. Toplam **~200-400 ms**. App Check token'ı ilk çağrıda bir kez alınır ve cache'lenir. Bu sayılar tahmin, ölçülmeli.
- App Check replay koruması (`consumeAppCheckToken`) "adds a network round trip" ([app-check/cloud-functions](https://firebase.google.com/docs/app-check/cloud-functions), 2026-10-20). `connect()` için kullanmayın.

**Jeton tasarımı (yazmasız TOTP):** `join()` her oyuncuya rastgele bir `seed` üretir ve `playerSecrets/{uid}` dokümanına yazar. Bu dokümanı yalnız sahibi okuyabilir. İstemci `HMAC(seed, floor(t/30))` değerini hesaplayıp QR'a `{playerCode, totp}` koyar. Kısa kod `K7M-4821` biçiminde olur: 3 karakter oyuncu kodu + 4 hane TOTP. `connect()` aynı hesabı sunucuda yapar ve şimdiki ile önceki pencereyi kabul eder (FR-03). Saat kayması için `join()` yanıtı `serverTime` döner, istemci offset uygular. Rotasyon için **0 yazma** gerekir. 4 haneli kodu tahmin etmeyi oyuncu başına hız sınırı (ör. dakikada 10 hatalı deneme) pratikte imkânsız kılar.

**`connect()` transaction adımları:** event `live` mi → tarayan diskalifiye mi, cooldown dolmuş mu (`lastConnectionAt`) → `playerCode` → hedef uid → kendisi değil → TOTP geçerli mi → `connections/{minUid_maxUid}` yok mu → puan = 10 + (ilgi alanı kesişimi boşsa 5) → bağlantı dokümanını yaz (puan ve `questionId` dahil), iki oyuncuya `FieldValue.increment` uygula. Reddedilen denemeler `rateLimits/{uid}` sayacına yazılır. Bu sayaç FR-31'i de besler.

**Karşılaştırma (özet)**

| | Rules-only (Spark) | `connect()` (Blaze) |
|---|---|---|
| Güvenlik | Doğru ama geniş yazma izinleri, karmaşık kurallar | İstemci hiçbir oyun dokümanına yazamaz (`allow write: if false`) |
| p95 gecikme | ~150-300 ms (doğrudan Firestore) | ~200-400 ms sıcak. Cold start riski `minInstances` ile kapanır |
| Karmaşıklık | Kurallarda iş mantığı | İş mantığı TypeScript'te, kurallar okumadan ibaret |
| Test | Yalnız rules testleri | Saf fonksiyon unit testleri + emülatörde entegrasyon + basit rules testleri |
| Per-IP auth sorunu | Çözümsüz | `join()` + custom token |

**Öneri:** Blaze + `join()` ve `connect()` callable'ları (Node.js 22/TypeScript, `region: europe-west3`, `minInstances: 1` yalnız etkinlik günü, `maxInstances: 10`, `concurrency: 80`, `enforceAppCheck: false` + kod içinde bayrağa bağlı kontrol, bkz. §6). Hibrit yok: tüm yazmalar function'dan geçer, okumalar doğrudan Firestore listener'ları ile yapılır.
**Güven:** Orta-yüksek. **Spike (şart):** `connect()`'i europe-west3'e deploy edip Adana'dan 4G ve Wi-Fi üzerinden 200 çağrı yapın, p50/p95'i ölçün. Bir de `minInstances: 0` ile cold start ölçün.

---

## 4. Kota ve maliyet hesabı

**Bulgular:** Ücretsiz günlük kota: **50.000 okuma, 20.000 yazma, 20.000 silme, 1 GiB** ([quotas](https://firebase.google.com/docs/firestore/quotas), 2026-10-21). Blaze bu kotayı korur, aşan kısmı faturalar. Listener 30 dakikadan uzun koparsa yeni sorgu gibi tamamen yeniden faturalanır ([pricing](https://firebase.google.com/docs/firestore/pricing)).

**Varsayımlar:** 150 oyuncu, 1.500 bağlantı, oyuncu başına ortalama 10 bağlantı, 3 projeksiyon/yönetici istemcisi, her istemci ortalama 2 tam yeniden yükleme.

| Kalem | Hesap | Okuma | Yazma |
|---|---|---|---|
| `join()` | 150 × (oyuncu + secret + playerCode) | ~450 | 450 |
| `connect()` başarılı | 1.500 × (5 okuma, 3 yazma) | 7.500 | 4.500 |
| `connect()` reddedilen + sayaç | ~1.500 × (3 okuma, 1 yazma) | 4.500 | 1.500 |
| Oyuncu listener'ı: kendi dokümanı + kendi bağlantıları | 150 × 11 + 1.500 × 2 | ~4.650 | 0 |
| Projeksiyon: `connections` + `players` | 3 × (1.500 + 150 + 1.500 skor güncellemesi) | ~9.450 | 0 |
| Soru havuzu (tek doküman veya Hosting JSON) | 150 | 150 | 0 |
| Yeniden yüklemeler (×2 tampon) | | ~15.000 | |
| **Toplam** | | **~41.000** | **~6.500** |

- **Leaderboard stratejisi:** Her oyuncu canlı top-10 sorgusu dinlerse, top-10'daki her değişiklik 150 okumaya mal olur. ~1.000 değişiklikle bu **150.000 okuma** eder ve kotayı tek başına aşar. Öneri: Top-10 yalnız projeksiyonda olsun ve projeksiyon bunu zaten dinlediği `players` akışından istemcide hesaplasın. Oyuncu yalnız kendi puanını görür. Sıra bilgisi gerekiyorsa `ended` anında bir kez yazılan özet doküman kullanılsın.
- **Sayaçlar:** Projeksiyon sayaçları listener'lardan kendisi türetsin. Ayrı bir sayaç dokümanı oluşturmayın (sıcak doküman riski var).
- **Offline persistence (web):** Kapalı tutun (FlutterFire web'de varsayılan zaten kapalı, doğrulanmadı). Çok sekmeli IndexedDB kilit sorunlarından kaçınılır. Kısa kopmalarda SDK resume token'la yeniden bağlanır (NFR-04).
- **Maliyet:** Kota içinde kalınıyor. Prova günü de aynı günlük kotayı tüketir, bu yüzden testleri emülatörde yapın. Aşılsa bile Firestore okuma birim fiyatı yüz bin başına birkaç sent düzeyinde (bölgeye göre, doğrulanmadı). Asıl maliyet riski kötü niyetli kullanım (§6).
- **Güven:** Orta (varsayımlara bağlı). **Spike:** Yük testinden sonra Firebase konsolundaki kullanım ekranıyla karşılaştırın (R3).

---

## 5. Bölge

**Bulgular:** Türkiye'de Firestore bölgesi yok. Avrupa seçenekleri: `europe-west3` Frankfurt, `europe-west1` Belçika, `europe-central2` Varşova, `europe-west8` Milano; Orta Doğu'da `me-west1` Tel Aviv. Multi-region seçeneği `eur3` ([locations](https://firebase.google.com/docs/firestore/locations), 2026-10-21). Firestore konumu sonradan değiştirilemez.

**Öneri:** Firestore ve Functions için **`europe-west3` (Frankfurt)**. Türk ISS'lerinin ana peering noktası Frankfurt olduğundan RTT tahminen 40-60 ms (doğrulanmadı). Fiziksel olarak daha yakın olan Tel Aviv'e trafik genelde Avrupa üzerinden gider. Function ile veritabanı **aynı bölgede** olmalı.
**Güven:** Orta. **Spike (10 dk):** Salondan ve 4G'den [gcping.com](https://gcping.com) ile europe-west3, europe-west1, europe-central2 ve me-west1 ölçülsün, kazanan seçilsin.

---

## 6. Güvenlik ve kötüye kullanım

### 6.1 Denial-of-wallet
- **Bütçe uyarısı** zorunlu (NFR-09): $5, $20 ve $50 eşikleri, e-posta + mobil bildirim. Bütçe uyarıları gecikmeli gelir ve harcamayı durdurmaz.
- **Sert tavan:** Pub/Sub bütçe bildirimi → function → billing'i kapat. Google dokümanındaki uyarılar: "Resources might be irretrievably deleted", "terminate all Google Cloud services in the project, including Free Tier services", ayrıca bildirimlerde gecikme olduğu ve bütçenin altında kalmanın garanti olmadığı belirtiliyor ([disable-billing-with-notifications](https://docs.cloud.google.com/billing/docs/how-to/disable-billing-with-notifications), 2026-10-20). **Öneri:** Etkinlik sırasında kurmayın, çünkü yanlış alarm oyunu öldürür (G4). Alarmı yüksek bir eşiğe ($100) koyup yalnız etkinlik sonrası için etkinleştirmek kabul edilebilir.
- **Function sınırları:** `maxInstances: 10`, `timeoutSeconds: 10`, `memory: 256MiB`. Kötü niyetli bir döngü 10 × 80 eşzamanlı istekte tıkanır, sınırsız ölçeklenemez.
- **Firestore okuma amplifikasyonu:** Herhangi bir oturum sahibi, `connections` koleksiyonunun tamamını (~1.650 doküman) bir döngüde tekrar tekrar sorgulayabilir. Kurallarla sınırlayın:

```
match /events/{e}/connections/{id} {
  allow get, list: if isStaff() ||
    (request.auth.uid in resource.data.participants && request.query.limit <= 100);
  allow write: if false;
}
match /events/{e}/players/{uid} {
  allow get: if signedIn();
  allow list: if isStaff() || request.query.limit <= 20;
  allow write: if false;
}
function isStaff() { return request.auth.token.admin == true || request.auth.token.projector == true; }
```

Tüm `players` ve `connections` listesini yalnız `projector`/`admin` claim'li hesaplar okuyabilir. Oyuncu sorguları `participants array-contains uid` ile kısıtlıdır.

### 6.2 App Check (web)
- reCAPTCHA Enterprise sağlayıcısı: score-based web anahtarı. Spark'ta yalnız 4 skor seviyesi var, Blaze'de 0.0-1.0 arası tamamı. Token TTL'i 30 dk ile 7 gün arası, varsayılanı 1 saat. Auto-refresh varsayılan olarak kapalı. CI ve localhost için debug provider kullanılır ([recaptcha-enterprise-provider](https://firebase.google.com/docs/app-check/web/recaptcha-enterprise-provider), 2026-10-21). reCAPTCHA Essentials/Premium ayda ilk **10.000 değerlendirmeyi ücretsiz** veriyor ([compare-tiers](https://docs.cloud.google.com/recaptcha/docs/compare-tiers), 2026-10-13). 150 oyuncu × birkaç token birkaç yüz değerlendirme eder, maliyeti $0.
- v3 mü Enterprise mı: Yeni projeler için Firebase'in yönlendirdiği yol Enterprise. v3 de destekleniyor ama ek bir avantajı yok.
- Yükleme maliyeti: `recaptcha/enterprise.js` ayrı bir üçüncü taraf script'i. Flutter boot'uyla paralel ve `async` yüklenmeli, ilk etkileşimi bloklamamalı (boyutu R1 ölçsün).
- iOS Safari ve in-app browser: Düşük skor veya script engellenmesi gerçek oyuncuları reddedebilir (doğrulanmadı).
- **Öneri: Monitor-only başlayın, kanıtla enforce'a geçin.** Firestore için enforcement konsoldan açılıp kapanabildiği için deploy gerektirmez (NFR-14 ile uyumlu). Functions'ta `enforceAppCheck: false` bırakın ve kod içinde `if (config.appCheckEnforce && !request.app) throw`. Bayrak `events/{e}/private/config` dokümanından okunur, yani etkinlik sırasında admin panelinden değiştirilebilir. Provada doğrulanmış istek oranı %98'in üzerindeyse ikisini de enforce edin, değilse monitor'da kalın. Emülatör ve CI'da debug token, gerçek projede kayıtlı debug token secret olarak tutulur.

### 6.3 Per-IP kayıt limiti
Bkz. §0. Özetle: anonim auth yerine `join()` + custom token. Ek önlemler: katılımı lobby'ye yaymak, mobil veriye yönlendirmek, prova sırasında **gerçek projede** yeni hesap açmamak (kota saatlik).

### 6.4 Sybil (sahte oyuncu çiftliği)
Bir kişi birkaç tarayıcı profiliyle sahte oyuncular açıp kendi sekmeleri arasında tarama yapabilir. Katmanlı önlemler:
1. **Katılım kodu:** Projeksiyondaki QR `https://.../#j=7QK2PX` biçiminde olsun. Kodun fragment'ta olması sunucu loglarına ve Referer başlığına sızmasını engeller. Kod birkaç dakikada bir döner ve `join()` tarafından doğrulanır. Salonda olmayan kişi katılamaz.
2. **Tavanlar:** Etkinlik başına maksimum oyuncu (ör. 200). Bağlantılar arası cooldown 15 sn (gerçek bir tanışma ≥ 30 sn sürer). Oyuncu başına üst sınır 60 bağlantı.
3. **Tespit (FR-31):** `join()` IP'nin tuzlu hash'ini ve User-Agent'ı saklar (KVKK: etkinlikle birlikte silinir). Şüphe sinyalleri: aynı IP+UA'dan kısa sürede çok katılım; bağlantılarının çoğu yeni ve başka bağlantısı olmayan hesaplarla olan "yıldız" düğümler; dakikada yüksek bağlantı hızı; yüksek hatalı TOTP oranı.
4. **Yaptırım:** Admin `disqualified: true` işaretler (FR-32). Leaderboard bu oyuncuları filtreler, puanlar silinmez, karar geri alınabilir.

### 6.5 Yönetici koruması
- Rol custom claim ile verilir (`admin`, `projector`). İstemcideki hiçbir alan ya da UI bayrağı yetki sayılmaz: hem kurallar hem function'lar `request.auth.token.admin`'i kontrol eder.
- Admin Google hesaplarında **2 adımlı doğrulama** zorunlu (Google hesabı seviyesinde). En fazla 2 admin.
- Durum değişikliği (`setEventState`) de callable üzerinden yapılır ve audit kaydı yazılır.

### 6.6 Hosting güvenlik başlıkları
`firebase.json` → `hosting.headers`. Önce provada `Content-Security-Policy-Report-Only` ile deneyin, sonra enforce edin. Taslak:

```
Content-Security-Policy:
  default-src 'self';
  script-src 'self' 'wasm-unsafe-eval' https://www.gstatic.com https://www.google.com https://www.recaptcha.net;
  connect-src 'self' https://*.googleapis.com https://*.cloudfunctions.net https://*.run.app https://www.gstatic.com https://fonts.gstatic.com;
  frame-src https://www.google.com https://www.recaptcha.net https://<project>.firebaseapp.com;
  img-src 'self' data: blob:;  style-src 'self' 'unsafe-inline';  font-src 'self' https://fonts.gstatic.com;
  worker-src 'self' blob:;  object-src 'none';  base-uri 'self';  frame-ancestors 'none'
Strict-Transport-Security: max-age=31536000; includeSubDomains
Referrer-Policy: no-referrer
Permissions-Policy: camera=(self), microphone=(), geolocation=()
X-Content-Type-Options: nosniff
```

Gerekçeler:
- FlutterFire web, Firebase JS SDK'yı çalışma anında `https://www.gstatic.com/firebasejs/<ver>/firebase-*.js` adresinden enjekte ediyor ([firebase_core_web kaynak](https://github.com/firebase/flutterfire/blob/main/packages/firebase_core/firebase_core_web/lib/src/firebase_core_web.dart)). CanvasKit/skwasm varsayılan olarak gstatic CDN'den gelir, wasm için `'wasm-unsafe-eval'` gerekir.
- Flutter loader `nonce` desteğine sahip ([web initialization](https://docs.flutter.dev/platform-integration/web/initialization), 2026-09-08). Nonce, statik Hosting'de zahmetli olduğundan `style-src 'unsafe-inline'` pragmatik bir taviz.
- Üçüncü taraf yüzeyi küçültmek için `flutter build web --no-web-resources-cdn` ile CanvasKit'i self-host etmek bir seçenek. Yükleme süresine etkisini R1 değerlendirsin.

### 6.7 Proje hijyeni
- IAM: En az yetki ilkesi. Owner 1-2 kişi, geliştiriciler Firebase Develop Admin/Viewer. Deploy için GitHub Actions → **Workload Identity Federation** (OIDC). Servis hesabı JSON anahtarı üretilmez, mümkünse `iam.disableServiceAccountKeyCreation` org policy'si açılır.
- Repo: GitHub secret scanning + push protection açık. Admin script'leri ADC (`gcloud auth application-default login`) ile çalışır. Web `apiKey` gizli değildir ama Cloud Console'da HTTP referrer ve API kısıtı eklenmeli.
- `connect()`/`join()` function'ları kişisel veriyi loglamaz. Cloud Logging `_Default` bucket'ının saklama süresi (30 gün, doğrulanmadı) KVKK planına yazılmalı.

**Güven (§6 geneli):** Orta-yüksek. **Spike:** CSP report-only provası; App Check doğrulanmış istek oranının iOS Safari + Instagram webview'da ölçülmesi.

---

## 7. Test

**Bulgular:** Güncel sürümler: `@firebase/rules-unit-testing` **6.0.0** (2026-10-07), `firebase-tools` **15.34.1** (2026-10-21), `firebase` JS **13.1.0** (2026-10-21), `firebase-functions` **7.4.0** (2026-09-15), `firebase-admin` **14.5.0** (2026-09-23) (npm registry, 2026-10-22). Emülatör Java gerektirir; güncel firebase-tools için JDK 21 (doğrulanmadı). GitHub Actions'ta `actions/setup-java` + `firebase emulators:exec "npm test"` kalıbı birkaç satır sürer.

**Öneri:**
- **Rules testleri** (TS, rules-unit-testing): yazma her zaman reddedilir, liste limitleri, claim'ler, başkasının secret'ını okuma.
- **Function testleri:** (1) Saf iş mantığı (TOTP doğrulama, puan, pair ID, cooldown) için bağımlılıksız unit testler. (2) Emülatörde `connect()` entegrasyon testleri: kendinle bağlantı, çift bağlantı, `live` değil, eski jeton, hız sınırı, eşzamanlı aynı çift (transaction yarışı).
- **Dart tarafı:** `fake_cloud_firestore` kuralları değerlendirmez. Kural güvencesi TS testlerinde kalsın, Dart'ta repository katmanı mock'lanır. CI'da hepsi zorunlu kontrol olur (NFR-12).
- **Güven:** Yüksek. **Spike:** Gerekmez.

---

## 8. FlutterFire web

**Bulgular (pub.dev, 2026-10-22):** `firebase_core` **5.0.0**, `firebase_auth` **7.0.0**, `cloud_firestore` **7.0.0**, `firebase_app_check` **0.5.0**. Hepsi 2026-10-15'te yayımlandı. Önceki kararlı sürümler: 4.15.0 / 6.7.0 / 6.10.0 (2026-09-14). Major sürümlerin breaking değişiklikleri iOS SDK 13, Android BoM 35 ve minSdk 24 ile ilgili, yani native taraf ([firebase_core CHANGELOG](https://github.com/firebase/flutterfire/blob/main/packages/firebase_core/firebase_core/CHANGELOG.md), [cloud_firestore CHANGELOG](https://github.com/firebase/flutterfire/blob/main/packages/cloud_firestore/cloud_firestore/CHANGELOG.md)). `firebase_core_web` JS SDK 13.0.0'ı gstatic'ten yüklüyor. Bu yüzden Firebase JS kodu Dart bundle'ına girmez, ayrı ve cache'lenebilir istekler olarak gelir (app, auth, firestore, functions, app-check). `window.flutterfire_ignore_scripts` ile kullanılmayan servisler atlanabilir.

**Öneri:** FlutterFire kullanın, JS interop'a gerek yok. Sürümü **pinleyin** (`firebase_core: 5.0.0` vb., caret yok) ve `pubspec.lock`'u commit edin. Bir haftalık major sürüm risk taşıyor, ama web tarafı değişmediği için 5.x/7.x'te kalmak makul. Sorun çıkarsa 4.15/6.x'e dönüş planı hazır olsun. `cloud_functions` paketi de gerekli (sürümü ayrıca pinlenmeli).
**Güven:** Orta (yeni major sürüm). **Spike:** Boş bir Flutter web + FlutterFire uygulamasıyla auth, listener ve callable'ın uçtan uca çalıştığını görün ve ağ waterfall'ını R1'e verin.

---

## 9. Veri silme (KVKK)

**Öneri:** Admin SDK script'i (`scripts/purge-event.ts`) ADC ile yerelden çalıştırılır:
1. Kişisel olmayan özet istatistikleri dışa aktar (oyuncu sayısı, bağlantı sayısı, dağılım).
2. `firestore.recursiveDelete(db.doc('events/{e}'))` ile tüm alt koleksiyonları sil.
3. Etkinliğin uid'leri için `auth.deleteUsers(uids)` (çağrı başına 1.000 uid).
4. Event dokümanını `archived` + `purgedAt` ile yeniden yaz.

Script dry-run modunda başlar ve "silinecek N doküman, M kullanıcı" onayı ister (FR-33). İstemciden toplu silmeyi (kurallarla) önermiyorum: 3.000+ doküman, sayfalama, yarıda kalma riski ve Auth kullanıcılarını silememesi. FR-33 UI'ı yalnız bir `purgeEvent` callable'ını tetikleyebilir. Bu callable aynı mantığı function içinde, admin claim kontrolüyle çalıştırır. Ayrıca PITR/backup açık olmamalı, log saklama süresi aydınlatma metninde belirtilmeli.
**Güven:** Yüksek. **Spike:** Emülatörde bir dry-run ve gerçek silme testi.

---

## Önerilen veri modeli (Blaze)

```
events/{eventId}                      public read; write: admin callable
  name, state: draft|lobby|live|ended|archived, liveStartAt?, liveEndAt?
events/{eventId}/private/config       admin only
  joinCode, joinCodeRotatedAt, appCheckEnforce, cooldownSec, maxConnPerPlayer, maxPlayers
events/{eventId}/players/{uid}        get: signed-in; list: staff or limit<=20; write: false
  displayName, interests[], playerCode, score, connectionCount,
  lastConnectionAt, disqualified, joinedAt
events/{eventId}/playerSecrets/{uid}  read: owner only; write: false
  totpSeed
events/{eventId}/playerCodes/{code}   read/write: false (functions only)
  uid
events/{eventId}/connections/{minUid_maxUid}  read: participants / staff; write: false
  participants[a,b], scannerUid, targetUid, points, bonus, questionId, createdAt
events/{eventId}/rateLimits/{uid}     functions only
  windowStart, attempts, failures
events/{eventId}/joinAudit/{uid}      admin only (KVKK: purged with event)
  ipHash, userAgent, joinedAt
questions/{pairKey}  or Hosting JSON  read: signed-in; write: admin script
Custom claims: admin, projector
Callables: join, connect, setEventState, rotateJoinCode, disqualify, purgeEvent
```

---

## Özet karar önerileri

1. **Blaze + callable function'lar** (`join`, `connect`, admin işlemleri). İstemci hiçbir oyun dokümanına yazmaz. Kurallar okuma kontrolü ve sorgu sınırından ibaret.
2. **Oyuncu kimliği `join()` + custom token.** Anonim auth'un 100 hesap/saat/IP limitini aşmanın tek pratik yolu bu. Spike ile doğrulanmalı.
3. **Jeton TOTP** (sunucuda üretilen seed + HMAC, 30 sn, önceki pencere de geçerli). Rotasyon yazma gerektirmez.
4. **Bölge `europe-west3`** (Firestore + Functions aynı yerde). gcping ile teyit edilmeli.
5. `connect()`: `minInstances: 1` (yalnız etkinlik günü), `maxInstances: 10`, `concurrency: 80`, `timeout: 10s`.
6. Leaderboard **yalnız projeksiyonda**, istemci tarafında hesaplanır. Oyuncu kendi puanını görür.
7. **App Check monitor-only ile başlar**, provada doğrulanmış istek oranı %98'in üzerindeyse enforce edilir. Anahtar config dokümanından gelir, deploy gerekmez.
8. Admin ve projeksiyon için Google ile giriş + custom claim + 2 adımlı doğrulama.
9. Bütçe uyarıları ($5/$20/$50). Etkinlik sırasında billing'i kapatan otomatik tavan kurulmaz.
10. FlutterFire 5.0.0/7.0.0 sürümleri pinlenir. Rules ve function testleri emülatörde, CI'da zorunlu.

## Riskler

| Risk | Olasılık | Etki | Azaltma |
|---|---|---|---|
| Custom token girişi de per-IP limitine takılır | Düşük-orta | Yüksek | Spike; mobil veri yönlendirmesi; katılımı lobby'ye yaymak |
| Function cold start veya gecikme p95 > 1 sn | Düşük (`minInstances` ile) | Orta | Spike ölçümü, optimistik UI |
| App Check gerçek oyuncuları reddeder | Orta | Yüksek | Monitor-only + çalışma anında açılıp kapanan bayrak |
| Telefon saati kayık, TOTP reddedilir | Düşük | Orta | `serverTime` offset, ±1 pencere |
| Yeni FlutterFire major sürümünde web hatası | Düşük-orta | Orta | Pinleme, 4.15/6.x geri dönüş planı |
| Prova gerçek projede kotayı veya per-IP limitini tüketir | Orta | Orta | Prova emülatörde veya ayrı staging projesinde |
| Sybil çiftliği | Orta | Düşük-orta | Katılım kodu, cooldown, FR-31 sinyalleri, diskalifiye |
| CSP Flutter/reCAPTCHA'yı kırar | Orta | Yüksek | Report-only prova, ardından enforce |
| Kötü niyetli sorgularla okuma amplifikasyonu | Düşük | Düşük-orta | Liste kuralları, `maxInstances`, bütçe uyarısı |
