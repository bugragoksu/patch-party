# Figma Tasarım İncelemesi v1

- **Tarih:** 2026-10-22
- **Kaynak:** Figma dosyası (12 ekran, bağlantı repoda tutulmaz), tasarım sistemi `figma-v1/DESIGN.md` ("Warm Pastel Social Connection"), ekran görüntüleri `figma-v1/`
- **Karşılaştırıldığı dokümanlar:** `../specs/01-requirements.md`, `../specs/02-architecture.md`, `../specs/05-security.md`, ADR'lar, `../research/r4-game-assets.md`

## 1. Özet

Ekran akışı gereksinimlerimizle büyük ölçüde örtüşüyor: katılım, dönen QR kartı, vizörlü okutma ve "kamera algılamıyor mu" yedeği, +10/+5 ayrımlı başarı ekranı, ortak soru, ilgi alanı kümelerine göre gruplanmış projeksiyon grafiği, kazananlar kürsüsü. Akış iskeleti olarak iyi bir başlangıç.

Üç ana sorun var:

1. **Sanat yönü onaylanan karardan farklı ve "AI slop" riskine yakın.** `DESIGN.md` Material 3 token yapısında, krem zemin + pastel bento kartlar + yüzen siyah pill navigasyon + Plus Jakarta Sans. Bu, R4'ün "kaçınılacak jenerik görünümler" listesindeki kalıba çok yakın ve onaylanan D4 ("Çıkartma Atölyesi", koyu zemin) ile çelişiyor.
2. **Bir oyun değil, bir uygulama/dashboard gibi hissettiriyor (NFR-16).** Ekranlar metin yoğun, alt navigasyonda 4-5 sekme var. Gürültülü bir salonda, 15 dakikalık bir oyunda ekranlar bir bakışta anlaşılmalı.
3. **Bazı ekranlar mimari ve güvenlik kararlarıyla çelişen özellikler varsayıyor:** profil fotoğrafları, iş unvanları, karşılıklı onay, oyuncuya canlı sıralama, kendi beyanına dayalı "sohbet tamamlandı" puanı. Ayrıntılar §3'te.

## 2. Ekran ekran

