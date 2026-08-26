# CropCare — UX & UI improvement plan

> **Optimising for:** demo / evaluation quality.
> **Scope:** Home, History & scan detail, Settings / profile / account, Diagnosis result.
> **Written:** 2026-08-26, against the codebase at that date. Verify before acting — the code wins.

Ordered so that each phase is independently demoable. Phase 0 is not optional:
those are things that will visibly misbehave in front of an evaluator.

---

## Phase 0 — Demo blockers (do first)

These are already-known gaps that will show up badly on a live run.

### 0.1 The offline explanation section renders "not added to your phone yet"
`disease_explanation` and `disease_confusion` ship empty by design (TD-018), and
the diagnosis screen honestly says so. In a demo that reads as unfinished.

**Options, pick one deliberately:**
- Seed a handful of real entries for the 3–4 crops you will demo (tomato late
  blight, tomato early blight, chili bacterial spot). Highest impact, and the
  content is needed eventually anyway.
- Hide the section entirely when empty rather than showing the notice.

Do **not** fabricate agronomic content to fill it — wrong treatment advice for a
real disease is worse than an empty section. Get the copy from whoever owns the
agronomy content.

### 0.2 `scan_result_screen.dart` is un-redesigned
194 lines, **zero** design-token references. It is reachable from History for any
scan without a diagnosis. It will look like a different app.

**Fix:** rebuild on `AppCard` / `AppBanner` / theme tokens, or fold it into the
diagnosis result screen as a "no result" state and delete it.

### 0.3 `crop_selection_screen.dart` is orphaned but still reachable
Bare loading/error states, un-tokenised, and no longer on the scan path since
camera-first landed (TD-015).

**Fix:** confirm nothing routes to it, then delete. Same call for
`add_photo_screen.dart`.

### 0.4 The model's alternative predictions are computed, stored, and never shown
`RunDiagnosisUseCase` builds a top-3 `alternatives` list on every diagnosis and
persists it. **Nothing in `lib/presentation/` reads it.**

This is the single best demo feature already sitting in the database — see 3.1.

---

## Phase 1 — Motion and depth (cross-cutting)

Only 4 files in `lib/presentation/` use any animation. The app is completely
static, which is the main reason it reads as "basic" regardless of layout.

### 1.1 Shared motion vocabulary
New `lib/core/theme/app_motion.dart`: two or three durations and curves
(`fast` 150ms, `standard` 250ms, `emphasis` 400ms; `Curves.easeOutCubic`).
Everything animates on these, so motion feels like one system.

### 1.2 Screen transitions
Custom `PageRouteBuilder` (shared axis / fade-through). Flutter's default
Android transition is dated; this is a large perceived-quality gain for very
little code.

### 1.3 Hero the scan photo
`Hero` on the scan image from history card → diagnosis result. Demos
extremely well and costs almost nothing — the same `File` is on both screens.

### 1.4 Staggered list entry
Home cards and history rows fade+slide in on first build. Keep it subtle
(≤200ms, ≤12px offset) and **disable when the user has reduced-motion set** —
check `MediaQuery.disableAnimationsOf(context)`.

### 1.5 Result reveal
The confidence meter animates from 0 to its value; the result chip scales in.
Turns the diagnosis screen from "text appeared" into "a result arrived".

---

## Phase 2 — Screen redesigns

### 2.1 Home dashboard
Currently: CTA card, two stat tiles, sync banner, three recent scans.

- **Greeting header** with time-of-day and crop-season context.
- **Trend strip** — scans per week as a sparkline. `HistoryCubit` already holds
  every `ScanHistoryItem` with `capturedAt`, so this needs no new data. Load the
  `dataviz` skill before building any chart.
- **"Needs attention" surface** — promote unhealthy/low-confidence scans into an
  actionable row rather than a bare count.
- **Crop breakdown** — small horizontal chips showing which crops were scanned,
  using `CropVisuals`.
- **Empty state with intent** — first-run home should teach, not show zeros.

### 2.2 History & scan detail
- **Date grouping** — "Today / This week / Earlier" section headers.
- **Search** by crop or disease name.
- **Crop filter** alongside the existing status filter, using `CropVisuals`.
- **Thumbnail grid toggle** — list vs. grid. Grid demos well and suits a
  photo-centric history.
- **Scan detail screen** — see 0.2. Should carry the Hero image, the diagnosis,
  and re-entry into treatment guidance.
- **Swipe-to-delete** with undo. Note: per-scan delete does not exist yet —
  `ScanRepository` only has `deleteAllLocalScans()` and the new
  `purgeFailedScans()`. A `deleteScan(id)` is needed, and it must delete the
  image file and cancel any queued sync op, exactly as `rejectInvalidScan` does.

### 2.3 Settings / profile / account
Currently plain `Card` + `ListTile` rows.

