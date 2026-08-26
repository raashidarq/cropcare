# CropCare — DECISIONS.md

> **Purpose:** Track technical decisions, trade-offs, and personal notes during development.
> **Last updated:** 2026-08-26

---

## Technical Decisions

### TD-001 · No DI Framework (Manual Constructor Injection)

**Date:** Pre-session  
**Decision:** All dependencies are wired manually in `main.dart`. No `get_it`, `injectable`, or `riverpod`.  
**Rationale:** Keeps the codebase simple for MVP, avoids codegen complexity, and makes the dependency graph explicit and readable.  
**Trade-off:** `CaptureScreen` was forced to create its own `AppDatabase()` inline — a known violation of this rule that must not be replicated.

---

### TD-002 · No `freezed` / `equatable` for State Classes

**Date:** Pre-session  
**Decision:** State classes are plain Dart abstract class hierarchies.  
**Rationale:** Avoids codegen overhead. States are simple enough that manual definitions are cleaner.  
**Trade-off:** No auto-generated `copyWith`, `==`, or `hashCode`. Acceptable for current complexity.

---

### TD-003 · ML Inference in Domain Use Case, Not Cubit

**Date:** 2026-08-24  
**Decision:** `RunDiagnosisUseCase` orchestrates validation → inference → persist. `ScanCubit` calls it after `createScan()` and propagates the result state.  
**Rationale:** Cubits should not contain business logic. The use case layer owns the orchestration. `ScanCubit` is extended (not replaced with a `DiagnosisCubit`) to avoid an extra BlocProvider level for MVP.  
**Trade-off:** `ScanCubit` is now doing double duty (scan + diagnosis). Acceptable for MVP; if diagnosis state grows, split into `DiagnosisCubit`.

---

### TD-004 · `tflite_flutter` JVM Target Mismatch Fix

**Date:** 2026-08-24  
**Decision:** Added a `subprojects {}` block in `android/build.gradle.kts` that dynamically matches the Kotlin compiler's `jvmTarget` to each plugin's `JavaCompile` target compatibility.  
**Rationale:** Kotlin 2.x strictly enforces JVM target parity between Java and Kotlin tasks. `tflite_flutter` uses Java 11 while `image_picker_android` and `:app` use Java 17. A blanket override of either direction breaks the other.  
**Fix location:** [`android/build.gradle.kts`](android/build.gradle.kts) — `subprojects {}` block at line 22.

---

### TD-005 · Disease Table Seeded via `DiseaseRepositoryImpl`, Not `CropRepositoryImpl`

**Date:** 2026-08-24  
**Decision:** `DiseaseRepositoryImpl.seedDiseasesIfEmpty()` is called from `main.dart` after crops are seeded (FK dependency: `disease.crop_id → crop.id`).  
**Rationale:** Seeding order must respect foreign key constraints. Diseases cannot be inserted before their parent crops exist.  
**Update (2026-08-24):** All 38 PlantVillage disease classes and Paddy healthy rows are seeded with foreign keys to all 15 supported crops.

---

### TD-006 · PlantVillage 38-Class Model: Dynamic Crop & Disease Support

**Date:** 2026-08-24  
**Decision:** All 15 crops present in the ML model dataset (Apple, Blueberry, Cherry, Corn, Grape, Orange, Peach, Chili/Pepper, Potato, Raspberry, Soybean, Squash, Strawberry, Tomato, plus Paddy/Rice) are seeded in `cropTable` with full localization (EN, SI, TA).  
**Rationale:** The crop selection screen dynamically queries `cropTable` via `GetSupportedCropsUseCase` so all supported crops are available for selection. All 38 model class indices map directly to their SQLite disease IDs in `MlInferenceService`.

---

### TD-007 · Static Localization Map Instead of ARB / `flutter_localizations`

**Date:** Pre-session  
**Decision:** All strings live in a static Dart map in `app_localizations.dart`. No ARB files, no `intl` package, no `flutter_localizations`.  
**Rationale:** Minimal dependencies; fast to iterate; EN/SI/TA are the only supported languages for MVP.  
**Trade-off:** No pluralization, no number formatting. Acceptable for current string set.

---

### TD-008 · `supabase_flutter` Dead Dependency

**Date:** Pre-session  
**Decision:** Left in `pubspec.yaml` for now.  
**Rationale:** Adding it was likely an early experiment. Zero imports in Dart code — it is not active.  
**Future:** Remove once confirmed no one is referencing it. Reduces APK size and avoids confusion.

---

