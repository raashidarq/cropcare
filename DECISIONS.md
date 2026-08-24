# CropCare — DECISIONS.md

> **Purpose:** Track technical decisions, trade-offs, and personal notes during development.
> **Last updated:** 2026-08-24

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
4. **Action Buttons Renaming:** On the diagnosis screen, actions are standardized to *"Get AI Recommendation"* and *"WhatsApp Share with Expert"*. The redundant "Change Language" button beneath "Scan Crop" on HomeScreen was removed in favor of the AppBar language switcher.

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
