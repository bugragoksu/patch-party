# Bağlantı Ağı: Gereksinimler

- **Sürüm:** 0.1 (taslak)
- **Tarih:** 2026-10-22
- **Etkinlik:** GDG Adana Info Session, 25 Ekim 2026 Pazar
- **Durum:** Açık sorular kısmen cevaplandı (bkz. §10)
- **İlgili:** `05-security.md` (tehdit modeli)

## 1. Bağlam

GDG Adana info session'ında yaklaşık 100 katılımcının birbiriyle tanışmasını sağlayacak, telefon tarayıcısından oynanan bir oyun.

Kodun kendisi de konuşmada gösterilebilecek kalitede olmalı.

## 2. Hedefler

| Kimlik | Hedef | Ölçüm |
|---|---|---|
| G1 | Salondakilerin çoğu oyuna katılır | Katılan oyuncu / salondaki kişi ≥ %80 |
| G2 | Gerçek tanışmalar olur | Oyuncu başına ortalama ≥ 5 bağlantı |
| G3 | Oyun hiç bekletmez | QR okut → "istek gönderildi" p95 ≤ 1 sn, onay → iki tarafta başarı p95 ≤ 2 sn |
| G4 | Etkinlik sırasında oyunu durduran hata olmaz | Oyunu kesintiye uğratan olay sayısı = 0 |
| G5 | Konuşmada kod ve mimari gururla gösterilebilir | Ekip incelemesi |

## 3. Kapsam dışı

- Native iOS/Android uygulaması (yalnızca web).
- Google veya e-posta ile giriş. Oyuncu yalnızca isim girer.
- Oyun sırasında canlı Gemini çağrısı. AI içeriği etkinlikten önce üretilir (bkz. FR-40).
- Oyuncular arası mesajlaşma, sohbet, kalıcı sosyal profil.
- Birden fazla eş zamanlı etkinlik. Veri modeli `eventId` ile ayrılır ama yönetim arayüzü tek etkinlik içindir.

## 4. Roller ve yüzeyler

| Rol | Yüzey | Açıklama |
|---|---|---|
| Oyuncu | Telefon tarayıcısı | Katılır, QR gösterir/okutur, puanını görür |
| Projeksiyon | Salon ekranı (dizüstü) | Salt okunur: katılım QR'ı, canlı ağ, sıralama, kazananlar |
| Yönetici | Dizüstü veya telefon | Oyun durumunu yönetir, hileleri inceler, veriyi temizler |

## 5. Oyun durumları

```
draft ──▶ lobby ──▶ live ──▶ ended ──▶ archived
          (katılım   (bağlantı   (sonuçlar   (kişisel veri
           açık)      açık)       sabit)      silindi)
```

- Durumu yalnızca yönetici değiştirir. İsteğe bağlı olarak `live` için otomatik başlangıç ve bitiş saati ayarlanabilir.
- Durum, sunucu tarafındaki kurallarla zorlanır. Örnek: `live` dışında bağlantı yazılamaz.

## 6. Fonksiyonel gereksinimler

Öncelik: **P0** = etkinlik için şart, **P1** = olması güzel, zaman kalırsa yapılır, **P2** = sonraya.

### Oyuncu