### TD-009 · Treatment Guidance: Remote Gemini LLM Primary + Optional User Observations

**Date:** 2026-08-24  
**Decision:**

1. The remote FastAPI endpoint (`https://cropcare-backend-xy88.onrender.com/interpret-diagnosis`) is the primary source of treatment guidance. Local database table `treatment_guideline` remains unpopulated for now.
2. Healthy plant diagnoses skip the treatment endpoint and confirm healthy status with a "Scan Again" button.
3. Added an optional user observations text input to allow farmers to supply symptom duration, watering, or environmental context to improve LLM accuracy.
4. If network fails or server errors occur, the UI displays a clear connectivity/Wi-Fi retry banner rather than crashing.

---

### TD-010 · Escalation & WhatsApp Share Flow + Embedded Scan History

**Date:** 2026-08-24  
**Decision:**

1. **Manual Escalation with Photo:** Escalation routes manually to WhatsApp via `share_plus` (`Share.shareXFiles([XFile(imagePath)], text: formattedText)`). The leaf photo captured by the farmer is directly attached to the share payload alongside the crop name, predicted disease, confidence level, severity, scan ID, and optional farmer observations.
2. **Low-Confidence Advisory:** When model confidence is < 80% or result state is `DiagnosisResultState.lowConfidence`, an amber advisory banner is presented on both the diagnosis screen and the escalation screen explicitly advising the user to consult an agronomist.
3. **Embedded Scan History:** The past scan history is embedded directly on `HomeScreen` below the primary "Scan Crop" button (rather than as a separate navigation button). Includes total scan counter, dynamic filter chips (All, Low Confidence, Shared, Healthy), and tap-to-review navigation.
4. **Action Buttons Renaming:** On the diagnosis screen, actions are standardized to _"Get AI Recommendation"_ and _"WhatsApp Share with Expert"_. The redundant "Change Language" button beneath "Scan Crop" on HomeScreen was removed in favor of the AppBar language switcher.

---

### TD-011 · Authentication & Guest-to-Registered User Upgrade Flow

**Date:** 2026-08-24  
**Decision:**

1. **In-Place Upgrade:** When a guest registers or logs in, the existing `local_user` row in SQLite is updated in-place (`is_guest = 0`, `remote_user_id`, `email`, `session_token`, etc.). This guarantees that all previously captured scans associated with `local_user.id` remain seamlessly preserved on the device.
2. **Token Security:** Auth JWTs and refresh tokens are stored encrypted using `flutter_secure_storage`.
3. **Rate-Limiting UI:** `AuthApiClient` maps HTTP 429 to a distinct `RateLimitException`, which `AuthCubit` presents to the user via a clear cooldown banner.
4. **Trilingual UI & Entry Points:** An Account section in `SettingsScreen` and a hero card link on `HomeScreen` allow guest farmers to link/upgrade their account at any time.

---

---

### TD-012 · Design System in `lib/core/theme/`, Not Ad Hoc Colours

**Date:** 2026-08-26
**Decision:** All colour, type, spacing and radius values come from
`lib/core/theme/` (`AppColors`, `AppTextStyles`, `AppSpacing`, `AppRadius`,
assembled by `AppTheme.light(languageCode)` / `AppTheme.highContrast(...)` and
wired once in `lib/app.dart`). Screens must not use `Colors.*` swatches or raw
`Color(0x...)` literals for anything carrying meaning.

