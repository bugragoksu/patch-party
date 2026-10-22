# ADR-0001: Flutter web, tek uygulama, dart2js, Flutter 3.47.7

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** NFR-02, NFR-10, NFR-12, R1, R3, D1, D2

## Bağlam

Oyun telefon tarayıcısında, projeksiyonda ve yönetici panelinde çalışacak. Ekip Flutter biliyor ve etkinlik bir GDG etkinliği. İlk yükleme boyutu kritik: 100 telefon ortak Wi-Fi'da. Güncel paketler (go_router 18, sentry_flutter 10, very_good_analysis 11) Flutter ≥ 3.44 / Dart ≥ 3.13 istiyor.

## Seçenekler

1. **React/Vite:** En hafif ilk yükleme (~0,3 MB). Ekibin alanı değil, GDG hikâyesine daha az uygun.
2. **Flutter web, `--wasm`:** Android'de daha küçük ve hızlı. Ama iOS'ta hiçbir tarayıcı wasm yolunu kullanmıyor, `sentry_flutter` wasm uyumlu değil, Rive data binding wasm'da hata atıyor (rive-flutter #593).
3. **Flutter web, dart2js + CanvasKit:** Her platformda tek yol. Android'de ~1 MB daha ağır.
4. Üç ayrı Flutter uygulaması veya pub workspace monorepo.

## Karar

Flutter web, **tek uygulama, üç rota** (`/`, `/screen`, `/admin`), **yalnızca dart2js + CanvasKit**, Flutter **3.47.7** fvm ile sabit. Projeksiyon ve yönetici `deferred` import ile ayrı yüklenir. Motor ve fontlar kendi alan adımızdan servis edilir (`--no-web-resources-cdn`).

## Sonuçlar

- Tek derleme yolu, tek source map hattı, Sentry ve Rive sorunsuz.
- Kritik yol bütçesi iki platformda ≤ 2,9 MB (brotli).
- Android kullanıcıları skwasm'ın hız avantajını kaybeder. Bizim sahnelerimiz hafif olduğu için kabul edildi.
- Yedek: iPhone kamera spike'ı (S2) 3.47.7'de başarısız olursa 3.38.10 ve paketlerin eski ana sürümleri. Geri dönüş maliyeti: yarım gün, çoğu bağımlılık sürümü.
