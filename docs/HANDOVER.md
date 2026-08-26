# CropCare — handover

> Paste this to the agent or developer picking the work up. It is written to be
> read cold, with no prior context.
>
> **Written:** 2026-08-26. Everything below was verified against the codebase at
> that moment. **If anything here contradicts the code, the code wins** —
> re-verify before acting on it.

---

## 0. Read this first

**All work from the last session is UNCOMMITTED.** At handover: 94 changed
files, branch `main`, last commit `c82b2cd` (which predates all of it).

Before doing anything else:

```bash
git status
git stash list          # confirm nothing was stashed and forgotten
```

Decide with the repo owner whether to commit as-is, split into logical commits,
or branch. Do not start new work on top of an uncommitted 94-file diff without
agreeing that first. Note that `lib/data/local/database/app_database.g.dart` is
generated — regenerate rather than hand-edit (`dart run build_runner build`;
`--delete-conflicting-outputs` was removed from this build_runner version and is
ignored).

---

## 1. What this project is

A Flutter app (Android-first) for **Sri Lankan farmers**. Photograph a leaf, get
an on-device ML diagnosis, get treatment guidance, escalate to a human expert
via WhatsApp. Offline-first with a sync outbox to a FastAPI/Supabase backend.
Trilingual: English, Sinhala, Tamil.

The audience shapes almost every decision in the codebase: users are frequently
offline, often on budget devices, outdoors in bright sun, and may not read
fluently in any of the three languages. When a trade-off comes up, that is the
tiebreaker.

**`CODEBASE_MAP.md` is the map of the codebase. `DECISIONS.md` records why
things are the way they are (TD-001 … TD-019). Read both before changing
architecture.**

---

## 2. Verified state at handover

| | |
|---|---|
| `flutter test` | **150 passing, 0 failing** |
| `flutter analyze` | **clean** (lib and test) |
| Drift `schemaVersion` | **6** |
| Localization keys | **382**, full EN/SI/TA parity |
| Flutter / Dart | 3.44.8 / 3.12.2 |

Re-run both before you start, so you know whether a later failure is yours.

---

## 3. What changed in the last session

Grouped by theme. Each has a `TD-xxx` in `DECISIONS.md` with the reasoning.

### Design system (TD-012, TD-013)
`lib/core/theme/` created from scratch — it previously existed as an empty
directory while ~145 raw colour literals were scattered across 15 screens.
`AppColors`, `AppTextStyles` (language-aware), `AppSpacing`, `AppRadius`,
`AppTheme`. Noto fonts for all three scripts are **bundled as assets**;
`google_fonts` is deliberately NOT a dependency (it fetches at runtime, which
breaks offline-first). Shared widgets live in
`lib/presentation/shared/widgets/`.

### The OOD bug (TD-014) — the most important fix
A photo of a **desk** was diagnosed as "Tomato Healthy, 98%, CONFIDENT". Root
cause: the model is a closed-set 38-class softmax with no rejection option — it
mathematically cannot say "none of the above", so it always produces a confident
answer for any input. Confidence thresholds cannot fix this; the bug scored 98%.

Fixed by a **content gate in `ValidateImageUseCase`** that runs *before*
inference: exposure, blur (Laplacian variance) and a vegetation-hue heuristic.
There is also an entropy check in `RunDiagnosisUseCase`, but it is
**deliberately documented as weak** — entropy is tightly coupled to max-softmax,
so it only bites in a narrow band. The content gate does the real work.

### Camera-first capture (TD-015)
The old "camera screen" was a static black placeholder; capture handed off to
the OS camera app. There is now a real `CameraPreviewView` with a leaf-framing
guide. `AddPhotoScreen` (the camera-or-gallery chooser) was removed from the
scan path — gallery is a control inside the viewfinder.

### Bottom-nav shell (TD-016)
`HomeScreen` is now a shell over Home / History / Account. **Tabs build
lazily** — `IndexedStack` builds every child eagerly, which was constructing the
entire Settings tree on the first frame.