**Rationale:** The app previously had ~145 raw colour literals across 15
screens and no theme file at all — `lib/core/theme/` existed but was empty. The
same concept rendered differently per screen: severity had two contradictory
colour scales (`diagnosis_result_screen.dart` used high/moderate/low;
`home_screen.dart` used an unrelated binary green/orange), so one scan could be
two different colours on two screens. The WhatsApp brand green was hardcoded in
three places. There were also two competing "brand greens": the theme seeded
from `Colors.green` (#4CAF50) while the launcher icon used #2E7D32.

**Palette rationale:** primary is #1B5E20 — darker and more saturated than
either previous green (≈8.9:1 on white). Chosen for direct sunlight, where
mid-tones wash out. Warning is deep orange #E65100, not amber: amber on white
is ≈1.9:1 and fails AA for text, so amber is used only as a container fill.

**Rule:** alpha-blended colours are acceptable for decorative backgrounds and
scrims, never behind text — a translucent surface has an unpredictable
effective contrast ratio, which is exactly what fails outdoors.

**Remaining literals are deliberate:** `Colors.white`/`Colors.black` on the
camera viewfinder, photo scrims and modal barriers, and the black/yellow pair
in high-contrast mode.

---

### TD-013 · Bundled Noto Fonts, Not the `google_fonts` Package

**Date:** 2026-08-26
**Decision:** Noto Sans, Noto Sans Sinhala and Noto Sans Tamil ship as variable
`.ttf` assets in `assets/fonts/`, declared in `pubspec.yaml`. The
`google_fonts` package is **not** a dependency.

**Rationale:** `google_fonts` fetches at runtime and caches. CropCare is
offline-first and its users are frequently offline on first launch, so a
runtime fetch is the wrong mechanism. With the files bundled, the package would
be pure dead weight — the same mistake as TD-008.

`AppTextStyles.textThemeFor(languageCode)` selects the primary face from the
active language and lists the other two as `fontFamilyFallback`, because a
Sinhala UI still renders Latin crop names, numbers and units — without the
fallback chain those runs render as tofu.

**Trade-off:** ~3.5 MB added to the APK. Explicitly accepted for guaranteed,
consistent trilingual rendering; the alternative (OS fallback) is
device-dependent and was never verified. Subsetting was offered and declined.

---

### TD-014 · Out-of-Distribution Rejection Happens Before Inference

**Date:** 2026-08-26
**Decision:** `ValidateImageUseCase` gained a content gate — exposure, a
cheap Laplacian-variance blur estimate, and a vegetation-hue/saturation
heuristic — run before the TFLite model. Failures map to the rejection
vocabulary the schema already reserved (`TOO_DARK`, `TOO_BRIGHT`, `BLURRY`,
`NO_PLANT_DETECTED`), which no code had ever produced.

**Rationale:** This fixes the reported bug (a photo of a desk diagnosed as
"Tomato Healthy", 98%, CONFIDENT). Root cause: the model is a closed-set
38-class softmax with no rejection option. Softmax normalises over exactly 38
classes for *any* input, so it always produces a confident-looking answer; it
cannot represent "none of the above". Confidence thresholds cannot fix this —
the bug scored 98%, above any usable threshold.

**A second gate exists but is weak, deliberately documented as such:**
`RunDiagnosisUseCase` also requires low normalised softmax entropy for
`CONFIDENT`. Entropy is tightly coupled to max-softmax, so at p_max ≥ ~0.67
even a maximally flat tail stays under the threshold. It only bites in a narrow
band just above `confidenceThreshold`. It is cheap defence-in-depth, **not**
the fix — the content gate is.

**Not a substitute for a trained detector.** The proper fix is a binary
leaf-vs-not-leaf classifier or an embedding-distance OOD score. Thresholds are
named constants so they can be recalibrated from field data. They have been
tuned only against synthetic fixtures; **they need validation on real
photographs before release**, in both directions — a threshold that rejects
genuine diseased leaves (often brown or yellow, not green) is its own bug.

---

### TD-015 · Camera-First Capture; `AddPhotoScreen` Off the Critical Path

**Date:** 2026-08-26
**Decision:** The scan action opens a live viewfinder
(`CameraPreviewView`, using the already-bundled `camera` package) with gallery
as a control inside it. The `AddPhotoScreen` camera/gallery chooser is no
longer in the path.

**Rationale:** The previous "camera view" was a static black placeholder with
an icon; capture actually handed off to the OS camera app, so the farmer left
CropCare, framed in a different UI with no leaf guidance, and came back. And
the chooser screen was a full stop in the middle of the app's primary task.
Camera-first is the convention in comparable scanning apps (Google Lens,
PlantNet, Plantix) because "I am standing in front of a sick plant" should be
zero taps from a shutter.

A framing guide overlay nudges capture toward what the model can actually
read: PlantVillage is close-up, single-leaf, centre-framed imagery, and a whole
plant shot from two metres is already out of distribution.

`AddPhotoScreen` still exists and is still reachable; it is simply no longer
the default route.

---

### TD-016 · Bottom Navigation Shell

**Date:** 2026-08-26
**Decision:** `HomeScreen` is a shell over three destinations — Home, History,
Account — each supplying its own `Scaffold` and `AppBar`.

**Rationale:** The old home screen carried the scan action *and* the entire
scan history with filters, and reached Settings and Profile only through small
unlabelled AppBar icons. Icon-only affordances in a top corner are the least
discoverable control on a phone, which is a poor fit for an audience that may
not read fluently. Labelled bottom destinations are permanently visible and
thumb-reachable.

**Tabs are built lazily.** `IndexedStack` builds every child eagerly, which
constructed the whole Settings tree during the first frame. Tabs are now built
on first visit and kept alive after.

---

### TD-017 · Treatment Guidance Is Requested, Not Automatic

> **SUPERSEDED by TD-021 (2026-08-26).** The reasoning below was sound but
> rested on a false premise: it assumed all guidance costs a network request.
> The app already ships 27 trilingual on-device guidelines, so the common case
> is free. Kept here because the cost argument still governs the *online*
> request, which is still opt-in.

**Date:** 2026-08-26
**Decision:** `DiagnosisResultScreen` no longer fetches treatment guidance on
open. A "Get Treatment Guidance" button triggers it.

**Rationale:** The fetch attempts the network first and only falls back to
on-device guidelines if that fails (`TreatmentRepositoryImpl`). On a metered
rural connection a farmer who only wanted to know what the plant has should not
pay for advice they did not ask for.

**Related bug fixed:** `DiagnosisCubit` hardcoded `source:
TreatmentSource.llm`, so every offline-fallback answer was labelled as
AI-generated. It now derives from `interpretationId`, which is what the UI was
already (correctly) keying off.

---

### TD-018 · Offline Explanation Content Is Schema-Only

**Date:** 2026-08-26
**Decision:** `disease_explanation` and `disease_confusion` tables (schema v6)
plus the full read path exist, and ship **empty**. No code seeds them; content
is authored and delivered separately.

**Rationale:** Kept out of `treatment_guideline` because it answers a different
question ("what is this, and how sure should I be" vs "what do I do") and is
reviewed and shipped on a different cadence.

`disease_confusion.confused_with_disease_id` is nullable on purpose: the most
dangerous look-alikes are often not diseases at all — nutrient deficiency,
water stress, spray burn — and have no `disease` row to point at. Those use the
label columns.

Language resolution is per-field, not per-row, so a partially translated entry
shows translated text where it exists rather than dropping wholesale to
English. The UI renders field by field and states plainly when nothing is
present, so the gap reads as undelivered content rather than a broken screen.

---

### TD-019 · Sync Failures Are Surfaced, Never Silently Dropped

**Date:** 2026-08-26
**Decision:** Operations that stop retrying are visible in `OfflineScreen`
with a reason and an action. `AUTH_REQUIRED` (session expired) is separated
from `PERMANENTLY_FAILED` and offers sign-in, which releases the whole held
batch via `clearAuthHold()`.

**Rationale:** Previously an operation that exhausted its retry budget was
excluded from every subsequent query and vanished with no user-visible signal —
a farmer's scans simply never reached the cloud and nothing said so. A 401 was
treated identically to a network timeout, so an expired session burned the
retry budget and lost the backlog silently.

Retrying a permanently-failed item is deliberately manual: these stopped
retrying because retrying was not working, so re-queueing is a decision, not a
default. `last_error` is a raw untranslated exception string and stays behind a
"Show details" expander.

---

### TD-020 · The Result Screen Shows a Diagnosis, Steps, and a Way to Ask

**Date:** 2026-08-26
**Decision:** `DiagnosisResultScreen` was cut from 1451 lines to 772 and
restructured to: photo and name, one trust line, what to do, what to avoid,
when to check again, what else it might be, ask about it.

**Rationale:** It rendered a hero photo, a verdict, a state chip, a severity
chip, a confidence meter, a caveat banner, a raised Card containing a title
row, a source badge, a full-width read-aloud button and three more coloured
sub-blocks of prose, then an alternatives card, an observations card, a chat
tile and a sticky bar. Cards inside cards, and four separate renderings of
"how sure are we" stacked above the one thing the farmer opened the app for.

Specific consequences:
- The state chip, severity chip, confidence meter and standing AI disclaimer
  collapsed into one plain line plus an amber note shown only when there is
  genuinely a reason to hesitate.
- Guidance renders as numbered steps. The order is information: the backend
  sorts by urgency, so step 1 really is what to do first.
- Read-aloud moved from a full-width button above the text to an icon beside
  the heading it reads. It still exists because it is the path through this
  screen for anyone who does not read comfortably.
- The free-text observations box was removed. Asking a farmer to type is what
  chat is for now, and the mic moved to the chat composer where speaking has
  an obvious purpose.
- `SingleChildScrollView`, not `ListView`: lazy building silently skips
  off-screen children, which makes semantics and tests depend on scroll
  position for no benefit on a screen this short.

---

### TD-021 · On-Device Guidance Loads on Open; the LLM Call Stays Opt-In

**Date:** 2026-08-26
**Supersedes:** TD-017
**Decision:** `TreatmentRepository` split into `getLocalTreatmentGuidance`
(local read, no network) and the existing `getTreatmentGuidance` (LLM). The
local read runs when the result screen opens. The online call remains an
explicit action.

**Rationale:** TD-017 put all guidance behind a button because the fetch tried
the network first, and a farmer who only wanted to know what the plant has
should not pay for advice they did not ask for. That is still true of the
*online* call. But the app seeds trilingual guidelines for every disease the
model can name, so the common path costs nothing at all — and TD-017 had the
effect of hiding the app's entire payload behind a button on the screen you
opened to get it.

---

### TD-022 · Runner-Up Predictions Are Shown, Without Percentages

**Date:** 2026-08-26
**Decision:** The top-3 alternatives are rendered as named chips under
"Not what you see?". The confidence figures are deliberately not displayed.

**Rationale:** The honest presentation of a closed-set softmax that cannot say
"none of the above" (TD-014): showing what else it considered turns the
weakness into something a farmer who knows their own crop can act on. The
percentages were dropped because a farmer cannot act on "21%", and the
ordering already carries what the number was saying.

**Bug fixed at source:** `AlternativePrediction.diseaseId` stored the model's
raw class index as a string, so it joined to nothing and rendered as a bare
number. It now holds a real disease id, and ids stored before the fix are
mapped back on read so existing scans repair themselves without a migration.

---

### TD-023 · Chat Is Scoped to One Diagnosis, and the Transcript Is Local

**Date:** 2026-08-26
**Decision:** "Ask about this result" is a full screen backed by a
`chat_message` table (schema v7). The backend keeps no session; the device's
transcript is authoritative and is sent with each question.

**Rationale:** Offline-first. A conversation has to survive a dropped
connection, an app restart, and a week in a field with no signal, so the only
copy that matters is the local one. A question is persisted *before* the
request goes out and marked `FAILED` if it does not land, so it stays on
screen and can be retried without retyping rather than evaporating.

The cubit takes its `Diagnosis` as a constructor argument rather than a method
parameter, so there is no path to asking about a different scan. Confidence
and `resultState` go to the backend, which hedges harder on an uncertain
result: a chat interface is the easiest place in this app to launder a shaky
closed-set guess into confident prose.

---

### TD-024 · Voice Input Lives in the Chat Composer

**Date:** 2026-08-26
**Decision:** `SpeechRecognitionService` mirrors `TtsService`. The mic is
offered only when the device can transcribe the *active* language.

**Rationale:** Typing is the worst interaction in this app for its audience:
Sinhala and Tamil keyboards are slow, the farmer is usually one-handed in a
field, and limited literacy is why read-aloud is already a first-class
control. This is its input-side counterpart.

It was first attached to the observations box on the result screen and moved
when that box was removed (TD-020) — speaking a question has an obvious
purpose, speaking into a box you were asked to fill in before being told
anything did not.

Language support belongs to the platform, not the package, so on a phone with
no Sinhala pack the control is **absent rather than present-and-broken**. An
English-only mic button would serve exactly the users who least need it.
`MicrophonePermissionService` deliberately does **not** copy
`CameraPermissionService`'s blanket `catch (_)`, which reports plugin failure
as user denial.

**Unverified:** si/ta recognition has never been tested on physical hardware.

---

### TD-025 · The Model Is Being Replaced Because of Its Data, Not Its Architecture

**Date:** 2026-08-26
**Decision:** `ml/` holds a Kaggle training pipeline for a MobileNetV3 model
over a 34-class taxonomy covering rice, tomato, cassava, maize, potato and
chili. `ml/taxonomy.py` is the single source of truth; the notebook is
generated from it.

**Rationale:** The shipped model is stock PlantVillage, and three things are
wrong with it:

1. **It cannot see rice.** The app seeds `paddy` with disease rows and a
   translated guideline, but the classifier has no rice class, so a rice leaf
   returns a confident tomato answer. Rice is the staple crop of the audience
   this app is for.
2. **It was trained on lab plates.** Models scoring 99.35% on PlantVillage's
   own split drop to 31.4% on field images, and a classifier trained on eight
   background pixels alone reaches 49% — the network is substantially reading
   the backdrop, not the leaf.
3. **It has one arthropod class**, so pests are unsupported.

Architecture does not address any of that: MobileNetV2 88.5% -> MobileNetV3
92.4% is four points against a 68-point field collapse. So the taxonomy drops
24 temperate-fruit classes, adds rice and cassava, and PlantDoc is held out of
training entirely as the field test set — the validation number is measured on
the training distribution and will look good regardless.

Two compatibility choices keep the app's preprocessing untouched: the model
takes `[0,1]` input with the `[-1,1]` rescale baked into the graph, and emits
raw logits, because `MlInferenceService` applies softmax and derives entropy
itself.

---

### TD-026 · Treatment Guidance Is Sourced and Cited, Never Written From Memory

**Date:** 2026-08-26
**Decision:** All 28 diagnosable classes have on-device trilingual guidance.
The 12 added for rice and cassava are sourced from IRRI's Rice Knowledge Bank
and Pacific Pests / CABI, with per-class provenance in
`ml/CONTENT_SOURCES.md`.

**Rationale:** Wrong treatment advice for a real disease is worse than an
empty section, and several of these would have been wrong if guessed: brown
spot is a poor-soil problem rather than a spray problem; insecticide is
explicitly ineffective against tungro; clipping leaf tips removes 75–90% of
rice hispa grubs; cassava bacterial blight has no chemical control at all.

Guidance is written as short single-action sentences because the app splits
on-device prose into steps at sentence boundaries, so it renders as the same
numbered list the LLM path produces.
`treatment_guideline_coverage_test.dart` enforces coverage, translation, and
step shape — the failure mode is otherwise silent: add a class, retrain, and
nothing complains until someone is standing in a field.

**Outstanding, and not a code problem:** si/ta are unreviewed; the chemical
names come from international sources and should be checked against Department
of Agriculture / RRDI recommendations; and `cassava_green_mottle` may not
occur in Sri Lanka at all.

---

## Personal Notes

### 2026-08-24 — Gradle JVM Build Issue

- `flutter run` failed with: _Inconsistent JVM Target Compatibility Between Java and Kotlin Tasks_
- Root cause: Kotlin 2.x (used in `settings.gradle.kts` via `org.jetbrains.kotlin.android:2.3.20`) strictly enforces that `compileDebugKotlin` and `compileDebugJavaWithJavac` use the same JVM target.
- Different plugins report different Java targets: `tflite_flutter` → JVM 11; `image_picker_android` / `:app` → JVM 17.
- Three attempts needed before the dynamic matching approach in `build.gradle.kts` resolved both sides simultaneously.
- **Result:** APK built successfully after 153s Gradle build.

---

> _Add new notes below this line with a date heading._

## 2026-08-24 - Tested the app on my Samsung A528B device.

- Diagnosis screen works. But faulty. I took a photo that was my desk. It identified it as Tomato Healthy with 98% and CONFIDENT. It should have identified it as unsupported.
- Furthermore the crop selection screens only show 3 crops. It needs to show all the crops available.
- The model works functionally...but its faulty. The UI/UX should also demonstrate that this is an ML output not treatment recommendation. Speaking of which, there should be features to implement the next part i.e. the treatment guidance feature.

**Update on the above:** ok. All crops are supported. The model is definitely faulty. Gave a tomato plant disease for a picture of a piece of paper. This needs to be fixed.

---

### 2026-08-25 — Android App Name & Launcher Icon Configuration

- Changed app display name to `CropCare` in `android/app/src/main/AndroidManifest.xml` (`android:label="CropCare"`).
- Configured `flutter_launcher_icons` with `assets/icon/app_icon.png` and `#2E7D32` background.
- Generated Android mipmap densities and adaptive icons (`mipmap-anydpi-v26/ic_launcher.xml` and `mipmap-*/ic_launcher.png`) via `dart run flutter_launcher_icons`.

---

### 2026-08-26 — Redesign pass

- Bundled fonts add ~3.5 MB. Worth re-checking APK size before release.
- The OOD thresholds are the single most important thing to validate on a real
  device with real leaves. Synthetic fixtures prove the wiring, not the tuning.
- **All Sinhala and Tamil strings added during this pass were written without
  a native speaker and need review before release.** They are grounded in
  vocabulary already present in `app_localizations.dart`, but that is not the
  same as being correct or natural.
- ~~Two features have placeholder entry points and written briefs~~ — both
  built on 2026-08-26. See TD-023 (chat) and TD-024 (voice); the briefs moved
  to `docs/implemented/`.
- ~~`add_photo_screen.dart` is off the default path but still compiled~~ —
  deleted on 2026-08-26 along with `crop_selection_screen.dart`.
