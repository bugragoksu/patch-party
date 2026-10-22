# ADR-0009: Animasyonlar önce sade Flutter, Rive üstüne yükseltme

- **Durum:** Kabul edildi. **Güncelleme (2026-10-22):** İlk sürüm tamamen Rive'sız yapılacak. Rive bir sonraki sürüme ertelendi. Aşağıdaki "sade Flutter" katmanı artık tek uygulama. S4 spike'ı ve Rive Cadet planı şimdilik gerekmiyor
- **Tarih:** 2026-10-22
- **İlgili:** FR-12, NFR-02, NFR-11, NFR-16, R4, D3, D4

## Bağlam

Ürün bir web sitesi değil, oyun gibi hissettirmeli. Rive ile kaliteli rozet ve kutlama animasyonları yapılabilir. Ama Rive'ın web çalışma zamanı ~0,8 MB (brotli), web'de açık hatalar var (çok widget'ta boş animasyon, bellek artışı) ve Rive işi yeni başlayan biri için 15-25 saat.

## Seçenekler

1. Her şey Rive: oyun Rive'a bağımlı olur, yükleme ağırlaşır.
2. Rive yok: daha düşük kalite tavanı.
3. **Önce sade Flutter, Rive yükseltme olarak.**

## Karar

**Seçenek 3.**
- Her animasyon anının (bağlantı kuruldu, rozet kazanıldı, kazananlar) önce sade Flutter sürümü yapılır.
- Rive çalışma zamanı ve `.riv` dosyaları oyuncu katıldıktan sonra arka planda, kendi alan adımızdan (`RIVE_NATIVE_WASM_HOST`) yüklenir. İlk açılışa girmez.
- Tek bir Rive "rozet kabuğu", data binding ile 4 rozeti sürer. Ekranda aynı anda en fazla 2-3 Rive widget'ı, `Factory.flutter`, oynatma bitince dispose.
- `settings.features.rive` ile deploy gerekmeden kapatılabilir. Rive yüklemesi başarısız olursa sessizce sade sürüme düşülür.
- `prefers-reduced-motion` iki sürümde de uygulanır.
- Karar noktaları: Cuma 12:00 ve Cumartesi 14:00.

## Sonuçlar

- Oyun Rive olmadan da eksiksiz. Rive geç kalırsa etkinlik etkilenmez.
- Her animasyon için iki uygulama: ek iş. Sade sürümlerin kısa tutulmasıyla sınırlanır.
- Rive Cadet planı (kişi başı aylık 9 $), dışa aktarma kısıtları belirsizliğini kaldırmak için.
