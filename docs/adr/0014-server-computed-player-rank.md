# ADR-0014: Oyuncu sırası sunucuda, dakikada bir hesaplanır

- **Durum:** Kabul edildi. ADR-0011'i kısmen değiştirir
- **Tarih:** 2026-10-22
- **İlgili:** FR-09, FR-24, NFR-09, ADR-0011, `../design/figma-review-v1.md` (DS4)

## Bağlam

ADR-0011'de oyuncuların global sıralamayı dinlemesini okuma maliyeti yüzünden yasakladık (tahmini ~150 bin okuma). Tasarım ise oyuncuya kendi sırasını gösteriyor ("7. sıra, ilk %10") ve bu onaylandı (DS4).

## Seçenekler

1. Her oyuncu top-N sorgusunu dinler: kota dışı, reddedildi (ADR-0011).
2. **Zamanlanmış fonksiyon** dakikada bir tüm sırayı hesaplar ve oyuncunun kendi belgesine `rank` yazar. Oyuncu kendi belgesini zaten dinlediği için ek dinleyici yok.
3. Her bağlantıdan sonra transaction içinde sıra güncellemek: sıcak belge, yazma çekişmesi, yarış durumları.

## Karar

**Seçenek 2.** `computeRanks`, `onSchedule("every 1 minutes")`, `europe-west3`. Etkinlik `live` değilse hemen çıkar. Diskalifiye oyuncuları çıkarır. Eşit puanda o puana önce ulaşan önde. Yalnızca sırası değişen oyunculara yazar. `ended` geçişinde son kez çalışır.

Projeksiyon için ADR-0011 geçerli kalır: projeksiyon sıralamayı kendi dinlediği `players` akışından anlık hesaplar.

## Sonuçlar

- Maliyet: dakikada ≤ 200 okuma ve ≤ 200 yazma. 15 dakikalık oyunda en kötü durumda ~3 bin okuma, ~3 bin yazma.
- Oyuncunun gördüğü sıra en fazla 1 dakika gecikmeli. Arayüz bunu "1 dk önce güncellendi" diye açıkça gösterir.
- Projeksiyondaki anlık sıra ile oyuncunun telefonundaki sıra kısa süreliğine farklı olabilir. Oyun sonunda ikisi aynı hesaplamadan gelir.
- Cloud Scheduler en az 1 dakikalık aralık destekliyor. Daha sık güncelleme gerekirse bu yaklaşım yetmez.
