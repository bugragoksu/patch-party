# ADR-0004: Dönen jetonlar TOTP tabanlı, QR içeriği URL, ortak test vektörleri

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** FR-03, FR-05, SEC-10, SEC-12, SEC-13, R2

## Bağlam

QR'ın ekran görüntüsüyle paylaşılması işe yaramamalı. Katılım kodu da salon dışına sızınca kısa sürede geçersizleşmeli. Rotasyon veritabanı yazması gerektirmemeli (maliyet, karmaşıklık). Elle giriş kodu kısa olmalı.

## Seçenekler

1. Her oyuncu her 30 sn'de yeni bir nonce yazar: ~18 bin yazma, yazma izni gerekir.
2. **TOTP:** Sunucu bir tohum üretir, istemci ve sunucu aynı zaman penceresinden aynı kodu hesaplar. Sıfır yazma.

## Karar

- **Oyuncu jetonu:** `HMAC-SHA256(totpSeed, eventId | floor(t/30))`. QR için 10 karakter (~50 bit), elle giriş için 4 rakam. Sunucu şimdiki ve önceki pencereyi kabul eder. Saat kayması `join` yanıtındaki `serverTime` ile düzeltilir.
- **Katılım kodu:** Aynı yöntem, `joinSeed` ve 5 dakikalık pencere, 6 karakter. Projeksiyon hesaplar, `join` doğrular.
- **QR içeriği bir URL:** `https://<host>/#/c/<oyuncuKodu>.<jeton>`. Yerleşik kamera ile okutulursa da uygulamayı açar.
- **Elle girişte daha sıkı hız sınırı** (dakikada 5 hatalı), çünkü 4 rakam daha kolay tahmin edilir.
- **Ortak test vektörleri:** TOTP ve puanlama hem Dart'ta hem TypeScript'te var. `shared/test-vectors/*.json` iki tarafın testlerinde de koşar.

## Sonuçlar

- Rotasyon bedava ve çevrimdışı çalışır.
- Tohumlar yalnızca sahibine (oyuncu) veya ekibe (katılım) okunabilir. Tohum sızarsa yalnızca o oyuncunun kodu taklit edilebilir. Etki küçük.
- İki dilde aynı algoritma, sessiz ayrışma riski taşır. Ortak vektörler bunu CI'da yakalar.
