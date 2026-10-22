# ADR-0008: Projeksiyon grafiği kendi CustomPainter'ımız ile, oyun motoru yok

- **Durum:** Kabul edildi (S6 spike sonucuna bağlı)
- **Tarih:** 2026-10-22
- **İlgili:** FR-20, NFR-16, R1, R4

## Bağlam

Projeksiyonda 150 düğüm ve 1.500 kenarlık canlı bir ağ ≥ 30 fps ile çizilmeli. Yeni kenarlar animasyonla eklenmeli. Bu, oyunun salondaki "ortak an"ı.

## Seçenekler

1. Hazır paketler (`graphview` 1.5.1, `flutter_force_directed_graph` 1.0.8): widget tabanlı veya bu ölçekte denenmemiş.
2. **Flame** 1.38.2: tam bir oyun motoru, ihtiyacımızdan büyük ve paket boyutunu artırır.
3. **Kendi `CustomPainter`'ımız** + `Ticker` ile basit kuvvet simülasyonu (O(n²) itme, kenar yayları, sönümleme).

## Karar

**Seçenek 3.** Simülasyon saf Dart (`projector/graph/domain`), çizim ayrı. Fizik ile çizim arasında temiz bir sınır, böylece simülasyon birim testlenebilir. Oyunun geri kalanında da Flame kullanılmıyor.

## Sonuçlar

- 150 düğümde tick başına < 1 ms bekleniyor. Worker veya isolate gerekmez.
- Görsel dilin tamamı bizde: sanat yönüyle (D4) uyumlu çizim, kenar çizilme animasyonu.
- S6 spike'ı gerçek veri boyutuyla doğrular. Yetmezse kenar çizimi sadeleştirilir (ör. yalnızca son N kenar animasyonlu).
