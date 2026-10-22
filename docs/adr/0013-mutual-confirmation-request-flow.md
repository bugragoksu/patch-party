# ADR-0013: Karşılıklı onay: bağlantı isteği ve onay

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** FR-06, FR-07, FR-11, FR-15, G3, SEC-11, SEC-13, SEC-14, `../design/figma-review-v1.md` (DS3)

## Bağlam

İlk mimaride tek okutma yeterliydi: QR geçerliyse bağlantı anında kurulup puan yazılıyordu. Figma tasarımındaki Ekran 05 bir onay adımı içeriyor ve bu karar onaylandı (DS3). Onay, iki kişinin de tanışmaya rıza gösterdiğini gösterir ve "birinin ekranını omzunun üstünden okutma" durumunu engeller. Bedeli bir ağ turu ve biraz daha karmaşık bir durum makinesi.

## Seçenekler

1. **Tek fonksiyon, onay istemci tarafında:** İstemci onaylayınca `connect` çağırır. Onayın gerçekten hedef tarafından verildiği sunucuda kanıtlanamaz.
2. **İki fonksiyon, istek belgesi:** `requestConnection` jetonu doğrulayıp bekleyen istek yazar. `respondToRequest` yalnızca hedef tarafından çağrılabilir ve onayda bağlantıyı ve puanı yazar.
3. Onay için ikinci bir QR okutma (iki yönlü okutma): en güvenlisi ama en yavaşı.

## Karar

**Seçenek 2.**
- İstek belgesi ikili başına tek: `connectionRequests/{minUid_maxUid}`. Durumlar: `pending`, `accepted`, `declined`, `expired`, `cancelled`.
- Varsayılan süre 45 sn (`settings.requestTtlSec`). Süre aşımı onay anında sunucu saatiyle kontrol edilir. Zamanlanmış temizlik işi yok.
- Okutanın tek açık giden isteği, hedefin en fazla 3 bekleyen gelen isteği olabilir.
- Aynı anda iki taraf birbirini okutursa ikinci istek, mevcut bekleyeni doğrudan onaylar.
- Puan ve rozetler yalnızca onay transaction'ında yazılır.

## Sonuçlar

- Bağlantı süresi bir onay dokunuşu kadar uzar. G3 hedefi buna göre ikiye ayrıldı: istek ≤ 1 sn, onaydan sonra iki tarafta başarı ≤ 2 sn.
- Yeni bir kötüye kullanım yolu: istek spam'i. İstek sınırları ve mevcut hız sınırları bunu kapsar.
- Sahte hesap çiftliği (SEC-13) onayla engellenmez, çünkü saldırgan kendi hesaplarını onaylayabilir. Katılım kodu ve şüpheli tespiti bu konuda geçerliliğini korur.
- Test matrisine yeni senaryolar eklenir: süresi dolmuş istek, başkasının isteğini onaylama, karşılıklı eşzamanlı istek, istek sınırları.
- Okuma ve yazma maliyeti bağlantı başına yaklaşık iki katına çıkar (istek + onay). Etkinlik ölçeğinde ücretsiz kota içinde kalır.