### Auth screens redesigned
Removed the TabBar (it stacked on the email/phone toggle, forcing users into a
2×2 matrix before typing) and the fixed-height form area (it clipped at larger
text scales and in Sinhala/Tamil). **Autofill is now wired throughout** — it
previously was not, anywhere, so saved credentials were never offered. OTP entry
is one hidden field behind six painted boxes, which is what makes SMS autofill
and paste work.

### History pollution (last session's final fix)
Scans were created **before** validation, and the crop is only derived from a
*successful* inference — so every rejected photo became an "Unknown" history
entry. Validation now runs first; a rejected photo leaves nothing at all.
`purgeFailedScans()` runs at startup to clean up existing rows.

Worth knowing: the `image_validation` table is **written in two places and never
read anywhere**. That is why it was safe to stop writing it on the rejection
path.

### Accessibility — 3 of 5 settings controlled nothing
Speech rate was hardcoded to `0.5`; auto-read and haptics had **zero
consumers**. All three are now wired (`AppHaptics` is new). Text scale and high
contrast already worked. A **double text-scaling bug** was also fixed — the
preview card multiplied font sizes by the scale on top of the global
`MediaQuery` scaler, so 145% rendered near 210%.

### Auto-sync now opt-in (last session)
Default **off**, persisted via `SyncPreferences`, refuses to enable without a
session, cleared on sign-out.

### Onboarding reordered and redesigned
The flow was Splash → Onboarding → Language, so the whole introduction was shown
in **English before the user could choose their language**. Now: Splash →
Language → 4 slides → account-or-guest choice → Home.

### Sync hardening (TD-019)
Reentrancy guard, cross-isolate advisory lock, stalled-operation recovery,
retry-without-re-upload, transient-vs-permanent failure classification, and UI
in `offline_screen.dart` for failures and expired sessions.

---

## 4. What to do next

**`docs/UX_IMPROVEMENT_PLAN.md` is the plan.** It is ordered for demo/evaluation
quality, which is the current priority. Its suggested first steps:

1. **0.2 / 0.3** — `scan_result_screen.dart` has *zero* design-token references
   and is reachable from History; `crop_selection_screen.dart` and
   `add_photo_screen.dart` are orphaned but still compiled. These look like a
   different app.
2. **3.1 — show the top-3 alternatives.** Highest value for the effort:
   `RunDiagnosisUseCase` already computes and stores an `alternatives` list on
   every diagnosis, and **nothing in `lib/presentation/` reads it**.
   ⚠️ `AlternativePrediction.diseaseId` currently stores the *class index as a
   string*, not a disease id — map it back before display, or fix it at source.
3. **1.2 / 1.3 — page transitions and a `Hero` on the scan photo.** Only 4 files
   in `lib/presentation/` use any animation at all; this is the main reason the
   app reads as basic.
4. **3.5 — localised disease names.** Names are prettified from the English id
   on every screen. `disease` has `name_si`/`name_ta`, but `Diagnosis` carries
   only an id so they are unreachable. **Essential before any Sinhala or Tamil
   demo** — it is the most important string on the screen and the one still in
   English.

Two other briefs are already written and ready to hand to an agent:
`docs/future/chat_with_result_implementation.md` and
`docs/future/voice_observations_implementation.md`. Both have inert placeholder
entry points in the UI already.

---

## 5. Hard constraints — do not violate these

From `CODEBASE_MAP.md` §9 (rules 16–21 were added in this work):

- **No `Colors.*` swatches or raw `Color(0x...)`** for anything meaningful. Use
  `AppColors`. Alpha blending is for decorative backgrounds and scrims, never
  behind text — translucent text has an unpredictable contrast ratio, which is
  what fails outdoors.
