# ADR-0010: Ortamlar, CI/CD ve etkinlik günü yayın güvenliği

- **Durum:** Kabul edildi
- **Tarih:** 2026-10-22
- **İlgili:** NFR-12, NFR-14, SEC-42, R2, R3, D5

## Bağlam

Testler ve yük testi gerçek kotayı tüketmemeli. Etkinlik günü yayın hatası telafi edilemez. Repoda gizli anahtar olmamalı.

## Seçenekler

- Tek Firebase projesi veya ayrı staging/prod.
- CI kimliği: servis hesabı JSON anahtarı (`action-hosting-deploy` yalnızca bunu kabul ediyor) veya Workload Identity Federation (anahtarsız) + `firebase-tools` doğrudan.
- Kuralların ve fonksiyonların CI'dan otomatik veya elle deploy'u.

## Karar

- **Ortamlar:** `dev` = Emulator Suite. Ayrı `baglanti-agi-staging` ve `baglanti-agi-prod` projeleri.
- **CI (GitHub Actions):** `check` (format, analyze, test, domain import kontrolü), `backend` (fonksiyon ve kural testleri emülatörde), `deploy`. `check` ve `backend` main dalında zorunlu kontrol.
- **Deploy:** PR → staging önizleme kanalı. `main` → staging canlı. Prod → yalnızca elle tetikleme + onay.
- **Kimlik:** Workload Identity Federation + `firebase-tools`. Kurulum yetişmezse yalnızca Hosting Admin rolünde, etkinlikten sonra silinecek bir anahtar. Bu durumda bu ADR'ye bilinçli borç olarak not edilir.
- **Kurallar ve fonksiyonlar** prod'a elle, tek komutla deploy edilir.
- **Sürüm:** `pubspec.yaml` sürümü + git SHA. Uygulamanın köşesinde küçük sürüm etiketi. Deploy edilen commit'e `event-2026-10-25` etiketi.
- **Önbellek:** `index.html`, `flutter_bootstrap.js`, `version.json` için `no-cache`. Diğer JS/wasm için 1 saat. 3.47.7 çıktısında service worker olmadığı doğrulanır.
- **Dondurma:** T-12 saat. Son sürüm staging'de doğrulanır, `hosting:clone` ile prod'a alınır. Geri alma konsoldan.

## Sonuçlar

- İki proje kurulum yükü getirir (yaklaşık 1 saat). Karşılığında prova ve yük testi prod'a dokunmaz.
- Kuralların elle deploy'u insan hatasına açık. Tek komut ve kontrol listesiyle sınırlanır.
