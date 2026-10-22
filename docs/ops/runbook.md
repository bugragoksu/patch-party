# Çalıştırma Kılavuzu

Bütün komutlar repo kökünden çalıştırılır. Firebase CLI, `functions/` içindeki sabit sürümle kullanılır: `npx --prefix functions firebase ...`.

## Yerelde (emülatör)

```bash
npm --prefix functions run build
npx --prefix functions firebase emulators:start --only auth,firestore,functions --project demo-baglanti
```

Başka bir terminalde:

```bash
node tools/admin/setup-event.mjs staging --emulator
node tools/admin/dev-state.mjs gdg-adana-2026-10 live 30
cd app && fvm flutter build web --release --no-web-resources-cdn --dart-define-from-file=.env.app.local
python3 -m http.server 5173 --bind 127.0.0.1 -d app/build/web
```

`dev-state` çıktısındaki `url`'i (`/#/j/XXXXXX`) aç. İki ayrı oyuncu için `localhost:5173` ve `127.0.0.1:5173` adreslerini kullan: farklı origin, farklı oturum.

## Staging'e ilk kurulum (bir kez)

1. **Authentication'ı aç ve Google sağlayıcısını etkinleştir:** Firebase konsolu → Authentication → Get started → Sign-in method → Google. Oyuncular custom token ile girer, ekip (yönetici, projeksiyon) Google ile.
2. **Custom token imzalama izni:** Cloud Functions'ın kullandığı varsayılan servis hesabına (`<proje-no>-compute@developer.gserviceaccount.com`) kendisi üzerinde **Service Account Token Creator** rolü verilir. Google Cloud Console → IAM → ilgili servis hesabı → İzinler. Bu olmadan `join` çalışmaz (`signBlob` izni).
3. **Yerelde Admin SDK kimliği:** `gcloud auth application-default login` (Google Cloud CLI kurulu değilse: `brew install --cask google-cloud-sdk`). `setup-event` ve `purge` script'leri bu kimlikle çalışır.
4. **Etkinliği ve rolleri kur:** Yönetici ve projeksiyon hesapları staging sitesine bir kez Google ile giriş yapar, sonra:

```bash
node tools/admin/setup-event.mjs staging
```

## Deploy (staging)

```bash
node tools/env.mjs check staging
node tools/env.mjs app staging
(cd app && fvm flutter build web --release --no-web-resources-cdn --source-maps --dart-define-from-file=.env.app.staging)
npx --prefix functions firebase deploy --project staging --only firestore,functions,hosting
```

## Etkinlik günü

- `functions/.env.baglanti-agi-prod` içine `HOT_MIN_INSTANCES=1` (soğuk başlangıcı önler), etkinlikten sonra `0`.
- Kontrol listesi: `../specs/05-security.md` §4 ve R3 §8.
- Etkinlikten sonra kişisel veri silme: yönetici panelindeki "Verileri sil" (durum `ended` iken).