- **Use `AppSpacing` / `AppRadius` / `Theme.of(context).textTheme`**, never
  inline `TextStyle(fontSize:)`. **Never multiply a font size by the
  accessibility text scale** — it is applied globally in `app.dart`; doing it
  again squares the effect.
- **Every new string goes into all three language maps** in
  `app_localizations.dart`. Parity is enforced by review, not tooling — a
  missing key silently renders the raw key to the user.
- **Never render a raw exception to a user.** `AppErrorView` has a
  `technicalDetail` slot, collapsed by default.
- **Never imply more certainty than a closed-set softmax supports**, and do not
  remove the pre-inference content gate.
- **`disease_explanation` / `disease_confusion` are intentionally empty.** Do
  not seed content to make a test pass — assert the empty path.
- **Manual constructor injection from `main.dart`.** No `get_it`, `freezed`,
  `equatable`, `go_router` (TD-001, TD-002).
- **Offline-first.** Nothing may assume connectivity.

---

## 6. Gotchas that will bite you

- **Heredocs are unreliable in this shell.** Multi-line `bash <<'EOF'` frequently
  fails with "unexpected EOF". Use the Write tool, or write to a temp file and
  `cat` it.
- **Widget tests: the viewport is short.** Screens are long now; `tester.tap`
  silently misses off-screen widgets. Use `tester.ensureVisible(finder)` first.
- **`pumpAndSettle` hangs on the camera screen** — the viewfinder shows an
  indeterminate spinner while deciding whether a camera exists. Use bounded
  `pump()` calls, or inject a fake `CameraService`.
- **Adding a method to `ScanRepository` breaks 8 test fakes** plus
  `_FallbackScanRepository` in `home_screen.dart`. Expect to stub all of them.
- **Drift `&` on `Expression<bool>`** needs `package:drift/drift.dart` imported;
  it is not in `drift/native.dart`. Filtering in Dart is often simpler in tests.
- **Two FKs to the same table** need `@ReferenceName()` or codegen warns and
  drops the generated filters (see `DiseaseConfusionTable`).
- **Schema changes** require bumping `schemaVersion`, adding an `onUpgrade`
  branch, and re-running build_runner. `_createIndexes` must stay called from
  **both** `onCreate` and `onUpgrade` — it previously was not, so no upgraded
  device ever had indexes.

---

## 7. Open risks and caveats

State these to the repo owner rather than quietly carrying them:

- ⚠️ **All Sinhala and Tamil strings written during this work were produced
  without a native speaker.** They are grounded in vocabulary already in the
  file, which is not the same as being correct or natural. They need review
  before release.
- ⚠️ **The OOD thresholds have only been tuned against synthetic fixtures**, not
  real photographs. They need validating in both directions on a real device:
  a threshold that rejects genuine diseased leaves — often brown or yellow, not
  green — is its own bug.
- **No token refresh exists.** `sessionRefreshToken` is stored and never used;
  a session simply dies. The UI now surfaces this (TD-019) instead of losing
  the backlog silently, but the backend work is outstanding.
- **Bundled fonts add ~3.5 MB** to the APK. Deliberate (TD-013), but worth
  re-checking APK size before release.
- **`disease_explanation` / `disease_confusion` ship empty.** Content is owned
  elsewhere. Decide seed-vs-hide before any demo (plan §0.1). Do not fabricate
  agronomic content — wrong treatment advice for a real disease is worse than an
  empty section.
- **A temporary "Replay onboarding" entry** sits in Settings → Support & Legal,
  marked `TEMPORARY` in source. Remove it once the onboarding flow is signed
  off.

---

## 8. Useful commands

```bash
flutter analyze                       # must stay clean
flutter test                          # 150 passing at handover
dart run build_runner build           # after any tables.dart change
flutter test test/presentation/auth/  # run one area

# find un-tokenised colours (should return only scrims/camera overlay)
grep -rn "Colors\.\|Color(0x" lib/presentation --include=*.dart | grep -v AppColors
```
