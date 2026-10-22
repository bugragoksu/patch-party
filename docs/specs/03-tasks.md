# Bağlantı Ağı: Görev Planı

- **Sürüm:** 0.1
- **Tarih:** 2026-10-23
- **Girdiler:** `01-requirements.md`, `02-architecture.md`, `05-security.md`, ADR'lar
- **Çalışma biçimi:** Her paket tek bir ajana (veya kişiye) verilebilecek şekilde bağımsız. Her pakette dokunabileceği klasörler, girdisi, çıktısı ve kabul kriteri var. Bir paket başka bir paketin klasörüne yazmaz; ortak sözleşmeler (`shared/`, fonksiyon arayüzleri) önce gelir.

## Bağımlılık sırası

```
T00 iskelet ─┬─ T01 shared (katalog, vektörler) ─┬─ T02 backend domain ── T03 backend handler'lar ── T04 kurallar ve testler
             │                                    └─ T05 istemci domain
             └─ T06 uygulama kabuğu ── T07 tasarım bileşenleri ─┬─ T08 oyuncu akışı
                                                                ├─ T09 projeksiyon
                                                                └─ T10 yönetici
T11 soru havuzu (bağımsız) · T12 CI/CD (T00'dan sonra) · T13 yük testi ve spike'lar (T03'ten sonra) · T14 prova
```

## Paketler

| Kimlik | Paket | Klasörler | Gereksinimler | Kabul kriteri |
|---|---|---|---|---|
| T00 | Repo iskeleti: fvm 3.47.7, `app/` Flutter projesi, `functions/` TS projesi, `firebase.json`, emülatör ayarları, `tools/env` | kök, `app/`, `functions/`, `firebase/`, `tools/env` | NFR-12, NFR-14 | `flutter analyze` ve `npm run build` temiz, emülatörler açılıyor, `tools/env app staging` APP_ anahtarlarını süzüyor |
| T01 | Ortak sözleşmeler: `interests.json`, TOTP, puan ve ad normalizasyonu test vektörleri | `shared/` | FR-03, FR-11, FR-17, §6.1 | Vektörler en az 10'ar örnek, sınır durumları dahil (pencere sınırı, Türkçe İ/ı) |
| T02 | Backend domain (saf TS): `totp`, `scoring`, `pairId`, `eventState`, `names`, `interests`, `ranks` | `functions/src/domain` | FR-03, 06, 11, 17, 24 | Vitest ile ortak vektörlerin tamamı geçiyor |
| T03 | Backend handler'lar: `join`, `requestConnection`, `respondToRequest`, `cancelRequest`, `computeRanks`, `setEventState`, `updateEventConfig`, `moderatePlayer`, `purgeEvent` | `functions/src/{handlers,data,infra}` | FR-01..33 | Emülatör entegrasyon testleri `02-architecture.md` §14'teki bütün senaryoları kapsıyor |
| T04 | Firestore kuralları ve indeksler | `firebase/` | SEC-01, 20, NFR-15 | Kural testleri: istemci yazması her yerde reddedilir, liste sınırları, sırların gizliliği, staff claim'leri |
| T05 | İstemci domain (saf Dart): modeller, `Result`/`GameFailure`, TOTP, kod biçimleri, ad normalizasyonu, avatar | `app/lib/core/domain` | FR-03, 16, 17 | `flutter test` ortak vektörleri geçiyor, modellerin JSON gidiş-dönüş testleri |
| T06 | Uygulama kabuğu: `main`, Sentry + `ErrorReporter`, global hata yakalama, router (3 rota, deferred), Firebase başlatma, emülatör bağlantısı | `app/lib/{main.dart,app,core/observability,core/data}` | NFR-05, ADR-0005, 0007 | Kasıtlı hata Sentry'ye (staging) veya sahte reporter'a düşüyor, hata kartı görünüyor |
| T07 | Tasarım sistemi bileşenleri: tokenlar, çıkartma kartı, butonlar, çip, avatar, QR kartı, sayaç, animasyonlar | `app/lib/app/theme`, `app/lib/core/ui` | NFR-11, NFR-16, `04-design.md` | Widget testleri, azaltılmış hareket desteği |
| T08 | Oyuncu akışı: katılım, QR'ım, tarama (web kamera katmanı + elle kod), istek/onay, başarı ve ortak soru, bağlantılarım, oyun sonu | `app/lib/features/{join,play,summary}`, `app/lib/core/platform` | FR-01..17, 24 | Emülatöre karşı uçtan uca elle test listesi, widget testleri |
| T09 | Projeksiyon: lobi (katılım QR'ı), canlı ağ (`CustomPainter` + kuvvet simülasyonu), ilk 10, kazananlar | `app/lib/features/projector` | FR-20..23 | 150 düğüm / 1.500 kenarda ≥ 30 fps (S6) |
| T10 | Yönetici paneli: durum kontrolü, ayarlar, sağlık kartı, şüpheliler, moderasyon, silme | `app/lib/features/admin` | FR-30..33, NFR-06 | Yetkisiz kullanıcı paneli göremiyor, işlemler fonksiyonlardan geçiyor |
| T11 | Soru havuzu: üretim script'i, taslak havuz, gözden geçirme | `tools/question-gen`, `app/web/content` | FR-08, FR-40 | 78 ikili × ≥ 2 + ≥ 30 genel soru, şemaya uygun JSON |
| T12 | CI/CD: GitHub Actions (check, backend, deploy), staging önizleme | `.github/` | NFR-12, NFR-14, ADR-0010 | PR'da üç iş yeşil |
| T13 | Spike'lar ve yük testi: S1 (custom token per-IP), S5 (gecikme), S6 (grafik), 150 sanal oyuncu | `tools/loadtest`, `docs/spikes/` | G3, NFR-01 | Her spike'ın sonucu `docs/spikes/` altında, eşikler raporlu |
| T14 | Prova ve etkinlik günü kontrol listesi | `docs/ops/` | `05-security.md` §4 | Kontrol listesi doldurulmuş |

## Kullanıcı gerektiren işler

| İş | Ne zaman |
|---|---|
| iPhone ve Android'de kamera ile okutma testi (S2) | Cuma sabahı, staging linkiyle |
| Yönetici ve projeksiyon Google hesapları, 2FA | Prova öncesi |
| `.env.prod` değerleri, ödüller | Prova öncesi |
| Prod'a deploy onayı | Cumartesi akşamı |

## Kapsam dışı (bu sürüm)

Rive (ADR-0009), App Check'in zorunlu yapılması (provaya bağlı), golden testler.