| Ekran | Karşılık gelen gereksinim | Uyumlu olan | Sorunlu olan |
|---|---|---|---|
| 01 Oyuna Giriş | FR-01, FR-22 | Net vaat ("Tanış, QR okut, bağlantı kur"), 3 adım, "uygulama indirmeden" mesajı | Çok metin. "Salonda 142 katılımcı aktif" oyuncuya canlı sayaç demek (okuma maliyeti, §3.4). Ürün adı "ChitChat v2.4", bizimki "Bağlantı Ağı" (karar gerekiyor) |
| 02 İsim ve İlgi Alanı | FR-01, FR-13 (NFR) | Takma ada izin, 2-3 ilgi alanı kuralı, 25 karakter sayacı | "Akıllı algoritma sohbeti kolaylaştırır" gibi abartılı iddia. Avatar görseli fotoğraf gibi duruyor (§3.1) |
| 03 Ana Ekran / QR Kodum | FR-03, FR-09 | Dönen QR kartı, geri sayım çubuğu, "30 saniyede yenilenir" bilgisi, büyük "Birinin Kodunu Tara" | Kısa kod yerine `PIXEL_7_PRO` (cihaz adı) yazıyor, olması gereken `K7M-4821` biçimi. QR ortasında logo var: hata düzeltme seviyesi M'de okunabilirliği düşürür. Kısa kodun elle girilebileceği belli değil |
| 04 QR Tarama & Vizör | FR-04, FR-05 | Vizör, ipuçları, "Kamera algılamıyor mu? Tekrar dene", "Benim QR Kodum" geçişi | Elle kod girişi butonu yok, sadece "Tekrar dene" var (FR-05 her zaman bir dokunuş uzakta olmalı). Uygulama başlığında Figma çerçeve adı görünüyor ("Ekran 04 — Qr Tarama & Vizör") |
| 05 Bağlantı İsteği | Yok | | **Karşılıklı onay akışı.** Mimaride tek okutma kararı verdik (§3.2). "Gemini 1 dakikalık soru hazırladı", "%94 uyum" ve "+50 puan" bizim puan modelimizle tutarsız |
| 06 Bağlantı Başarılı | FR-07, FR-11 | +10 ve +5'in ayrı kartlarda gösterilmesi, "projeksiyonda ağ güncellendi" geri bildirimi | "Liderlik tablosunda 7. sıra" ve "Seviye 3" oyuncuya canlı sıralama demek (§3.4). Çok fazla ikincil bilgi |
| 07 Ortak Sohbet Sorusu | FR-08 | Büyük, okunaklı soru metni, "Başka soru iste" | "Gemini 1.5 Pro" etiketi hem eski hem yanlış (canlı AI çağrısı yok). 2 dk geri sayım ve "Sohbeti Tamamla" doğrulanamaz bir eylem: puan verirse hile kapısı (§3.3). "Masa / Alan: Bölge #04" verisi yok |
| 08 Bağlantılarım | FR-09 | Liste, filtreler (Son eklenen, Farklı alanlar), bağlantı başına kazanılan puan | İş unvanları ("AI Researcher @ TechLab") toplanmıyor. "Bağlantı notu" kapsam dışı. Sıralama ve "İlk %10" yine görünüyor |
| 09 Oyun Bitti | FR-10, FR-12 | Rozetler, özet sayılar, oyun sonu duygusu | "Kartvizit olarak kaydet", "İletişim notları" kapsam dışı ve kişisel veri. "Günün hatırası" fotoğrafı yok. "Katılımcı ID #GDG-284" gereksiz |
| 10 Projeksiyon: Katılım QR | FR-22 | Büyük QR, 3 adım kartı, yeni katılanlar akışı | Statik PIN `#GDG2024`: bizim katılım kodumuz dönüyor (ADR-0004). Adım 1'de "GitHub/LinkedIn profilini ekle" yazıyor, toplamıyoruz. Yıl 2024/2025 yazıyor. Projeksiyonda sekmeli navigasyon var: projeksiyon etkileşimsiz, sahneler kendiliğinden dönmeli |
| 11 Projeksiyon: Canlı Ağ | FR-20, FR-21 | İlgi alanı kümeleri, "yeni köprü" vurgusu, ilgi alanı dağılımı, top 3 | "Canlı WebSocket" ifadesi teknik olarak yanlış. Arka sıradan okunamayacak kadar küçük metinler |
| 12 Projeksiyon: Kazananlar | FR-23 | Kürsü, özel ödüller, toplam istatistikler | Ödüller (Google sertifikası, VIP yemek, DevFest bileti) organizasyonca onaylanmalı. "Disiplinlerarası Kraliçe" cinsiyetli ifade. "Hız rekoru: ilk 45 saniyede eşleşme" hızlı ve yüzeysel okutmayı ödüllendirir, hile önlemlerimizle çelişir |

## 3. Mimariyle çelişen varsayımlar

### 3.1 Profil fotoğrafları ve iş unvanları
Ekranların neredeyse hepsinde gerçek kişi fotoğrafları ve unvanlar var. Biz yalnızca görünen ad ve ilgi alanı topluyoruz (SEC-21, KVKK). Google girişi de yok, yani fotoğraf kaynağı yok.
**Öneri:** Fotoğraf yerine addan ve ilgi alanlarından üretilen avatarlar (R4 önerisi). Unvan alanı yok.

### 3.2 Karşılıklı onay (Ekran 05)
Mimaride tek okutma kararı verdik: 100 kişide onay adımı akışı yavaşlatıyor, dönen QR zaten uzaktan hileyi engelliyor.
**Öneri:** Ekran 05'i kaldır. Karşı taraf onay yerine anında "Caner seninle bağlandı" bildirimi görür.

### 3.3 "Sohbeti tamamla" puanı (Ekran 07, 10, 12)
Sohbetin gerçekten yapıldığını doğrulayamayız. Puan verirse herkes hemen "tamamla"ya basar.
**Öneri:** Sohbet tamamlama puan vermez. Soru ekranı yalnızca sohbeti başlatır. Puan modeli: +10 bağlantı, +5 farklı alan bonusu. Ekranlardaki +15, +50, +70 değerleri bu modele göre düzeltilmeli.

