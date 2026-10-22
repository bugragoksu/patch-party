# Bağlantı Ağı: Dokümantasyon

Bu proje **spec-driven** geliştiriliyor: kod, onaylanmış bir dokümana dayanmadan yazılmaz.

## Aşamalar

| # | Aşama | Çıktı | Klasör | Kapı (geçmek için) |
|---|---|---|---|---|
| 1 | Gereksinimler | Ne yapıyoruz, neden, ne yapmıyoruz | `specs/01-requirements.md` | Açık sorular cevaplandı, P0 kapsamı onaylandı |
| 2 | Araştırma | Teknik belirsizliklerin kanıtlı cevapları | `research/` | Her araştırma sorusu için bir öneri ve güven seviyesi |
| 3 | Tasarım | Mimari, veri modeli, güvenlik kuralları, hata yönetimi | `specs/02-architecture.md`, `adr/` | Her kalıcı karar bir ADR olarak kayıtlı |
| 4 | Görevler | Sıralı, test edilebilir iş listesi | `specs/03-tasks.md` | Her görev bir gereksinime (FR/NFR) bağlı |
| 5 | Uygulama | Kod + testler | `apps/`, `packages/`, `firebase/` | Görevin kabul kriterleri ve CI yeşil |

Arayüz, oyun hissi ve animasyon tasarımı (Rive) ayrı bir iz olarak 3. aşamada başlar: `specs/04-design.md`. Asset üretim yolu araştırma R4'te.

Güvenlik tüm aşamaları keser: tehdit modeli `specs/05-security.md`. Her `SEC-xx` önlemi tasarımda karşılanır ve testle doğrulanır.

## Kurallar

- Her gereksinimin bir kimliği var (`FR-xx`, `NFR-xx`). Kod, test ve görevler bu kimliklere referans verir.
- Kalıcı bir teknik karar (paket seçimi, veri modeli, güvenlik yaklaşımı) bir ADR ile kaydedilir: `adr/NNNN-baslik.md`, şablon `adr/0000-template.md`.
- Bir doküman değişirse, ona bağlı aşağı akış dokümanları da aynı PR'da güncellenir.
- Doküman dili Türkçe, kod ve tanımlayıcılar İngilizce.
