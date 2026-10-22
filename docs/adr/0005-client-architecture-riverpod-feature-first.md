# ADR-0005: İstemci mimarisi: feature-first katmanlar, Riverpod 3, go_router, elle modeller, Result tipi

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** NFR-05, NFR-12, R3

## Bağlam

Kod konuşmada gösterilecek ve "kıdemli bir ekibin karar verdiği" kalitede olmalı. Ama 3 günde over-engineering yapmamalıyız. Test edilebilirlik öncelikli.

## Seçenekler

- State management: Riverpod 3, flutter_bloc 9, signals.
- Modeller: freezed / dart_mappable (build_runner gerekir) veya elle yazım (Dart 3.13 primary constructors).
- Hata modeli: exception, `fpdart` Either, kendi `Result` tipimiz.
- Yapı: tek paket + klasör kuralları veya pub workspace paketleri.

## Karar

- **Riverpod 3**, kod üretimi olmadan. Firestore akışları `StreamProvider`. Testte `ProviderContainer` override'ları, mock kütüphanesi yok.
- **go_router**, hash URL. Rol ve oturum kontrolü `redirect`'te.
- **Elle yazılmış modeller**, `sealed` sınıflar. Model sayısı 12'yi geçerse `dart_mappable`.
- **`Result<T>` + `sealed GameFailure`**: beklenen hatalar değer olarak döner, programcı hataları global yakalayıcıya gider.
- **Feature-first, yalın katmanlar:** presentation → application → domain ← data, artı `platform`. `domain/` saf Dart, CI'da import kontrolüyle zorlanır.
- **Lint:** `very_good_analysis`, sıfır uyarı CI'da zorunlu.

## Sonuçlar

- build_runner yok: daha hızlı geri bildirim döngüsü, daha az CI süresi.
- Elle `fromJson`/`toJson` yazmak hataya açık. Her model için gidiş-dönüş birim testi yazılır.
- Ekip bloc'a belirgin biçimde daha hakimse (Q7) bu karar yeniden açılabilir. Katman yapısı değişmez.