### 3.4 Oyuncuya canlı sıralama ve sayaçlar (Ekran 01, 03, 06, 08)
ADR-0011: oyuncular global sıralamayı dinlemez, çünkü okuma maliyeti kotayı aşar.
**Seçenek:** Sıra bilgisi mutlaka isteniyorsa, bir zamanlanmış fonksiyon dakikada bir sıraları hesaplayıp her oyuncunun kendi belgesine `rank` yazabilir. Oyuncu zaten kendi belgesini dinlediği için ek okuma yok, yaklaşık 150 yazma/dakika. Bu bir ADR-0011 revizyonu olur.

### 3.5 Canlı AI iddiaları
"Gemini 1.5 Pro", "Gemini analiz etti", "%94 uyum" gibi ifadeler oyun sırasında canlı AI çalışıyormuş izlenimi veriyor. Sorular önceden üretiliyor.
**Öneri:** Dürüst ifade: "Gemini ile hazırlanmış soru". Uyum yüzdesi gibi uydurma metrikler yok.

## 4. Tasarım kalitesi

**İyi olanlar**
- Sıcak, samimi ton. Gergin "networking" havasını yumuşatıyor.
- QR kimlik kartı ve geri sayım çubuğu, oyunun ana nesnesini net gösteriyor.
- Projeksiyondaki ilgi alanı kümeleri grafiği güçlü bir "ortak an" fikri.

**Sorunlar**
- **Jenerik görünüm:** `DESIGN.md` bir AI tasarım aracının ürettiği tipik Material 3 token setine benziyor. Krem + pastel bento + Plus Jakarta Sans şu an çok yaygın bir kalıp. Kendine ait bir imza öğesi yok.
- **Oyun hissi zayıf:** Sabit sekme navigasyonu, uzun açıklama metinleri, dashboard kartları. Oyunda oyuncunun iki ana durumu var: "QR'ımı göster" ve "Tara". Bunlar tek bir ekranda, tek dokunuşla değişmeli.
- **Metin yoğunluğu:** Ekranların çoğunda 5-8 ayrı bilgi bloğu var. Gürültülü salonda telefona birkaç saniye bakılacak.
- **Okunabilirlik:** 11-13 px gri metinler krem zeminde düşük kontrastlı (NFR-11, WCAG AA). Projeksiyon ekranlarında metinler salonun arkasından okunamayacak kadar küçük.
- **Projeksiyon ve pastel:** Açık pastel tonlar projektörde soluklaşır. Karartılmış salonda koyu zemin ve yüksek kontrast daha iyi okunur.
- **Türkçe karakterler:** Bazı metinlerde `ş`, `ı`, `ğ` yerine `≡` görünüyor ("Ağ≡n", "Dağ≡lımı", "Arkadaş≡nın"). Plus Jakarta Sans'ın Google Fonts sürümü Türkçe karakterleri destekliyor (2026-10-22'de kontrol edildi). Yani sorun Figma'daki font kurulumunda veya kullanılan fontta. Final fontta mutlaka test edilmeli.
- **Çerçeve adı sızıntısı:** Ekran 03, 04 ve 08'in uygulama başlığında Figma çerçeve adı yazıyor.

## 5. Kararlar (2026-10-22)

| # | Karar | Sonuç |
|---|---|---|
| DS1 | Sanat yönü | **D4 "Çıkartma Atölyesi"** (R4 §7). Figma'daki ekran akışı korunur, görsel dil D4'e taşınır |
| DS2 | Ürün adı | **Belirlenmedi.** Çalışma adı "Bağlantı Ağı". Ad koda gömülmez: yerelleştirme dosyasında ve etkinlik ayarlarında tek yerde durur |
| DS3 | Karşılıklı onay (Ekran 05) | **Kalıyor.** Okutma bir bağlantı isteği oluşturur, karşı taraf onaylar. ADR-0013 |
| DS4 | Oyuncuya sıralama | **Gösterilir.** Sunucu dakikada bir hesaplar, oyuncunun kendi belgesine yazar. ADR-0014 (ADR-0011'i kısmen değiştirir) |
| DS5 | Fotoğraf ve unvan | **Üretilmiş avatar, unvan yok.** FR-16 |
| DS6 | Ödüller | Organizasyon onaylı listeyi verecek. Ekrandaki ödül metinleri ayarlardan gelir, koda gömülmez |

Ayrıca §3.3 (sohbet tamamlama puan vermez) ve §3.5 (canlı AI iddiası yok) önerileri geçerli. Puan modeli: +10 bağlantı, +5 farklı alan bonusu.
