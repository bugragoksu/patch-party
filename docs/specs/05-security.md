# Bağlantı Ağı: Güvenlik ve Tehdit Modeli

- **Sürüm:** 0.1 (taslak)
- **Tarih:** 2026-10-22
- **Bağlam:** Firebase Blaze planı onaylandı (2026-10-22). Ücretli plan, "faturayı şişirme" saldırısını (denial-of-wallet) gerçek bir risk yapar.
- **Durum:** Önlemlerin "nasıl"ı araştırma R2 ve R3 sonrasında mimari dokümanda ve ADR'larda kesinleşecek. Bu doküman "neyi, neden" koruduğumuzu tanımlar.

## 1. Korunan varlıklar

| Varlık | Neden önemli |
|---|---|
| Faturalandırma hesabı | Blaze'de kötüye kullanım doğrudan para kaybı demek |
| Oyunun adilliği (puan, sıralama) | Ödül varsa hile motivasyonu yüksek. Sahnede yanlış kazanan ilan etmek itibar kaybı |
| Oyunun erişilebilirliği | 15 dakikalık canlı oyun. Kesinti telafi edilemez |
| Katılımcı verisi (görünen ad, ilgi alanları) | KVKK. Az veri tutuyoruz ama yine de kişisel veri |
| Yönetici yetkisi | Oyun durumunu, sonuçları ve silme işlemini kontrol eder |
| Projeksiyon ekranı | 100 kişinin baktığı ekranda uygunsuz içerik çıkması |

## 2. Saldırgan profilleri

| Profil | Yetenek | Motivasyon |
|---|---|---|
| A1: Meraklı katılımcı | Tarayıcı geliştirici araçları, ekran görüntüsü, WhatsApp | Kolay puan |
| A2: Teknik katılımcı | Firebase web yapılandırmasını okuyup kendi script'iyle doğrudan Firestore/Functions'a istek atar | Kazanmak, "kırabilir miyim" denemesi |
| A3: Dış saldırgan | Linki ele geçirir, otomasyonla yüksek hacimli istek atar | Vandalizm, fatura şişirme |
| A4: Hesap ele geçiren | Yönetici veya Firebase konsol hesabına erişim | Veri, kontrol |

Varsayım: Firebase web yapılandırması (API anahtarı dahil) herkese açıktır ve A2 bunu kullanabilir. Güvenlik bu anahtarın gizliliğine dayanmaz.

## 3. Tehditler ve önlemler

Her önlem bir `SEC-xx` kimliği taşır. **Doğrulama** sütunu, önlemin nasıl kanıtlanacağını söyler.

### 3.1 Fatura ve erişilebilirlik

| Kimlik | Tehdit | Önlem | Doğrulama |
|---|---|---|---|
| SEC-01 | A3, Firestore'a sınırsız okuma/yazma ile faturayı şişirir | Yalnızca kimliği doğrulanmış istek. Kurallar sorgu boyutunu sınırlar (`limit`), liste sorgularını yalnızca gereken koleksiyonlarda açar | Kural testleri |
| SEC-02 | A3, Cloud Functions'ı yüksek hacimle çağırır | Fonksiyonlarda `maxInstances` ve eşzamanlılık sınırı, kullanıcı başına hız sınırı, App Check zorunluluğu | Yük testi, yapılandırma incelemesi |
| SEC-03 | Beklenmeyen maliyet fark edilmez | Bütçe uyarıları (%50, %90, %100), etkinlik öncesi ve sırasında maliyet izleme. Sert harcama tavanının riskleri R2'de değerlendirilecek | Uyarı testi |
| SEC-04 | Uygulama dışı istemciler (script, bot) | Firebase App Check (web: reCAPTCHA). Zorunlu mu yoksa izleme modunda mı olacağı R2'ye göre | Emülatör ve staging testi |

### 3.2 Oyunun adilliği

