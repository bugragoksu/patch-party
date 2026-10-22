# Araştırma

Gereksinimlerdeki (`../specs/01-requirements.md`) teknik belirsizlikleri, mimariyi tasarlamadan önce kanıtla kapatıyoruz. Her dosya şu yapıda:

- Soru → Bulgular (kaynak bağlantısı ve tarihiyle) → Öneri → Güven seviyesi (yüksek / orta / düşük) → Doğrulanması gerekenler (spike)

**Birleşik özet, çelişkiler ve kararlar:** `00-summary.md`

| Kimlik | Konu | Dosya | Bağlı gereksinimler |
|---|---|---|---|
| R1 | Flutter web platformu: derleme hedefi, ilk yükleme, tarayıcı uyumu, kamera ile QR, Rive, projeksiyon grafiği | `r1-flutter-web.md` | NFR-02, NFR-10, FR-04, FR-12, FR-20 |
| R2 | Firebase: kimlik, jeton doğrulama, güvenlik kuralları, Spark/Blaze, kotalar, App Check | `r2-firebase.md` | FR-03, FR-06, FR-11, NFR-01, NFR-07, NFR-09 |
| R3 | Kalite ve operasyon: hata/çökme raporlama, mimari standartlar, test, CI/CD, yük testi | `r3-quality-ops.md` | NFR-04, NFR-05, NFR-06, NFR-12, NFR-14 |
| R4 | Oyun hissi ve asset'ler: envanter, Flame mi değil mi, Rive üretim yolu, lisanslar, boyut bütçesi, sanat yönü, 3 günlük üretim planı | `r4-game-assets.md` | NFR-16, FR-12, FR-20 |

R2, Blaze kararı (2026-10-22) sonrası güvenlik ve kötüye kullanım bölümüyle genişletildi (bkz. `../specs/05-security.md`).
