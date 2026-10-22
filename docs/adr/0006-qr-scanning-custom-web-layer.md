# ADR-0006: QR okuma için Flutter dışında ince bir web katmanı

- **Durum:** Kabul edildi (S2 spike sonucuna bağlı)
- **Tarih:** 2026-10-22
- **İlgili:** FR-04, FR-05, NFR-10, R1

## Bağlam

`mobile_scanner` 7.4.2 iPhone'da kullanılamıyor: video elemanında `playsinline` yok, önizleme siyah tam ekrana atlıyor (#1785, açık). Flutter 3.42+ ile iOS Safari'de platform view önizlemesi yarı siyah (#1655). Ayrıca paket çözücüleri çalışma anında üçüncü taraf CDN'lerden yüklüyor. iOS Safari'de `BarcodeDetector` varsayılan olarak kapalı.

## Seçenekler

1. `mobile_scanner` olduğu gibi: iPhone'da çalışmıyor.
2. `mobile_scanner` fork'u + iki satırlık `playsInline` düzeltmesi: CDN bağımlılığı ve #1655 kalır.
3. **Kendi katmanımız:** Flutter canvas'ının dışında `position: fixed` bir `<video playsinline muted autoplay>`. Çözücü olarak Android'de yerel `BarcodeDetector`, iOS'ta self-host zxing-wasm. Yaklaşık 150 satırlık `package:web` kodu.

## Karar

**Seçenek 3**, `CameraScanner` arayüzünün arkasında. Her zaman bir dokunuş uzakta elle kod girişi (FR-05). QR içeriği URL olduğu için yerleşik kamera da son çare olarak çalışır (ADR-0004). Plan B: Seçenek 2.

## Sonuçlar

- Platform view regresyonlarından ve üçüncü taraf CDN'lerden bağımsız.
- Bakımını biz yapıyoruz. Arayüz sayesinde testte sahte okuyucu kullanılır.
- zxing-wasm (~0,36 MB) yalnızca iOS'ta ve okutma ekranı açılınca yüklenir.
- S2 spike'ı (iOS 18 ve 26 Safari/Chrome, Android Chrome, Instagram in-app) bu katmanı ve Flutter sürümünü birlikte doğrular.
