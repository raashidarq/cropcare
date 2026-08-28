# CropCare

An offline-first Flutter app for smallholder farmers in Sri Lanka. Photograph
a crop leaf, get an on-device diagnosis in English, Sinhala, or Tamil, read
treatment guidance that works with zero signal, and escalate to a human
expert over WhatsApp when the model isn't sure.

Backend: [`cropcare-backend`](https://github.com/raashidarq/cropcare-backend)
— live at `https://cropcare-backend-xy88.onrender.com`.

---

## Testing this without setting anything up

**You don't need to run the backend.** The app is pre-configured to talk to
the live Render deployment above.

- **Guest mode needs no credentials at all.** From the onboarding flow,
  choose "Continue as guest" — full diagnosis, treatment guidance, and chat
  all work; only cloud sync and cross-device restore require an account.
- **To test account creation**, register a fresh email — signup takes one
  step (no email confirmation required) and takes a few seconds. We are not
  publishing a shared demo password in this public repo: a shared account's
  scan history would be visible to anyone with the credentials, and account
  creation is itself one of the flows worth exercising.
- **Phone sign-in is intentionally disabled** (`PHONE_AUTH_ENABLED=false` on
  the backend) — every SMS provider bills per message, and there is no free
  tier. Use email.

## Running it locally

```bash
flutter --version   # 3.44.8 / Dart 3.12.2, this repo's tested version
flutter pub get
dart run build_runner build   # regenerates the Drift database layer
flutter run
```

Points at the live backend above by default. To run against a local backend
instead, see that repo's README, then pass its base URL when constructing
`AuthApiClient` / `TreatmentApiClient` / `SyncApiClient` in `lib/main.dart`.

## Testing

```bash
flutter analyze   # must stay clean
flutter test      # 227 passing at time of writing
```

## Building a release APK

```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-symbols
```

Produces one APK per CPU architecture in `build/app/outputs/flutter-apk/`.
For a real device, `app-arm64-v8a-release.apk` is the one — it covers
virtually every Android phone sold since ~2017. R8 shrinking and resource
shrinking are on; expect roughly a third smaller than an unminified build.

Signed with the debug key. Fine for sideloading; needs a real release
keystore before a Play Store submission.

## What this is built on

- **On-device ML**: TFLite, MobileNetV3, 34 disease/pest classes across 6
  crops actually grown in Sri Lanka (rice, tomato, cassava, maize, potato,
  chili) — trained on field photography, not lab plates. See `ml/README.md`
  for the training pipeline and why that distinction matters.
- **Offline-first**: every diagnosis and its treatment guidance work with the
  radio off. The AI-written guidance from Gemini is a non-blocking upgrade —
  see the diagnosis-flow diagram for exactly how a failed AI request can
  never blank or overwrite guidance already on screen.
- **Trilingual**: English, Sinhala, Tamil, with automated parity testing so a
  string added in one language can't silently ship missing in another.
- **Sync**: an outbox queue, Wi-Fi-gated for automatic uploads (an explicit
  "Sync now" always works, on any connection), with cloud restore and delete.

## Reading the codebase

- **`CODEBASE_MAP.md`** — architecture, layering rules, where things live.
- **`DECISIONS.md`** — the *why* behind non-obvious choices (TD-001 through
  TD-026), including several corrections made along the way.
- **`docs/HANDOVER.md`** — current state, open risks, what's still unproven.
- **`ml/README.md`** and **`ml/CONTENT_SOURCES.md`** — the model training
  pipeline and the sourcing for the on-device treatment guidance.

## Known limitations

- Sinhala and Tamil strings have not been reviewed by a native speaker.
- Confidence thresholds for the field-trained model are reasoned, not yet
  calibrated against measured accuracy — see `ml/README.md`.
- Voice input for Sinhala/Tamil has not been verified on real hardware.

Full list in `docs/HANDOVER.md` §7.
