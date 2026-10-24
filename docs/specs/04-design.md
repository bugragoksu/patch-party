# Bağlantı Ağı: Tasarım Spesifikasyonu

- **Sürüm:** 0.1
- **Tarih:** 2026-10-23
- **Sanat yönü:** D4 "Çıkartma Atölyesi" (R4 §7). Ekran akışı Figma v1'den, görsel dil prototipten.
- **Referans prototip:** Design canvas "Bağlantı Ağı Prototip" (telefon akışı + projeksiyon).

## 1. İlkeler

1. **Oyun, web sitesi değil.** Kaydırma yok, her ekran tek bir sahne. Oyuncunun iki ana durumu var: **QR'ım** ve **Tara**. Altta iki büyük buton, sekme çubuğu yok.
2. **Bir bakışta anlaşılır.** Ekran başına tek ana eylem, en fazla iki satır açıklama. Gürültülü salonda telefona birkaç saniye bakılacak.
3. **Çıkartma kuralı.** Öne çıkan her nesne bir çıkartmadır: kâğıt beyazı veya GDG rengi dolgu, 3 px koyu kontur, sert ofset gölge, hafif eğim. Kural tutarlılık sağlar ve jenerik görünümü engeller.
4. **Hareketin amacı var.** Yalnızca geri bildirim (istek gönderildi), ödül (bağlandınız, rozet) ve ortak an (projeksiyonda yeni bağlantı) için.
5. **Dürüst metin.** Canlı AI iddiası yok, uydurma metrik yok. "Gemini ile hazırlanmış soru".

## 2. Tokenlar

### Renk

| Token | Değer | Kullanım |
|---|---|---|
| `asphalt` | `#1C1B1F` | Zemin |
| `asphaltRaised` | `#26242A` | İkincil yüzey, pasif buton |
| `line` | `#3A373F` | Çizgi, ayraç |
| `paper` | `#F6F4EE` | Çıkartma dolgusu, zemin üstü ana metin |
| `ink` | `#141414` | Kontur, çıkartma üstü metin |
| `inkMuted` | `#4A4640` | Çıkartma üstü ikincil metin |
| `textMuted` | `#B9B4AA` | Zemin üstü ikincil metin (kontrast ≥ 7:1) |
| `blue` | `#4285F4` | Küme: Mobil & Web |
| `green` | `#34A853` | Küme: Yapay Zekâ & Veri, başarı |
| `yellow` | `#FBBC04` | Küme: Tasarım & Ürün, ana eylem, odak |
| `red` | `#EA4335` | Küme: Altyapı & Güvenlik, canlı göstergesi |

- GDG renklerinin üstüne her zaman `ink` metin yazılır (hepsinde kontrast ≥ 4.5:1).
- Hata durumu kırmızı dolguyla değil, `red` konturlu kâğıt çıkartmayla gösterilir: kırmızı küme rengiyle karışmasın.

### Tipografi

| Rol | Font | Ağırlık | Boyutlar |
|---|---|---|---|
| Başlık / sayı | Unbounded | 600, 800 | 34 / 28 / 24 / 20 / 15 |
| Arayüz | Google Sans Flex | 400, 500, 700 | 20 / 16 / 15 / 14 / 13 / 12 |
| Kod, sayaç | Google Sans Code | 500, 700 | 28 / 22 / 15 / 13 |

- Fontlar Latin + Türkçe karakterlere kırpılmış halde kendi alan adımızdan servis edilir (toplam ≤ 80 KB).
- Büyük harf etiketler 11-12 px, 0,1-0,12 em harf aralığı.
- Metin ölçekleme %200'e kadar düzeni bozmamalı.

### Şekil ve aralık

| Token | Değer |
|---|---|
| Kontur | 3 px (`ink` veya zeminde `paper`) |
| Ofset gölge | 4-8 px, bulanıklık yok, renk bağlama göre (`yellow` ana eylem, küme rengi bilgi) |
| Köşe | çip 999, buton 16, kart 18-24, büyük kart 28 |
| Eğim | çıkartma başına -2°…+2°, aynı ekranda en fazla iki farklı açı |
| Aralık ölçeği | 4, 8, 12, 14, 18, 22, 28 |
| Dokunma hedefi | ≥ 44 px, ana butonlar 56-60 px |

### Hareket

| Ad | Süre | Eğri | Nerede |
|---|---|---|---|
| `stamp` (damga) | 420 ms | ölçek 1,25 → 0,94 → 1, overshoot | "Bağlandınız", gelen istek kartı, rozet |
| `pop` | 300 ms, 120 ms aralıkla sıralı | ease-out, 12 px yukarı | Puan çıkartmaları |
| `sweep` | 1,6 sn, gidip gelen | ease-in-out | Tarama çizgisi |
| `pulse` | 1,2 sn döngü | ease-in-out | "Onay bekleniyor", canlı göstergesi |
| `ring` | 1,6 sn döngü | ease-out | Projeksiyonda yeni bağlantı |