| Kimlik | Öncelik | Gereksinim | Kabul kriteri |
|---|---|---|---|
| FR-01 | P0 | Katılım: isim (2-24 karakter) ve sabit listeden (§6.1) 2-3 ilgi alanı seçimi. Serbest metinle ilgi alanı girilemez | Kurulum veya hesap gerekmez. Katılım akışı ≤ 30 sn. Listede olmayan değer sunucuda reddedilir |
| FR-17 | P0 | Görünen ad etkinlik içinde benzersiz. Karşılaştırma büyük/küçük harf, Türkçe harf (İ/i, I/ı) ve boşluk farklarından bağımsız. Ad alınmışsa katılım engellenmez, ayırt edici bir öneri sunulur ("Deniz K.") | Eşzamanlı iki katılımda bile aynı ad iki kişiye verilmez (sunucu transaction'ı, testle kanıtlı). Öneri kabul edilebilir veya başka ad yazılabilir |
| FR-02 | P0 | Oturum sayfa yenilense de korunur | Yenileme, sekme kapatıp açma sonrası aynı oyuncu ve puan |
| FR-03 | P0 | Kişisel QR, belirli aralıklarla (varsayılan 30 sn) değişir. Altında aynı jetonun kısa kodu görünür | Süresi geçmiş jeton (bir önceki pencere hariç) reddedilir |
| FR-04 | P0 | Kamera ile başka oyuncunun QR'ını okutma | Kamera izni reddedilirse kullanıcı FR-05'e yönlendirilir |
| FR-05 | P0 | Kısa kodu elle girerek bağlantı kurma | FR-04 ile aynı doğrulama kuralları |
| FR-06 | P0 | Bağlantı kuralları: kendinle bağlantı yok, aynı ikili için tek bağlantı, yalnızca `live` durumunda, geçerli jetonla, karşı tarafın onayıyla (FR-15) | Kurallar sunucuda zorlanır, istemci atlatamaz (testle kanıtlı) |
| FR-07 | P0 | Anında geri bildirim. Okutan "istek gönderildi" durumunu, karşı taraf gelen isteği gerçek zamanlı görür | Okutan: istek sonucu p95 ≤ 1 sn. Karşı tarafa isteğin düşmesi p95 ≤ 2 sn. Onaydan sonra iki tarafta da başarı ekranı p95 ≤ 2 sn |
| FR-15 | P0 | Karşılıklı onay: okutma bir bağlantı isteği oluşturur. Karşı taraf isteği, okutanın adı, avatarı ve ilgi alanlarıyla görür, onaylar veya reddeder. İstek belirli süre (varsayılan 45 sn) içinde onaylanmazsa düşer | Puan yalnızca onayda yazılır. Oyuncunun aynı anda en fazla bir giden, en fazla üç bekleyen gelen isteği olabilir. Reddedilen veya süresi dolan istek puan vermez |
| FR-16 | P0 | Avatar: her oyuncuya adından ve ilgi alanlarından türetilen, kodla çizilen bir avatar. Fotoğraf yüklenmez, iş unvanı toplanmaz | Aynı girdi her cihazda aynı avatarı üretir |
| FR-08 | P0 | Bağlantı kurulunca iki tarafa aynı ortak soru gösterilir. Soru, ilgi alanı ikilisine göre hazır havuzdan seçilir | Canlı AI çağrısı yok. Havuzda soru kalmazsa genel havuza düşülür |
| FR-09 | P0 | Kendi puanım, sıram ve bağlantı listem | Liste bağlantı sırasına göre, isim, avatar ve ilgi alanlarıyla. Sıra en fazla 1 dk gecikmeli (FR-24) |
| FR-24 | P1 | Oyuncu sırası: sunucu `live` süresince dakikada bir tüm oyuncuların sırasını hesaplar ve her oyuncunun kendi belgesine yazar | Oyuncu global sıralamayı dinlemez. Diskalifiye oyuncular sıralamaya girmez |
| FR-10 | P1 | Oyun sonu özeti: kimlerle tanıştım, sıram, rozetlerim | `ended` durumunda otomatik açılır |
| FR-11 | P0 | Puanlama: yeni bağlantı +10, ortak ilgi alanı olmayan biriyle +5 bonus. Puan iki tarafa da yazılır | Puan sunucu tarafında türetilir veya kurallarla doğrulanır. İstemci puanı serbestçe yazamaz |
| FR-12 | P1 | Rozetler (örn. İlk Bağlantı, Köprü, Kaşif, Sosyal Kelebek), Flutter animasyonlarıyla. Rive sonraki sürümde (ADR-0009) | Rozet kazanılınca animasyonlu bildirim |

### Projeksiyon

| Kimlik | Öncelik | Gereksinim | Kabul kriteri |
|---|---|---|---|
| FR-20 | P0 | Canlı ağ grafiği: her oyuncu bir düğüm, her bağlantı bir kenar | 150 düğüm, 1.500 kenarda ≥ 30 fps; yeni kenar ≤ 2 sn içinde görünür |
| FR-21 | P0 | Canlı sıralama (ilk 10) ve sayaçlar (oyuncu, bağlantı) | Gerçek zamanlı |
| FR-22 | P0 | `lobby` ekranında büyük katılım QR'ı ve katılan sayısı | Uzaktan okunabilir |
| FR-23 | P0 | `ended` durumunda kazananlar ekranı | İlk 3 vurgulu |

### Yönetici

| Kimlik | Öncelik | Gereksinim | Kabul kriteri |
|---|---|---|---|
| FR-30 | P0 | Oyun durumunu değiştirme (FR §5) | Yalnızca yönetici kimliği. Kurallarla zorlanır |
| FR-31 | P1 | Şüpheli davranış listesi (kısa sürede çok bağlantı, çok hatalı deneme) | Eşikler yapılandırılabilir |
| FR-32 | P1 | Oyuncuyu diskalifiye etme / geri alma | Diskalifiye oyuncu sıralamada görünmez |
| FR-33 | P0 | Etkinlik verisini silme (`archived`) | Kişisel veri geri dönüşsüz silinir. Onay adımı var |

### İçerik

| Kimlik | Öncelik | Gereksinim | Kabul kriteri |
|---|---|---|---|
| FR-40 | P0 | Soru havuzu etkinlik öncesinde bir script ile Gemini'den üretilir, insan tarafından gözden geçirilir ve yayınlanır | 12 alanla 78 ikili: her ikili (aynı alan dahil) için ≥ 2 soru + ≥ 30 genel soru, toplam ~190 |

### 6.1 İlgi alanı kataloğu

Sabit liste, 12 alan, projeksiyondaki 4 renkli kümeye dağılır. Katalog tek bir dosyada tutulur ve istemci, sunucu ve soru üretimi aynı dosyayı kullanır.

| Küme (renk) | İlgi alanları |
|---|---|
| Mobil & Web (mavi) | Flutter & Mobil · Web & Frontend · Oyun Geliştirme |
| Yapay Zekâ & Veri (yeşil) | Yapay Zekâ & LLM · Veri & Analitik · Açık Kaynak |
| Tasarım & Ürün (sarı) | UI/UX & Tasarım · Ürün & Girişimcilik · Topluluk & Etkinlik |
| Altyapı & Güvenlik (kırmızı) | Backend & Cloud · DevOps · Siber Güvenlik |

- İlgi alanları uzmanlık beyanı değil, sohbet başlatıcıdır. Listede kendini bulamayan en yakın alanı seçer.
- Teknoloji dışı alanlar (kahve, spor) yok: "ortak alan yok" bonusunu anlamsızlaştırır.
- Bir oyuncunun avatar rengi ilk seçtiği alanın kümesinden gelir.

## 7. Fonksiyonel olmayan gereksinimler

| Kimlik | Alan | Gereksinim |
|---|---|---|
| NFR-01 | Ölçek | 150 eşzamanlı oyuncu (100 + %50 pay), etkinlik başına 1.500 bağlantı, 3 projeksiyon/yönetici istemcisi |
| NFR-02 | İlk yükleme | Orta seviye Android, 4G: ilk etkileşime kadar p75 ≤ 4 sn. Aktarılan bayt bütçesi araştırma (R1) sonrası belirlenecek |
| NFR-03 | Etkileşim gecikmesi | Oyuncu yolundaki hiçbir işlem ağ dışında bekletmez. Optimistik arayüz ve sunucu onayı |
| NFR-04 | Dayanıklılık | Bağlantı kısa süre koparsa oyun çökmeden devam eder ve yeniden bağlanınca senkronize olur. Tek bir istemci hatası başka kimseyi etkilemez |
| NFR-05 | Hata yönetimi | Yakalanmamış tüm hatalar bağlamıyla (oyuncu, durum, sürüm, tarayıcı) kaydedilir. Kullanıcıya teknik hata metni gösterilmez, kurtarma yolu sunulur |
| NFR-06 | Gözlemlenebilirlik | Etkinlik sırasında canlı izleme: aktif oyuncu, bağlantı hızı, hata sayısı, reddedilen yazma sayısı |
| NFR-07 | Güvenlik ve adil oyun | Tüm oyun kuralları sunucu tarafında. Jeton paylaşımı rotasyonla sınırlanır. Okutma hız sınırı. Yönetici yetkisi ayrı |
| NFR-08 | Gizlilik (KVKK) | Minimum veri: görünen ad ve ilgi alanları. Katılımda aydınlatma metni. Etkinlikten sonra ≤ 30 gün içinde silme |
| NFR-09 | Maliyet | Mümkünse Firebase ücretsiz kotası içinde. Ücretli plana geçilirse bütçe uyarısı zorunlu |
| NFR-10 | Uyumluluk | iOS Safari ve Android Chrome'un güncel ve bir önceki ana sürümü. Uygulama içi tarayıcılar (Instagram, WhatsApp) algılanır ve uyarılır. Kesin taban sürüm R1'den sonra |
| NFR-11 | Erişilebilirlik | WCAG AA kontrast, metin ölçekleme, `prefers-reduced-motion` ile animasyonların azaltılması |
| NFR-12 | Kod kalitesi | Katmanlı mimari, statik analiz sıfır uyarı, iş kuralları ve güvenlik kuralları için otomatik test, CI'da zorunlu kontrol |
| NFR-13 | Yerelleştirme | Türkçe birincil. Metinler koddan ayrık, İngilizceye hazır |
| NFR-14 | Yayın | Tek komutla tekrarlanabilir deploy. Etkinlik sırasında deploy yapılmaz, ayarlar arayüzden değişir |
| NFR-15 | Güvenlik | `05-security.md`'deki P0 önlemleri (SEC-xx) uygulanır ve testle doğrulanır. Ücretli plan nedeniyle fatura kötüye kullanımına karşı önlemler zorunlu |
| NFR-16 | Oyun hissi | Ürün bir web sitesi gibi değil, tarayıcıda çalışan bir oyun gibi hissettirir: tam ekran oyun düzeni, anlık görsel ve dokunsal geri bildirim, tutarlı sanat yönü. Asset'ler ilk yükleme bütçesini (NFR-02) aşmaz, gerekirse sonradan yüklenir |

## 8. Tasarım ilkeleri (detay `04-design.md`'de)

- Bir web sitesi değil, bir oyun: sayfa kaydırma, form ve link görünümü yerine oyun ekranları, sahneler ve geçişler.
- Hareket bir amaca hizmet eder: geri bildirim (bağlantı kuruldu), ödül (rozet), ortak an (projeksiyondaki ağ).
- İlk sürümde animasyonlar Flutter'ın kendi araçlarıyla (implicit/explicit animasyonlar, `CustomPainter`). Rive sonraki sürüme ertelendi (ADR-0009). Hazır şablon ve "AI slop" görünüm yok. Asset üretim yolu araştırma R4'te.
- Telefonda tek elle kullanım: QR ve okut butonu her zaman ulaşılabilir.

## 9. Riskler

| Risk | Etki | Azaltma |
|---|---|---|
| Salon Wi-Fi'ı 100 telefonu kaldırmaz | Katılım düşer | Hafif ilk yükleme, mobil veriyle de hızlı açılış, linkin konuşma başında paylaşılması |
| Flutter web ilk yükleme boyutu | Beyaz ekranda bekleme | R1 bulgularına göre derleme hedefi, ertelenmiş yükleme, açılış ekranı |
| iOS Safari kamera kısıtları | QR okunamaz | Elle kod girişi (FR-05) her zaman var |
| Teslim süresi 3 gün | Kapsam taşar | Katı P0/P1 ayrımı. P1'ler yalnızca P0 bitince |
| Projeksiyonda grafik performansı | Takılan animasyon | Düğüm/kenar sınırı, basit çizim, gerçek veriyle yük testi |

## 10. Açık sorular

| # | Soru | Etkisi |
|---|---|---|
| ~~Q1~~ | ~~Firebase Blaze planına geçebilir miyiz?~~ **Cevap (2026-10-22): Evet, sıkı güvenlik önlemleriyle.** Bkz. `05-security.md` | FR-06, FR-11, NFR-15 |
| Q2 | Puan iki tarafa da mı yazılsın, yoksa sadece okutana mı? | Hile dinamiği, FR-11 |
| Q3 | Oyuncu adları projeksiyonda herkese açık görünecek. Bu katılımda açıkça belirtilsin mi, takma ada izin verilsin mi? | KVKK, NFR-08 |
| Q4 | Oyun süresi kaç dakika? | Jeton rotasyonu, eşikler |
| Q5 | Yönetici kim olacak, kaç kişi? Yönetici girişi nasıl olsun (ör. Google ile tek hesap)? | FR-30 |
| Q6 | Özel alan adı kullanılacak mı? | Hosting, NFR-10 |
| Q7 | Ekip kaç kişi, kim hangi işi alacak? | Görev planı |
| Q8 | Ürün adı ne olacak? Çalışma adı "Bağlantı Ağı". Ad koda gömülmez | Yerelleştirme ve ayar metinleri |
| ~~Q9~~ | ~~Karşılıklı onay, oyuncuya sıralama, avatar, sanat yönü~~ **Cevap (2026-10-22):** onay var (FR-15), sıralama var (FR-24), üretilmiş avatar (FR-16), sanat yönü D4. Bkz. `../design/figma-review-v1.md` §5 | FR-06/07/09 |
