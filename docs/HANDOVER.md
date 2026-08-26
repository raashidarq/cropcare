# CropCare — handover

> Paste this to the agent or developer picking the work up. It is written to be
> read cold, with no prior context.
>
> **Written:** 2026-08-26 (second pass). Everything below was verified against
> the codebase at that moment. **If anything here contradicts the code, the
> code wins** — re-verify before acting on it.

---

## 0. Read this first

Work sits on branch **`ux/flow-restructure-and-future-features`**, 8 commits
ahead of `main`, **not pushed**. The backend repo has 2 commits, also unpushed.

```bash
git status
git log --oneline main..HEAD
```

**The backend is not deployed, and one feature is dead until it is.** The app
points at `cropcare-backend-xy88.onrender.com`, where `/chat-about-diagnosis`
does not exist yet, so every chat question fails. It fails *honestly* — the
question is kept, marked "Not sent", and can be retried — but it does not work.
The new guidance prompt is a softer dependency: until deployed the API returns
old-shape prose, which the app still splits into steps, so the screen looks
right but the wording is not the improved version.

`lib/data/local/database/app_database.g.dart` is generated — regenerate rather
than hand-edit (`dart run build_runner build`).

---

## 1. What this project is

A Flutter app (Android-first) for **Sri Lankan farmers**. Photograph a leaf,
get an on-device ML diagnosis, get treatment guidance, ask follow-up questions,
escalate to a human expert via WhatsApp. Offline-first with a sync outbox to a
FastAPI/Supabase backend. Trilingual: English, Sinhala, Tamil.

The audience shapes almost every decision here: users are frequently offline,
often on budget devices, outdoors in bright sun, and may not read fluently in
any of the three languages. When a trade-off comes up, that is the tiebreaker.

**`CODEBASE_MAP.md` is the map. `DECISIONS.md` records why things are the way
they are (TD-001 … TD-026). Read both before changing architecture.**

---

## 2. Verified state

| | |
|---|---|
| `flutter test` | **199 passing, 0 failing** |
| `flutter analyze` | **clean** |
| Backend `pytest` | **85 passing** |
| Drift `schemaVersion` | **7** |
| Flutter / Dart | 3.44.8 / 3.12.2 |

Re-run all three before you start, so you know whether a later failure is
yours.

---

## 3. The single most important open item

**The shipped ML model is being replaced, and the replacement is mid-training.**

`assets/models/plant_disease_mobilenetv2.tflite` is stock PlantVillage. Three
things are wrong with it (TD-025):

1. **It cannot see rice.** The app seeds `paddy` with disease rows and
   translated guidance, but the classifier has no rice class — so a rice leaf
   returns a confident *tomato* answer. Rice is the staple crop here.
2. **It was trained on lab plates.** Models scoring 99.35% on PlantVillage's
   own split drop to **31.4%** on field images; a classifier trained on eight
   background pixels alone scores 49%. It is substantially reading the
   backdrop, not the leaf.
3. **One arthropod class**, so pests are unsupported.

`ml/` holds the replacement pipeline — see `ml/README.md`. Everything the new
model needs on the app side is **already committed**: the 12 new disease rows,
the cassava crop, and trilingual guidance for all of them.

When the `.tflite` lands, the swap is mechanical and `ml/README.md` has the
checklist. Three things on it are easy to forget:

- **Re-tune `confidenceThreshold` and `entropyThreshold`.** They were fitted to
  the old model's output distribution and do not carry over.
- **Re-check `ValidateImageUseCase`'s vegetation-hue gate against rice** — a
  narrower, greyer leaf than the broadleaf crops it was tuned on. A gate that
  rejects rice leaves would replace one bug with a worse one.
- **Delete the 11 orphaned guidelines** for apple, grape, cherry, orange,
  peach, squash and strawberry. They are deliberately still present because the
  *current* model predicts those classes; they must go in the same change that
  swaps the model, not before.

---

## 4. What changed in this pass

Grouped by theme; each has a `TD-xxx` in `DECISIONS.md`.

### The result screen was too technical (TD-020, TD-021, TD-022)
1451 → 772 lines. It rendered four separate "how sure are we" widgets above the
one thing a farmer opened the app for, with cards nested inside cards. Now:
photo and name, one trust line, numbered steps, what to avoid, when to check
again, what else it might be, ask about it.

On-device guidance now loads on open — the app already ships trilingual
guidelines, so the common path is free. The *online* LLM call stays opt-in
because it costs mobile data. This supersedes TD-017.

Runner-up predictions are shown as named chips. They were rendering as **bare
numbers** because `AlternativePrediction.diseaseId` held the raw class index;
fixed at source and repaired on read for existing scans.

### Chat and voice (TD-023, TD-024)
Both former placeholders are built. Chat is scoped to one diagnosis, its
transcript is local and authoritative, and an unsendable question is kept and
retryable rather than lost. The mic lives in the chat composer and is absent
entirely on a device that cannot transcribe the active language.

### Backend (in the cropcare-backend repo)
`POST /chat-about-diagnosis` added. `/interpret-diagnosis`'s prompt rewritten:
it now states who it is writing for, caps steps at one action and 14 words,
requires safety notes beside any chemical, and hedges harder below 0.80
confidence. Returns `what_to_do_steps` / `what_to_avoid_steps`; the old prose
fields are derived from them, so older clients keep working.