| Kimlik | Tehdit | Önlem | Doğrulama |
|---|---|---|---|
| SEC-10 | A1, QR'ın ekran görüntüsünü başkalarına gönderir | Jeton 30 sn'de bir değişir, yalnızca güncel ve bir önceki jeton kabul edilir | Birim + kural/fonksiyon testi |
| SEC-11 | A2, puanını veya başkasının puanını doğrudan yazar | Puan istemciden kabul edilmez. Sunucu tarafında türetilir veya kurallarla tam olarak doğrulanır | Saldırı senaryolu testler |
| SEC-12 | A2, jeton olmadan veya rastgele jetonlarla bağlantı denemesi (brute force) | Jeton tahmin edilemez (kriptografik rastgele, yeterli uzunluk). Hatalı denemeler kaydedilir ve hız sınırına takılır | Test + şüpheli listesi |
| SEC-13 | A2, çok sayıda sahte oyuncu açıp kendi aralarında bağlantı kurar (Sybil) | Katılım için projeksiyon QR'ındaki ve dönen bir etkinlik kodu gerekli. Hesap başına bağlantı hızı sınırı. Grafikte "yalnızca birbirine bağlı yeni hesaplar" kümesi şüpheli işaretlenir. Ödül öncesi yönetici incelemesi | Şüpheli tespiti testi, yönetici akışı |
| SEC-14 | Aynı ikili için tekrar tekrar bağlantı | İkili için deterministik belge kimliği (sıralı uid'ler), tek yazma | Kural/fonksiyon testi |
| SEC-15 | `live` dışındaki durumlarda veya oyun bittikten sonra yazma | Etkinlik durumu sunucu tarafında kontrol edilir | Test |

### 3.3 Veri ve gizlilik

| Kimlik | Tehdit | Önlem | Doğrulama |
|---|---|---|---|
| SEC-20 | A2, tüm oyuncu listesini ve jetonları çeker | Jeton belgeleri sahibinden başkasına okunamaz. Herkese açık profil yalnızca görünen ad, ilgi alanları ve puan içerir | Kural testleri |
| SEC-21 | Gereğinden fazla kişisel veri | E-posta, telefon, konum toplanmaz. Katılımda aydınlatma metni. `archived` durumunda tam silme | Veri modeli incelemesi, silme testi |
| SEC-22 | Loglarda kişisel veri | Hata raporlarında yalnızca anonim uid. Görünen ad loglanmaz | Log örneklerinin incelemesi |

### 3.4 İçerik ve arayüz

| Kimlik | Tehdit | Önlem | Doğrulama |
|---|---|---|---|
| SEC-30 | Projeksiyonda uygunsuz görünen ad | Ad uzunluk ve karakter kısıtı, basit küfür filtresi, yöneticinin adı gizleme/değiştirme yetkisi | Birim testi, yönetici akışı |
| SEC-31 | Görünen ad üzerinden enjeksiyon | Ad her yerde düz metin olarak çizilir, HTML olarak yorumlanmaz. Sunucuda da doğrulanır | Test |
| SEC-32 | Sitenin başka bir sayfada çerçeve içinde gösterilmesi (clickjacking), zayıf tarayıcı ayarları | Hosting güvenlik başlıkları: CSP, HSTS, `frame-ancestors`, `Referrer-Policy`, kamera için `Permissions-Policy` | Başlık taraması |

### 3.5 Yönetim ve tedarik zinciri

| Kimlik | Tehdit | Önlem | Doğrulama |
|---|---|---|---|
| SEC-40 | A4, yönetici yetkisini ele geçirir veya istemci tarafında "admin" bayrağı uydurur | Yönetici yetkisi sunucuda (custom claim veya izin listesi). Yönetici Google hesabında iki adımlı doğrulama zorunlu | Kural testi |
| SEC-41 | Firebase/Google Cloud konsoluna yetkisiz erişim | En az yetki ilkesi, tüm üyelerde 2FA, etkinlik sonrası gereksiz erişimlerin kaldırılması | Kontrol listesi |
| SEC-42 | Servis hesabı anahtarı veya gizli bilgi repoya sızar | Repoda anahtar yok. CI için workload identity veya kısıtlı gizli değişkenler. Secret scanning açık | CI kontrolü |
| SEC-43 | Gemini API anahtarı istemciye sızar | İstemcide AI çağrısı yok. Soru üretimi yalnızca yerel script ile yapılır | Kod incelemesi |
| SEC-44 | Kötü niyetli veya bozuk bağımlılık | Kilit dosyaları commit edilir, sürümler sabitlenir, bağımlılık güncellemeleri inceleyerek alınır | CI |

## 4. Etkinlik günü güvenlik kontrol listesi

- [ ] Güvenlik kuralları ve fonksiyonlar en son test edilen sürümle canlıda
- [ ] App Check durumu doğrulandı (zorunlu veya izleme)
- [ ] Bütçe uyarıları aktif, uyarı alıcıları doğru
- [ ] Yönetici hesabı 2FA ile, yedek yönetici belirlendi
- [ ] Test verisi temizlendi
- [ ] Yayın dondurma: etkinlik boyunca deploy yok
- [ ] Etkinlik sonrası: veri silme tarihi takvimde, gereksiz erişimler kaldırıldı

## 5. Kabul edilen riskler

- Yan yana duran iki kişi QR'ı tanışmadan okutabilir. Sistem yüz yüze tanışmayı kanıtlayamaz, yalnızca uzaktan hileyi zorlaştırır.
- Etkinlik linki ve kodu, dönme penceresi içinde salon dışına iletilebilir. Etki küçük: yalnızca katılım sağlar, puanı salondaki birinin QR'ı olmadan artıramaz.
