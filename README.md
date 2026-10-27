# Patch Party

A QR networking game for tech meetups. Everyone joins from their phone's browser, scans each other's rotating QR code, both confirm, and the pair gets a conversation starter that fits their interests. A projector shows the room's network growing live, and at the end the host reveals the winners one by one.

Built for the GDG Adana Info Session (October 2026): 80 players made 466 connections in 25 minutes. Running it cost about 1 USD.

> 🇹🇷 Türkçe özet aşağıda: [Türkçe](#türkçe).

## How it plays

1. **Join.** Scan the QR on the projector, pick a name and 2-3 interests. No install, no account.
2. **Meet and scan.** Each phone shows its own QR, which rotates every 30 seconds, so a screenshot or a shared code is useless. Scan someone in front of you; they confirm on their phone.
3. **Talk.** Both phones show the same question, picked for your pair of interests, and the screen stays for a minute so you actually talk.
4. **Score.** +10 per new person, +5 if you share no interests. Badges for the first connection, for connecting across interests, and more.
5. **The room.** The projector shows every player as a dot and every connection as a line, plus the top 10.
6. **Finale.** The host ends the game and reveals third, second and first, each with more confetti. Phones show each player's rank once all three are out.

## Stack

- **App:** Flutter web (dart2js), Riverpod, go_router. One app, three surfaces: player (`/`), projector (`/screen`), admin (`/admin`).
- **Backend:** Firebase. Cloud Functions (callables) handle every write. Firestore is read-only for clients, guarded by security rules. Players sign in with a custom token minted on join; staff sign in with Google and need an `admin` or `projector` custom claim.
- **Optional:** Sentry for error reports (PII scrubbed). Gemini, offline, to generate the question pool.

Design notes, requirements and architecture decisions (in Turkish) are in [`docs/`](docs/README.md).

## Run it for your own event

You need a Google account with billing enabled (Firebase **Blaze** plan; a meetup stays well inside the free tier), [Flutter](https://flutter.dev) **3.47.7** (via [fvm](https://fvm.app) is easiest), **Node 22**, and the [Google Cloud CLI](https://cloud.google.com/sdk) for the admin scripts.

### 1. Firebase projects

Create one project (or two: staging and prod). For each:

1. **Upgrade to Blaze.** Set a budget alert while you are there.
2. **Firestore:** create the database in **Native mode**. Pick a location close to your venue, e.g. `europe-west3`.
3. **Authentication → Get started → Sign-in method → Google → Enable.**
4. **Project settings → Your apps → add a Web app.** You will need its config in step 3.

### 2. Clone and install

```bash
git clone <your fork> patch-party && cd patch-party
npm --prefix functions ci
(cd app && fvm flutter pub get)
```

Point Firebase at your projects: `cp .firebaserc.example .firebaserc` and fill in your project ids (aliases `staging` and `prod`), or run `npx --prefix functions firebase use --add`.

### 3. Configure

Everything lives in one file per environment:

```bash
cp .env.example .env.staging
```

| Key | What |
|---|---|
| `FIREBASE_PROJECT_ID`, `APP_FIREBASE_*` | From `npx --prefix functions firebase apps:sdkconfig WEB --project <id>` |
| `APP_EVENT_ID` | Any id for this event, e.g. `devfest-2026` |
| `APP_FUNCTIONS_REGION` | Same as `FUNCTIONS_REGION` in `functions/.env` and close to Firestore |
| `ADMIN_EMAILS`, `PROJECTOR_EMAILS` | Google accounts of your team, comma separated |
| `EVENT_DISPLAY_NAME`, `EVENT_SUBTITLE`, `EVENT_PRIZE_1..3` | What players and the projector see |
| `APP_ORGANIZER_NAME`, `APP_ORGANIZER_LOGO` | Your community; see *Make it yours* |
| `APP_SENTRY_DSN` | Optional |

Only `APP_*` keys reach the web bundle, so never put a secret under `APP_`. `.env.staging` and `.env.prod` are git-ignored.

Cloud Functions settings live in `functions/.env` (`FUNCTIONS_REGION`). Per-project settings go in a local, git-ignored `functions/.env.<project-id>`, e.g. `HOT_MIN_INSTANCES=1` on event day to avoid cold starts and `0` afterwards (the default).

### 4. Deploy

```bash
node tools/env.mjs check staging
node tools/env.mjs app staging
(cd app && fvm flutter build web --release --no-web-resources-cdn --dart-define-from-file=.env.app.staging)
node tools/web-meta.mjs staging
npx --prefix functions firebase deploy --project staging --only firestore,functions,hosting
```

**After the first deploy only:** joining mints a custom token, so the default compute service account must be able to sign as itself:

```bash
gcloud iam service-accounts add-iam-policy-binding \
  <PROJECT_NUMBER>-compute@developer.gserviceaccount.com \
  --member=serviceAccount:<PROJECT_NUMBER>-compute@developer.gserviceaccount.com \
  --role=roles/iam.serviceAccountTokenCreator --project <PROJECT_ID>
```

Optional check: every callable should answer an empty request with `400`, not `403`.

### 5. Create the event and give your team access

Each admin opens `https://<your-site>/admin` and signs in with Google once. Then:

```bash
gcloud auth application-default login
node tools/admin/setup-event.mjs staging
```

This creates the event from `.env.staging` and grants the `admin` / `projector` claims.

### 6. On the day

- **Projector:** open `/screen` on the projector laptop and press *Tam ekran* (fullscreen).
- **Admin:** open `/admin` on your own phone or laptop, not on the projector.
- **Lobby:** open it and people join with the projector QR.
- **Play:** start the game with a duration (15-20 min works well), extend it if needed, end it, then reveal 3rd → 2nd → 1st.
- **Rehearsal:** `node tools/loadtest/run.mjs --project <id> --players 150 --minutes 3` simulates a crowd. It needs a live event; wipe the data afterwards.

### 7. Afterwards

- Set `HOT_MIN_INSTANCES=0` and redeploy the functions.
- In the admin panel, *Tehlikeli bölge* deletes all personal data and keeps only totals. The join screen promises this.

## Make it yours

- **Name and texts:** `EVENT_DISPLAY_NAME`, `EVENT_SUBTITLE` and the prizes in `.env`. They can also be changed live in the admin panel.
- **Organiser logo:** replace `app/assets/brand/organizer.png` (white on transparent, about 1440×210) and set `APP_ORGANIZER_NAME` / `APP_ORGANIZER_LOGO`. The GDG Adana logo is the example; set `APP_ORGANIZER_LOGO=false` to show none.
- **Interests:** edit `shared/catalog/interests.json` (12 interests in 4 colour clusters), then run `node tools/gen-catalog.mjs && (cd app && fvm dart format lib/core/domain/catalog.g.dart)`.
- **Questions:** `app/assets/content/questions.json` has one pool per interest pair plus `general`. Regenerate it with your own Gemini key (`GEMINI_API_KEY` in `.env`) using `node tools/question-gen/generate.mjs staging`, then review it by hand.
- **Game rules:** cooldown between connections, request timeout, connection cap and player cap are in the admin panel.
- **Look:** colours and fonts are in `app/lib/app/theme/tokens.dart`. The mark and icons are SVGs in `app/web/brand/`.
- **Language:** the UI is Turkish and its strings are in the widgets. A translation PR (with `flutter_localizations`) is welcome.

## Develop

```bash
npm --prefix functions test                    # unit tests
npm --prefix functions run test:integration    # against the Firebase emulators
(cd app && fvm flutter analyze && fvm flutter test)
```

[`docs/ops/runbook.md`](docs/ops/runbook.md) covers local emulator play.

## License

[MIT](LICENSE). The GDG name and logo belong to Google; replace them for your event if you are not a GDG.

---

## Türkçe

**Patch Party**, teknoloji etkinlikleri için QR tabanlı bir tanışma oyunu. Katılımcılar telefon tarayıcısından girer. Birbirinin 30 saniyede bir değişen QR'ını okutup iki taraf da onaylayınca bağlantı kurulur, ikisine ilgi alanlarına göre ortak bir sohbet sorusu gelir. Projeksiyonda salonun ağı canlı büyür. Oyun bitince sunucu kazananları 3 → 2 → 1 sırasıyla, konfetiyle açıklar.

GDG Adana Info Session (Ekim 2026) için yapıldı. 80 oyuncu 25 dakikada 466 bağlantı kurdu, maliyeti yaklaşık 41 TL oldu.

**Kendi etkinliğinde kurmak için** yukarıdaki *Run it for your own event* adımlarını izle:

1. Firebase projesi (Blaze), Firestore, Google girişi ve web uygulaması.
2. `.env.example` → `.env.staging`.
3. Build ve deploy.
4. Servis hesabına Token Creator yetkisi.
5. `setup-event`.

Organizatör adı ve logosu, ilgi alanları ve sorular *Make it yours* bölümünde.

Tasarım, gereksinimler ve mimari kararlar Türkçe olarak [`docs/`](docs/README.md) altında.