### Cuts
Removed: the "Notifications — Coming Soon" row, the TEMPORARY "Replay
onboarding" row, `add_photo_screen.dart`, `crop_selection_screen.dart`, the
observations text box, and 10 dead localization keys. `scan_result_screen.dart`
was a field dump showing scan UUIDs and filesystem paths to farmers; rebuilt.
Settings was the least-tokenised screen in the app while being a nav
destination; rebuilt.

### Content (TD-026)
All 28 diagnosable classes now have on-device trilingual guidance, up from 16.
Sourced from IRRI and Pacific Pests/CABI with per-class provenance in
`ml/CONTENT_SOURCES.md`. **Do not extend this from memory** — several entries
are counter-intuitive (brown spot is a soil problem, insecticide does not work
on tungro, cassava bacterial blight has no chemical control at all).

---

## 5. Hard constraints — do not violate these

From `CODEBASE_MAP.md` §9:

- **No `Colors.*` or raw `Color(0x...)`** for anything meaningful. Use
  `AppColors`. Alpha blending is for scrims, never behind text.
- **Use `AppSpacing` / `AppRadius` / `Theme.of(context).textTheme`.** Never
  multiply a font size by the accessibility text scale — it is applied globally
  in `app.dart`.
- **Every new string goes into all three language maps.** Enforced by
  `app_localizations_parity_test.dart`.
- **Never render a raw exception to a user.** `AppErrorView` has a collapsed
  `technicalDetail` slot.
- **Never imply more certainty than a closed-set softmax supports**, and do not
  remove the pre-inference content gate.
- **Do not fabricate agronomic content.** Cite it in `ml/CONTENT_SOURCES.md`.
- **Every diagnosable class needs offline guidance in all three languages.**
  Enforced by `treatment_guideline_coverage_test.dart`.
- **`ml/taxonomy.py` is the source of truth for the class list.** Regenerate
  the notebook with `python ml/build_notebook.py`; never hand-edit the `.ipynb`.
- **Manual constructor injection from `main.dart`.** No `get_it`, `freezed`,
  `equatable`, `go_router`.
- **Offline-first.** Nothing may assume connectivity.

---

## 6. Gotchas that will bite you

- **Heredocs are unreliable in this shell.** Multi-line `bash <<'EOF'` fails
  with "unexpected EOF" when the content has quotes or `$`. Write a script file
  instead.
- **`ListView` builds lazily**, so off-screen children are not built and
  `find.text` misses them. The result screen uses `SingleChildScrollView` for
  exactly this reason.
- **Widget tests: the viewport is short.** Use `tester.ensureVisible(finder)`
  before tapping.
- **`pumpAndSettle` hangs on the camera screen** — the viewfinder shows an
  indeterminate spinner. Use bounded `pump()` calls.
- **Adding a method to `ScanRepository` or `TreatmentRepository` breaks every
  test fake.** Expect to stub several.
- **Schema changes** need `schemaVersion` bumped, an `onUpgrade` branch, and
  build_runner re-run. `_createIndexes` must stay called from **both**
  `onCreate` and `onUpgrade`.
- **Two FKs to the same table** need `@ReferenceName()`.

---

## 7. Open risks and caveats

State these to the repo owner rather than quietly carrying them:

- ⚠️ **All Sinhala and Tamil written by an agent, never reviewed by a native
  speaker.** This now covers 39 treatment guidelines plus the UI strings.
- ⚠️ **Sinhala/Tamil speech recognition has never been tested on hardware.**
  The code degrades correctly if a language pack is missing, but whether si/ta
  work at all on a typical low-end Android phone in Sri Lanka is unknown.
- ⚠️ **The OOD thresholds are tuned against synthetic fixtures**, not real
  photographs — and will need retuning for the new model regardless.
- ⚠️ **Chemical names in the guidance come from international sources.**
  Product availability and registration differ in Sri Lanka, and the app tells
  farmers to buy things. Check against Department of Agriculture / RRDI.
- ⚠️ **`cassava_green_mottle` may not occur in Sri Lanka at all** — recorded
  only from the Solomon Islands. It is in the taxonomy because the Kaggle
  dataset labels it. Decide whether it earns its place.
- **`disease.name_si` / `name_ta`** are populated for the 12 new classes only;
  the original 40 are English in all three languages.
- **No token refresh.** `sessionRefreshToken` is stored and never used.
- **Bundled fonts add ~3.5 MB.** Deliberate (TD-013); re-check APK size.
- **`disease_explanation` / `disease_confusion` ship empty.** The UI now hides
  the section rather than apologising for it.

---

## 8. Useful commands

```bash
flutter analyze                       # must stay clean
flutter test                          # 199 passing
dart run build_runner build           # after any tables.dart change
python ml/build_notebook.py           # after any ml/taxonomy.py change

# backend, in ../cropcare-backend
python -m pytest -q                   # 85 passing
python -m ruff check . --exclude .venv

# find un-tokenised colours (should return only scrims/camera overlay)
grep -rn "Colors\.\|Color(0x" lib/presentation --include=*.dart | grep -v AppColors
```