- **Profile header** — avatar (initial or icon), name/email, account-state chip
  (Guest / Linked), and storage used.
- **Grouped settings cards** with section icons, replacing the flat list.
- **Storage breakdown** — scan images vs. database, with the existing delete
  action attached. Needs a small `du`-style helper over the scans directory.
- **Sync status as a first-class card** — last synced, pending, failed, with the
  Phase-0 failed-sync UI already built in `offline_screen.dart`.
- **Account screen states** — guest vs. linked should look materially different,
  not just a different chip.

### 2.4 Diagnosis result
Already redesigned once, but three additions:

- **Alternatives card** (see 3.1) — the highest-value addition.
- **Image zoom** — tap the hero to open a full-screen `InteractiveViewer`.
- **Sticky action bar** — "Scan again" / "Ask an expert" pinned to the bottom
  rather than at the end of a long scroll.

---

## Phase 3 — New features that demo well

### 3.1 "Other possibilities" — top-3 alternatives ⭐ highest value/effort ratio
The data already exists on every `Diagnosis`. Render the runner-up predictions
with their confidences beneath the primary result.

**Why it matters beyond the demo:** it is the honest presentation of a
closed-set classifier. It shows the model considered other options and how
close they were, which is exactly the framing TD-014 argues for. It turns a
weakness into a visible strength.

**Caveat found in the code:** `AlternativePrediction.diseaseId` currently stores
the *class index as a string*, not a disease id
(`diseaseId: pair.$1.toString()`). Map it back through
`MlInferenceService.classNameAt` / `_classIndexToDiseaseId` before display, or
fix it at the source.

### 3.2 Scan comparison / progress tracking
Pick two scans of the same crop and show them side by side with dates and
diagnoses — "is this getting better or worse?". Genuinely useful and visually
strong. All the data exists.

### 3.3 Treatment reminders
`TreatmentResponse.recheckAfterDays` is already returned and displayed but
nothing acts on it. A local notification "check your tomatoes again today"
closes a real loop. Requires `flutter_local_notifications` — currently **not** a
dependency, and push notifications are listed as unimplemented in
`CODEBASE_MAP.md`.

### 3.4 Disease reference library
A browsable list of the 38 known diseases with symptoms and treatment. Makes
the app useful before the first scan, and gives the empty-state a destination.
Depends on the same content as 0.1.

### 3.5 Localised disease names
Currently `_formatDiseaseName` prettifies the raw English id
(`tomato_late_blight` → "Tomato Late Blight") on **every** screen. The `disease`
table already has `name_si` and `name_ta` columns; the `Diagnosis` entity just
carries an id, so the localised name is never reachable.

**Fix:** join the disease row into the scan-history and diagnosis read paths.
For a Sinhala or Tamil demo this is glaring — the disease name is the single
most important string on the screen and it is the one thing still in English.

---

## Suggested demo-first ordering

| Order | Item | Why |
|---|---|---|
| 1 | 0.2, 0.3 | Remove the screens that look like a different app |
| 2 | 3.1 alternatives | Biggest visible win, data already exists |
| 3 | 1.2, 1.3 transitions + Hero | Largest perceived-quality gain per line of code |
| 4 | 3.5 localised disease names | Essential if demoing in Sinhala or Tamil |
| 5 | 2.1 home dashboard | First screen an evaluator sees |
| 6 | 1.5 result reveal | Makes the core flow feel finished |
| 7 | 2.2 history | Second-most visited screen |
| 8 | 0.1 explanation content | Decide seed-vs-hide before demo day |
| 9 | 2.3 settings/profile | Least likely to be opened in a demo |
| 10 | 3.2, 3.3, 3.4 | Only if there is time |

---

## Standing constraints

Everything above must respect what is already established:

- **Design tokens only** — `AppColors` / `AppSpacing` / `AppRadius` /
  `Theme.of(context).textTheme`. No raw `Colors.*` for anything meaningful
  (TD-012, rule 16).
- **All three languages** — every new string into all three maps in
  `app_localizations.dart` (rule 12). Parity is enforced by review, not tooling.
- **Never overstate model certainty** (TD-014, rule 20).
- **Never render a raw exception** to a user (rule 19).
- **Manual constructor injection from `main.dart`** — no DI framework (TD-001).
- **Offline-first** — nothing may assume connectivity.
- **Accessibility settings must keep working** — text scale, high contrast,
  speech rate, auto-read, haptics are now all wired; do not regress them, and
  never multiply a font size by the text scale (rule 17).

## Known gaps this plan does not close

- No token refresh (`sessionRefreshToken` is stored, never used) — a session
  simply dies. Backend work.
- `disease_explanation` / `disease_confusion` content.
- Sinhala/Tamil strings written during the redesign have **not** been reviewed
  by a native speaker.
- OOD thresholds tuned against synthetic fixtures only, never real photographs.
