# ADR-0012: Kötüye kullanım önlemleri: App Check, hız sınırları, bütçe, güvenlik başlıkları

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** NFR-15, SEC-02, SEC-03, SEC-04, SEC-13, SEC-32, R2

## Bağlam

Blaze planında kötü niyetli trafik doğrudan maliyet demek. Ama aşırı sıkı önlemler gerçek oyuncuları reddederse oyun biter (G4). Önlemler kanıta dayalı olarak sıkılaştırılmalı.

## Karar

- **App Check (reCAPTCHA Enterprise):** İzleme modunda başlar. Provada doğrulanmış istek oranı ≥ %98 ise Firestore ve fonksiyonlarda zorunlu yapılır. Fonksiyonlarda bayrak `settings.appCheckEnforce`'tan okunur, deploy gerekmez. Emülatör ve CI'da debug token.
- **Hız sınırları (fonksiyon içinde):** Bağlantılar arası 15 sn cooldown, oyuncu başına en fazla 60 bağlantı, dakikada 10 hatalı QR (elle girişte 5), aşımda 60 sn bekleme. Etkinlik başına en fazla 200 oyuncu.
- **Bütçe:** $5 / $20 / $50 uyarıları. Otomatik faturalama kapatma kurulmaz: Google kaynakların geri dönüşsüz silinebileceği konusunda uyarıyor.
- **Hosting başlıkları:** CSP önce `Report-Only` ile provada, sonra zorunlu. Ayrıca HSTS, `frame-ancestors 'none'`, `Referrer-Policy: no-referrer`, `Permissions-Policy: camera=(self)`, `X-Content-Type-Options: nosniff`.
- **Web API anahtarı:** Cloud Console'da HTTP referrer ve API kısıtı.

## Sonuçlar

- Bütün eşikler `settings` içinde. Etkinlik sırasında yöneticinin panelinden değiştirilebilir.
- App Check'in iOS Safari ve uygulama içi tarayıcılardaki davranışı provada ölçülmeden zorunlu yapılmaz.
- CSP, Flutter, FlutterFire (gstatic) ve reCAPTCHA ile uyumlu olmalı. Report-only provası bunu kanıtlar.
