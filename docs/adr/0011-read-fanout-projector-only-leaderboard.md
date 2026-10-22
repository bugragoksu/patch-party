# ADR-0011: Sıralama yalnızca projeksiyonda, istemcide hesaplanır

- **Durum:** Kabul edildi. Oyuncu tarafı ADR-0014 ile değişti: oyuncu kendi sırasını görür, ama sıra sunucuda hesaplanıp kendi belgesine yazılır. Global sıralamayı dinleme yasağı geçerli
- **Tarih:** 2026-10-22
- **İlgili:** FR-09, FR-21, NFR-01, NFR-09, SEC-01, R2, R3

## Bağlam

Firestore dinleyicileri her değişiklikte her dinleyiciye okuma faturalar. 150 oyuncu canlı top-10 sorgusunu dinlerse her puan değişikliği ~150 okuma eder. 1.500 bağlantıda bu ~150 bin okuma demek: günlük ücretsiz kotanın (50 bin) üç katı.

## Seçenekler

1. Her oyuncu canlı sıralamayı dinler.
2. Ayrı bir sayaç/sıralama belgesi: sıcak belge, yazma çekişmesi.
3. **Sıralama yalnızca projeksiyonda**, projeksiyonun zaten dinlediği `players` akışından istemcide hesaplanır.

## Karar

**Seçenek 3.** Oyuncu yalnızca etkinlik belgesini, kendi oyuncu belgesini ve kendi bağlantılarını dinler. Oyuncunun sırası oyun bitince (`ended`) bir kez hesaplanır ve gösterilir. Kurallar oyuncuların `players` listesini `limit ≤ 20` ile, tam listeyi yalnızca `projector`/`admin` claim'leriyle sınırlar.

## Sonuçlar

- Tahmini etkinlik günü kullanımı ~41 bin okuma, ~6,5 bin yazma: ücretsiz kota içinde.
- Oyuncular oyun sırasında kendi sıralarını göremez. Projeksiyondaki sıralama salonun ortak odak noktası olur, bu da tasarım açısından istenen bir şey.
