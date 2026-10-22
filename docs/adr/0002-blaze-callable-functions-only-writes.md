# ADR-0002: Blaze planı, bütün yazmalar callable Cloud Functions üzerinden

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** FR-06, FR-11, NFR-07, NFR-15, SEC-01, SEC-02, SEC-11, R2, Q1

## Bağlam

Oyunun adilliği (kendinle bağlantı yok, ikili başına tek bağlantı, geçerli jeton, puan) sunucu tarafında zorlanmalı. Bu, Spark planında yalnızca güvenlik kurallarıyla da yapılabilir. Blaze planı onaylandı (Q1).

## Seçenekler

1. **Yalnızca kurallar (Spark):** Batched write + `getAfter`. Çalışır, ama oyuncuların birbirinin belgesine yazma izni gerekir. Kurallar iş mantığıyla dolar. Jeton rotasyonu ~18 bin yazma eder. Hesap açma limitine (100/saat/IP) çözüm sunmaz.
2. **Callable fonksiyonlar (Blaze):** İstemci hiçbir oyun belgesine yazamaz. Mantık TypeScript'te, birim testlenebilir.
3. Hibrit: bazı yazmalar kurallarla, bazıları fonksiyonla.

## Karar

**Seçenek 2.** `join`, bağlantı işlemleri ve yönetici işlemleri callable fonksiyon. Firestore kurallarında bütün koleksiyonlar için `allow write: if false`. Kurallar yalnızca okumayı ve sorgu boyutunu sınırlar. Firestore ve Functions **`europe-west3`**. `maxInstances: 10`, `concurrency: 80`, `timeoutSeconds: 10`. Etkinlik günü `join` ve bağlantı fonksiyonları için `minInstances: 1`. (Bağlantı, ADR-0013 ile `requestConnection` + `respondToRequest` olarak ikiye ayrıldı.)

## Sonuçlar

- Güvenlik yüzeyi küçük, kurallar basit ve kolay test ediliyor.
- Sıcak yolda tahmini p95 200-400 ms. S5 spike'ı ile Adana'dan ölçülecek.
- Fatura kötüye kullanımı (denial-of-wallet) yeni bir risk. Bütçe uyarıları, instance sınırları, hız sınırları ve App Check ile azaltılır. Otomatik faturalama kapatma bilinçli olarak yok (yanlış alarm oyunu öldürür).
- Hibrit yok: bir yazmanın nereden geldiği sorusu her zaman "fonksiyondan".
- Geri dönüş maliyeti yüksek. Bu yüzden S1 ve S5 spike'ları Cuma sabahı ilk iş.