`prefers-reduced-motion` (Flutter: `MediaQuery.disableAnimations`) açıkken döngüsel animasyonlar durur, giriş animasyonları anında son haline geçer.

## 3. Bileşenler

| Bileşen | Tanım |
|---|---|
| `Sticker` | Kâğıt veya renkli dolgu + kontur + ofset gölge + isteğe bağlı eğim. Diğer her şeyin tabanı |
| `PrimaryButton` | `yellow` dolgu, `Unbounded` 18, `paper` gölge. Pasif: `asphaltRaised`, gölgesiz |
| `DockButton` | Alt bar için ikili buton (QR'ım / Tara). Etkin: `yellow` çıkartma, pasif: `asphaltRaised` |
| `InterestChip` | Seçili: küme rengi + kontur + gölge. Seçilmemiş: şeffaf, `line` kontur |
| `Avatar` | Daire, ilk ilgi alanının küme rengi, baş harf (Unbounded), sağ altta ikinci ilgi alanının renginde döndürülmüş kare. Addan ve ilgi alanlarından deterministik |
| `QrCard` | Kâğıt çıkartma, `yellow` gölge, -2° eğim. 21×21 QR, süre çubuğu (`green`), kısa kod (Google Sans Code 22) |
| `ScoreBadge` | Kâğıt çıkartma, puan (Unbounded 20) + "PUAN" etiketi |
| `PointsSticker` | Renkli çıkartma: "+10 yeni bağlantı" (`blue`), "+5 farklı alan bonusu" (`green`) |
| `QuestionCard` | Kâğıt çıkartma, `red` gölge, "ORTAK SORUNUZ" etiketi, Unbounded 19 soru |
| `Notice` | Kesikli `yellow` kontur, zemin üstü metin: uyarı ve öneriler (ad alınmış, kamera yok) |
| `ErrorCard` | Kâğıt çıkartma, `red` kontur, ne olduğu + tek kurtarma eylemi |

## 4. Ekranlar ve durumlar

| Ekran | Durumlar |
|---|---|
| Katılım | boş, ad alınmış (öneri), ilgi alanı < 2 (buton pasif), gönderiliyor, katılım kodu geçersiz (projeksiyondaki QR'ı yeniden okut), oyun dolu, oyun kapalı |
| Lobi | oyun başlamadı: QR'ım görünür, okutma pasif ve "Oyun birazdan başlıyor" |
| QR'ım | normal, saat kayması düzeltildi, çevrimdışı (QR soluk + "bağlantı bekleniyor") |
| Tara | kamera izni isteniyor, açık, izin reddedildi → elle kod, 10 sn okunamadı → elle kod önerisi |
| Elle kod | biçim hatası anında, gönderiliyor, hatalar (`GameFailure` metinleri) |
| Onay bekleniyor | geri sayım, reddedildi ("Şu an olmadı"), süresi doldu, iptal |
| Gelen istek | tek istek, birden fazla istek (sıralı, en fazla 3), süresi doldu |
| Bağlandınız | +10, +10 ve +5, rozet açıldı (P1) |
| Bağlantılarım | boş ("İlk bağlantını kur"), liste |
| Oyun bitti | özet, sıra, rozetler |
| Projeksiyon | lobi (katılım QR'ı + yeni katılanlar), canlı (ağ + ilk 10 + sayaçlar), duraklatıldı, kazananlar |

`GameFailure` metinleri tek bir yerelleştirme dosyasında, her biri "ne oldu + ne yapmalı" biçiminde: örn. `tokenExpired` → "Kod yenilendi. Bir kez daha okut."

## 5. Projeksiyon

- 1920×1080 için tasarlanır, 1280×720'de de okunur. En küçük metin 20 px, sayılar ≥ 26 px.
- Etkileşimsiz: sekme yok, sahneler etkinlik durumuna göre kendiliğinden değişir.
- Ağ: düğüm = oyuncu (avatar rengi), kenar = bağlantı. Küme içi kenar küme renginde, kümeler arası kenar `paper`, en yeni kenar `yellow` ve kalın + `ring`.
- Koyu zemin projektörde solmayı engeller, kontrast her zaman yüksek tutulur.

## 6. Erişilebilirlik

- Bütün etkileşimli öğeler gerçek buton/alan, anlamlı etiketlerle (Flutter `Semantics`).
- Renk tek başına bilgi taşımaz: kümeler hem renk hem adla, seçili çip hem renk hem kontur/gölgeyle ayrılır.
- Odak göstergesi: 3 px `yellow` çerçeve.
