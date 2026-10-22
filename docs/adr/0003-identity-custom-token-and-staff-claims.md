# ADR-0003: Oyuncu kimliği `join()` + custom token, ekip kimliği Google + custom claims

- **Durum:** Kabul edildi (S1 spike sonucuna bağlı)
- **Tarih:** 2026-10-22
- **İlgili:** FR-01, FR-02, FR-30, SEC-13, SEC-40, R2, R3

## Bağlam

Oyuncular hesap açmadan, yalnızca adla katılmalı. Firebase Auth aynı IP'den saatte 100 yeni hesaba izin veriyor. Salon Wi-Fi'ında 100+ telefon tek IP'den çıkabilir. Limit artışı iki hafta önceden destek talebi istiyor, yetişmiyor. Ayrıca salonda olmayanların ve sahte hesap çiftliklerinin katılımı sınırlanmalı.

## Seçenekler

1. **Anonymous Auth:** En basit. Per-IP limite takılır.
2. **`join()` callable + custom token:** Fonksiyon etkinlik kodunu doğrular, oyuncuyu oluşturur, `createCustomToken` döner. Proje başına dakikada 45 bin giriş limiti var. Per-IP limitin buna da uygulanıp uygulanmadığı dokümanda yazmıyor.
3. Ekip (yönetici, projeksiyon) için e-posta allowlist'ini kurallara gömmek veya custom claims.

## Karar

- Oyuncu: **`join()` + custom token**. Katılım için projeksiyon QR'ındaki dönen etkinlik kodu zorunlu (ADR-0004).
- Yönetici ve projeksiyon: **Google ile giriş + custom claims** (`admin`, `projector`). Claim'ler `tools/set-claims` ile atanır. E-posta adresleri ne kurallara ne repoya girer. Projeksiyon dizüstüsü ayrı bir hesapla açılır, orada yönetici oturumu açık kalmaz. Yönetici hesaplarında 2FA zorunlu.

## Sonuçlar

- Katılım ve sahte hesap önlemi tek noktada.
- S1 spike'ı (aynı IP'den ~110 custom token girişi) olumsuz çıkarsa: oyunculara mobil veriyle katılım önerilir, katılım lobi süresine yayılır. Mimari değişmez.
- Safari gizli sekmede oturum sekmeyle birlikte kaybolur. Uygulama içi tarayıcı ile Safari ayrı oturumdur. Bu durumlar uyarıyla karşılanır.
