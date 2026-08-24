# CropCare — CODEBASE_MAP.md

> **Purpose:** Compact, accurate description of the **current** Flutter codebase for future AI coding agents.
> **Source hierarchy:** Actual code > `CropCare_System_Architecture.md` > `CropCare_Build_Checklist.md`
> **Last updated:** 2026-08-24

---

## 1. Current Status

### What CropCare currently does
A Flutter mobile app (Android primary) that lets a guest farmer select a crop, capture a photo, validate image quality on-device, run on-device ML inference using a bundled MobileNetV2 TFLite model, and persist the `Scan` and `Diagnosis` rows in local SQLite — completely offline with no network dependency. Onboarding (3 slides) and language selection (EN/SI/TA) are fully working and persisted.

### What is implemented and working
| Feature | Status |
|---|---|
| App startup / splash routing | Done |
| Onboarding (3 slides + skip) | Done |
| Language selection (EN/SI/TA) | Done |
| Language persistence + live switching | Done |
| Guest user auto-creation (SQLite) | Done |
| Crop selection (Dynamic from SQLite: 15 crops including Tomato, Chili, Paddy, Apple, Corn, etc.) | Done |
| Disease reference data seeding (All 38 PlantVillage classes mapped + Paddy) | Done |
| Camera permission request + denial handling | Done |
| Photo capture via image_picker | Done |
| Photo review / retake | Done |
| Image validation (dimension, decodability, size checks) | Done |
| On-device ML inference (`tflite_flutter`, MobileNetV2 float32) | Done |
| Scan row INSERT to SQLite (status=CREATED) | Done |
| Image validation row INSERT to SQLite | Done |
| Diagnosis row INSERT to SQLite (CONFIDENT, LOW_CONFIDENCE, UNSUPPORTED, ANALYSIS_FAILED) | Done |
| DiagnosisResultScreen (disease name, confidence %, severity, low confidence banner, observations, Gemini treatment card, scan again) | Done |
| Treatment Guidance (FastAPI `POST /interpret-diagnosis` client, ResolveTreatmentUseCase, DiagnosisCubit) | Done |
| Escalation & WhatsApp Share Flow (EscalationScreen, EscalationCubit, attached photo, low-confidence advisory) | Done |
| Embedded Scan History (HomeScreen history section, HistoryCubit, filter chips, tap-to-review) | Done |
| Settings screen shell (Language, Accessibility, Notifications, Offline Data) | Shell only |
| SQLite schema (all Drift tables defined + migrations, schemaVersion=3) | Done |
| Full localization string tables (EN/SI/TA) | Done |

### What is partially implemented
- Settings sections: Shell displayed; only Language section is functional. Others show Coming Soon dialog.
- `SettingsCubit`: Exists but only tracks `expandedSection` — no real logic.

### What is not implemented
- Authentication (OTP/email) — `application/auth/` directory is empty
- Sync engine — `data/sync/` is empty; `application/sync/` is empty; no `sync_operation` table
- Push notifications / TTS / WorkManager

### Immediate development priorities (from checklist)
1. Authentication: Guest-to-registered user upgrade flow
2. Offline Sync Engine & Conflict Resolution
3. Audio/TTS playback for treatment guidance

---

## 2. Repository Structure

```
cropcare/
├── lib/
│   ├── main.dart                    # Entry point; DB + repos + seeders + ML model + cubit
│   ├── app.dart                     # CropCareApp widget; BlocProvider root; routing logic
│   ├── application/                 # Cubits (state management, one per feature)
│   │   ├── onboarding/              # AppStateCubit + AppStateState  <- IMPLEMENTED
│   │   ├── scan/                    # ScanCubit + ScanState           <- IMPLEMENTED (with ML chain)
│   │   ├── settings/                # SettingsCubit + SettingsState   <- STUB
│   │   ├── auth/                    # EMPTY
│   │   ├── diagnosis/               # EMPTY (handled via ScanCubit / UseCases)
│   │   ├── history/                 # EMPTY
│   │   └── sync/                    # EMPTY
│   ├── domain/
│   │   ├── entities/                # Pure Dart models
│   │   │   ├── app_state.dart       <- IMPLEMENTED
│   │   │   ├── crop.dart            <- IMPLEMENTED
│   │   │   ├── diagnosis.dart       <- IMPLEMENTED (includes DiagnosisResultState, TreatmentSource)
│   │   │   ├── local_user.dart      <- IMPLEMENTED
│   │   │   └── scan.dart            <- IMPLEMENTED (includes ScanStatus enum)
│   │   ├── repositories/            # Abstract interfaces
│   │   │   ├── app_state_repository.dart    <- IMPLEMENTED
│   │   │   ├── crop_repository.dart         <- IMPLEMENTED
│   │   │   ├── diagnosis_repository.dart    <- IMPLEMENTED
│   │   │   ├── local_user_repository.dart   <- IMPLEMENTED
│   │   │   └── scan_repository.dart         <- IMPLEMENTED
│   │   └── usecases/
│   │       ├── onboarding/          # GetAppStateUseCase, CompleteOnboardingUseCase, SetLanguageUseCase
│   │       ├── auth/                # GetOrCreateGuestUserUseCase
│   │       ├── crop/                # GetSupportedCropsUseCase
│   │       ├── scan/                # CaptureScanUseCase, GetScanByIdUseCase
│   │       ├── diagnosis/           # ValidateImageUseCase, RunDiagnosisUseCase <- IMPLEMENTED
│   │       ├── escalation/          # EMPTY
│   │       └── sync/                # EMPTY
│   ├── data/
│   │   ├── local/
│   │   │   ├── database/
│   │   │   │   ├── tables.dart          # All Drift table definitions <- COMPLETE SCHEMA
│   │   │   │   ├── app_database.dart    # Drift DB class, schemaVersion=2, migration
│   │   │   │   └── app_database.g.dart  # Generated; do not edit
│   │   │   ├── datasources/         # EMPTY
│   │   │   └── ml/
│   │   │       └── ml_inference_service.dart # TFLite model load, 224x224 NHWC preprocess, inference
│   │   ├── repositories/            # Concrete impls
│   │   │   ├── app_state_repository_impl.dart   <- IMPLEMENTED
│   │   │   ├── crop_repository_impl.dart        <- IMPLEMENTED (seeds 3 crops)
│   │   │   ├── diagnosis_repository_impl.dart   <- IMPLEMENTED (persists diagnosis)
│   │   │   ├── disease_repository_impl.dart     <- IMPLEMENTED (seeds PlantVillage classes)
│   │   │   ├── local_user_repository_impl.dart  <- IMPLEMENTED
│   │   │   └── scan_repository_impl.dart        <- IMPLEMENTED
│   │   └── sync/                    # EMPTY
│   ├── presentation/
│   │   ├── onboarding/
│   │   │   ├── splash_screen.dart
│   │   │   ├── onboarding_screen.dart
│   │   │   ├── language_selection_screen.dart
│   │   │   ├── localization/
│   │   │   │   ├── app_localizations.dart   # Static string map (EN/SI/TA)
│   │   │   │   └── localization_provider.dart # InheritedWidget + context.tr() extension
│   │   │   └── widgets/
│   │   │       └── change_language_dialog.dart
│   │   ├── home/
│   │   │   └── home_screen.dart
│   │   ├── crop/
│   │   │   └── crop_selection_screen.dart
│   │   ├── scan/
│   │   │   ├── capture_screen.dart
│   │   │   └── scan_result_screen.dart      # Raw scan view
│   │   ├── diagnosis/
│   │   │   └── diagnosis_result_screen.dart # Diagnosis result screen (disease, conf, severity)
│   │   ├── settings/
│   │   │   └── settings_screen.dart         # Shell; language works, rest = Coming Soon
│   │   ├── auth/                    # EMPTY
│   │   ├── history/                 # EMPTY
│   │   └── escalation/              # EMPTY
│   ├── core/
│   │   ├── constants/               # EMPTY
│   │   ├── errors/                  # EMPTY
│   │   ├── localization/            # EMPTY (localization in presentation/onboarding/localization/)
│   │   ├── theme/                   # EMPTY
│   │   └── utils/                   # EMPTY
│   └── platform/                    # EMPTY
├── assets/
│   └── models/
│       └── plant_disease_mobilenetv2.tflite # Bundled MobileNetV2 Float32 TFLite model (~9MB)
├── test/
│   ├── data/repositories/           # app_state_repository_impl_test.dart
│   ├── domain/usecases/             # crop/ & onboarding/ usecase tests
│   ├── presentation/onboarding/     # onboarding_screen_test.dart, language_selection_screen_test.dart
│   ├── presentation/scan/           # capture_screen_test.dart
│   └── widget_test.dart
├── pubspec.yaml
├── CropCare_System_Architecture.md
├── CropCare_Build_Checklist.md
└── Design.md
```

---

## 3. Important Files

| File | Responsibility | Key Classes/Functions | Layer | Important Dependencies | Known Callers |
|---|---|---|---|---|---|
| lib/main.dart | Entry point; DB init, seed crops/diseases, load ML model, wire all use cases & Cubit | main() | — | AppDatabase, all RepositoryImpls, MlInferenceService, all use cases, AppStateCubit | None (root) |
| lib/app.dart | Root widget; routing via AppStateCubit; wraps LocalizationProvider | CropCareApp | Presentation | AppStateCubit, LocalizationProvider, HomeScreen | main.dart |
| lib/application/onboarding/app_state_cubit.dart | Controls onboarding/language state; reads SQLite on init | AppStateCubit | Application | GetAppStateUseCase, CompleteOnboardingUseCase, SetLanguageUseCase | app.dart, SplashScreen, LanguageSelectionScreen, ChangeLanguageDialog, SettingsScreen |
| lib/application/scan/scan_cubit.dart | Camera lifecycle, photo capture, scan persistence, image validation & ML inference chaining | ScanCubit, CameraPermissionService | Application | CaptureScanUseCase, ValidateImageUseCase, RunDiagnosisUseCase, permission_handler | CaptureScreen |
| lib/application/scan/scan_state.dart | States for scan & inference lifecycle | ScanInitial through ScanError, ScanDiagnosing, ScanDiagnosed, ScanImageInvalid (11 states) | Application | Scan entity, Diagnosis entity | ScanCubit, CaptureScreen |
| lib/data/local/database/tables.dart | Drift table definitions — schema source of truth | 9 table classes | Local Data | drift | app_database.dart |
| lib/data/local/database/app_database.dart | Drift DB class; migrations; index creation | AppDatabase, AppDatabase.forTesting() | Local Data | drift, sqlite3_flutter_libs, path_provider | All RepositoryImpl files |
| lib/data/local/ml/ml_inference_service.dart | Loads bundled TFLite model, preprocesses image (224x224 NHWC), runs inference, applies softmax, maps class index to disease ID | MlInferenceService, InferenceResult | Local Data / ML | tflite_flutter, image | RunDiagnosisUseCase, main.dart |
| lib/data/repositories/disease_repository_impl.dart | Seeds disease table with 38 PlantVillage mapped entries; lookup by ID | DiseaseRepositoryImpl, seedDiseasesIfEmpty() | Repository | AppDatabase | main.dart |
| lib/data/repositories/diagnosis_repository_impl.dart | INSERT and SELECT diagnosis rows; JSON serialization for alternatives | DiagnosisRepositoryImpl, createDiagnosis(), getDiagnosisByScanId() | Repository | AppDatabase | RunDiagnosisUseCase, main.dart |
| lib/domain/entities/diagnosis.dart | Pure Dart domain entity for ML diagnosis | Diagnosis, DiagnosisResultState, TreatmentSource, AlternativePrediction | Domain | None | DiagnosisRepository, RunDiagnosisUseCase, ScanCubit, DiagnosisResultScreen |
| lib/domain/usecases/diagnosis/validate_image_use_case.dart | Image quality check (file existence, minimum bytes, decoding, minimum dimensions) | ValidateImageUseCase, ImageValidationResult | Domain | image | ScanCubit, RunDiagnosisUseCase, main.dart |
| lib/domain/usecases/diagnosis/run_diagnosis_use_case.dart | Orchestrates inference: persists image_validation, runs ML service, builds Diagnosis entity, saves to repository | RunDiagnosisUseCase | Domain | MlInferenceService, DiagnosisRepository, AppDatabase | ScanCubit, main.dart |
| lib/presentation/diagnosis/diagnosis_result_screen.dart | Renders ML diagnosis results (disease name, confidence %, severity, result state badge, scan again action) | DiagnosisResultScreen, _ResultStateBadge | Presentation | Diagnosis entity, Scan entity | CaptureScreen (on ScanDiagnosed) |
| lib/presentation/scan/capture_screen.dart | Camera/permission UI, photo review/retake, triggers scan+ML flow, routes to DiagnosisResultScreen on ScanDiagnosed | CaptureScreen, _CaptureView | Presentation | ScanCubit, ImagePicker, ValidateImageUseCase, RunDiagnosisUseCase | CropSelectionScreen |

---

## 4. Architecture in Practice

| Layer | Implemented | Partially | Planned Only | Not Present |
|---|---|---|---|---|
| Presentation | Splash, Onboarding, LanguageSelection, Home, CropSelection, Capture, ScanResult, DiagnosisResult, Settings (shell) | — | Auth, History, Escalation screens | — |
| Application / Cubit | AppStateCubit, ScanCubit (with ML orchestration) | SettingsCubit (stub) | — | AuthCubit, HistoryCubit, SyncStatusCubit |
| Domain / Use Cases | GetAppStateUseCase, CompleteOnboardingUseCase, SetLanguageUseCase, GetOrCreateGuestUserUseCase, GetSupportedCropsUseCase, CaptureScanUseCase, GetScanByIdUseCase, ValidateImageUseCase, RunDiagnosisUseCase | — | TreatmentResolutionUseCase, EscalateToExpertUseCase, SyncPendingOperationsUseCase | — |
| Domain / Entities | AppState, Crop, LocalUser, Scan (+ ScanStatus), Diagnosis (+ DiagnosisResultState, TreatmentSource) | — | Escalation | — |
| Domain / Repository interfaces | AppStateRepository, CropRepository, LocalUserRepository, ScanRepository, DiagnosisRepository | — | EscalationRepository, AuthRepository, ReferenceDataRepository | — |
| Repository (impl) | AppStateRepositoryImpl, CropRepositoryImpl, LocalUserRepositoryImpl, ScanRepositoryImpl, DiagnosisRepositoryImpl, DiseaseRepositoryImpl | — | All others | — |
| Local Data (SQLite) | All 9 tables defined: app_state, local_user, crop, disease, treatment_guideline, model_version, scan, image_validation, diagnosis | — | — | sync_operation table (not in schema yet) |
| ML Inference | On-device TFLite MobileNetV2 (float32, 224x224 NHWC, 38-class softmax) via `tflite_flutter` + `image` | — | — | — |
| Remote Data | — | — | HTTP client to FastAPI | No dio/http package |
| Platform Services | Camera (image_picker), Permissions (permission_handler) | — | TTS, Notifications, WorkManager | No code |
| Sync Engine | — | — | Outbox pattern, background sync | No code; no sync_operation table |

---

## 5. Implemented Runtime Flows

### App Startup

```
main()
  -> AppDatabase() [open cropcare.db]
  -> LocalUserRepositoryImpl.getOrCreateGuestUser()
       [INSERT or SELECT local_user WHERE is_guest=1]
  -> CropRepositoryImpl -> GetSupportedCropsUseCase()
       [SELECT crop -> if empty: seeds Tomato, Chili, Paddy]
  -> DiseaseRepositoryImpl.seedDiseasesIfEmpty()
       [SELECT disease -> if empty: seeds Tomato, Chili/Pepper, Paddy diseases]
  -> MlInferenceService.loadModel()
       [Loads assets/models/plant_disease_mobilenetv2.tflite into TFLite Interpreter]
  -> AppStateCubit (init -> loadAppState())
       -> GetAppStateUseCase -> AppStateRepositoryImpl.getAppState()
            -> SELECT app_state WHERE id=1
            -> if missing: INSERT defaults (onboarding_completed=0, language=en)
       -> emits AppStateOnboardingNeeded | AppStateOnboardingComplete
  -> runApp(CropCareApp(appStateCubit, user, useCases...))
  -> BlocBuilder<AppStateCubit>:
       AppStateLoading            -> CircularProgressIndicator
       AppStateOnboardingComplete -> HomeScreen
       else                       -> SplashScreen
```

### Image Capture, Image Validation & ML Diagnosis Flow

```
UI: ScanCameraReady -> user taps capture button
  -> _handleCapture():
       -> ImagePicker.pickImage(source: camera, quality: 90) -> XFile?
       -> ScanCubit.photoCaptured(cropId, tempImagePath)
       -> emit ScanPhotoCaptured

UI: ScanPhotoCaptured -> review/retake/use
  Retake     -> ScanCubit.retakePhoto() -> delete temp file -> emit ScanCameraReady
  Use Photo  -> ScanCubit.confirmPhoto(userId: user.id)
       -> emit ScanCreating
       -> copy temp file to <docs>/scans/scan_<timestamp>.<ext>
       -> CaptureScanUseCase(cropId, finalPath, userId)
            -> ScanRepositoryImpl.createScan() [INSERT scan (status=CREATED)]
       -> emit ScanDiagnosing
       -> ValidateImageUseCase(finalPath)
            -> Check file existence, size >= 5KB, decodable, min 100x100
            -> If invalid: emit ScanImageInvalid(reason)
       -> RunDiagnosisUseCase(scanId, finalPath, validationResult)
            -> INSERT image_validation (is_usable, rejection_reason, checked_at)
            -> MlInferenceService.runInference(finalPath):
                 -> Resize image to 224x224 NHWC float32 [0..1]
                 -> Interpreter.run(input, output) [raw logits]
                 -> Softmax(logits) -> probabilities
                 -> Map top class index -> diseaseId (or null if unsupported crop)
                 -> Set resultState: CONFIDENT (>=0.60), LOW_CONFIDENCE, or UNSUPPORTED
            -> DiagnosisRepositoryImpl.createDiagnosis(diagnosis)
                 -> INSERT diagnosis row
       -> emit ScanDiagnosed(scan, diagnosis)

BlocConsumer listener (CaptureScreen): ScanDiagnosed
  -> Navigator.pushReplacement -> DiagnosisResultScreen(scan, diagnosis)
       [Shows detected disease, confidence %, severity, result status badge, scan again button]
```

---

## 6. State Management

| Cubit | File | State Types | Controls | Calls | Key Transitions |
|---|---|---|---|---|---|
| AppStateCubit | application/onboarding/app_state_cubit.dart | AppStateLoading, AppStateOnboardingNeeded, AppStateOnboardingComplete | App routing; language code | GetAppStateUseCase, CompleteOnboardingUseCase, SetLanguageUseCase | loadAppState() on init; completeOnboarding() -> Complete; setLanguage() -> preserves complete/needed |
| ScanCubit | application/scan/scan_cubit.dart | ScanInitial, ScanPermissionChecking, ScanPermissionDenied, ScanCameraReady, ScanPhotoCaptured, ScanCreating, ScanCreated, ScanDiagnosing, ScanDiagnosed, ScanImageInvalid, ScanError | Camera permission lifecycle; photo capture; scan persistence; image validation; ML diagnosis | CaptureScanUseCase, ValidateImageUseCase, RunDiagnosisUseCase, CameraPermissionService | Permission -> CameraReady; capture -> PhotoCaptured; confirm -> ScanCreating -> ScanDiagnosing -> ScanDiagnosed / ScanImageInvalid |
| SettingsCubit | application/settings/settings_cubit.dart | SettingsState (expandedSection) | Nothing functional | Nothing | toggleSection() only — no real use currently |

---

## 7. Data Models

### Domain Entities (pure Dart, no framework deps)

| Entity | File | Key Fields | Notes |
|---|---|---|---|
| AppState | domain/entities/app_state.dart | onboardingCompleted, languageCode, firstLaunchAt | No lastSyncAt in entity (only in DB table) |
| Crop | domain/entities/crop.dart | id, nameEn, nameSi?, nameTa?, isSupported, iconAsset? | getLocalizedName(languageCode) helper method |
| LocalUser | domain/entities/local_user.dart | id (local UUID), remoteUserId?, email?, phoneNumber?, isGuest, sessionToken?, ... | Session tokens stored in plain SQLite |
| Scan | domain/entities/scan.dart | id (local UUID), remoteScanId?, userId, cropId, imageLocalPath, imageRemoteUrl?, status, timestamps | Includes ScanStatus enum (10 values) |
| Diagnosis | domain/entities/diagnosis.dart | id, scanId, diseaseId?, modelVersionId, confidence, resultState, severity?, alternatives, treatmentSource, treatmentGuidelineId?, inferredAt | Enums: DiagnosisResultState, TreatmentSource; AlternativePrediction class |

### SQLite Tables (Drift — data/local/database/tables.dart)

| Table | Key Columns | Notes |
|---|---|---|
| app_state | id=1 (singleton), onboarding_completed, language_code, first_launch_at, last_sync_at | Singleton enforced at app layer |
| local_user | id (UUID PK), remote_user_id?, email?, phone_number?, is_guest, session fields | Tokens in plain SQLite |
| crop | id (text PK), name_en, name_si?, name_ta?, is_supported, icon_asset? | Auto-seeded with Tomato, Chili, Paddy |
| disease | id (text PK), crop_id (FK->crop), name_en, name_si?, name_ta?, severity_default? | Seeded by DiseaseRepositoryImpl with PlantVillage classes |
| treatment_guideline | id, disease_id (FK->disease), guideline_version, summary/what_to_do/what_to_avoid in 3 langs, recheck_after_days? | Table exists; content seeding pending |
| model_version | id, released_at?, is_active | Table exists |
| scan | id (UUID PK), remote_scan_id?, user_id (FK->local_user), crop_id (FK->crop), image_local_path, imageRemoteUrl?, status, timestamps | Written with status=CREATED on scan capture |
| image_validation | id, scan_id (FK->scan), is_usable, rejection_reason?, checked_at | Written during RunDiagnosisUseCase execution |
| diagnosis | id, scan_id (FK->scan), disease_id?, model_version_id, confidence, result_state, severity?, alternatives_json?, treatment_source, treatment_guideline_id?, llm_interpretation_id?, inferred_at | Written during RunDiagnosisUseCase execution |

---

## 8. Dependencies and Integrations

| Package | In pubspec.yaml | Current Usage |
|---|---|---|
| flutter_bloc ^8.1.3 | Yes | AppStateCubit, ScanCubit, SettingsCubit; BlocProvider, BlocBuilder, BlocConsumer |
| drift ^2.9.0 | Yes | All local SQLite persistence (9 tables) |
| sqlite3_flutter_libs ^0.5.0 | Yes | Native SQLite binaries for Drift |
| path_provider ^2.1.0 | Yes | DB file location; scan image storage directory |
| path ^1.8.3 | Yes | File path manipulation |
| image_picker ^1.0.4 | Yes | Camera capture in CaptureScreen |
| camera ^0.10.5+9 | Yes | Added for native camera support |
| permission_handler ^11.0.0 | Yes | Camera permission in ScanCubit |
| tflite_flutter ^0.12.0 | Yes | On-device ML inference for plant disease classification |
| image ^4.1.7 | Yes | Image decoding, resizing (224x224), and pixel normalization for ML tensor input |
| supabase_flutter ^2.5.0 | Yes | NOT USED — zero Supabase imports in any Dart file (dead dependency) |
| cupertino_icons ^1.0.8 | Yes | Icons only |
| drift_dev ^2.9.0 | dev | Code generation |
| build_runner ^2.4.0 | dev | Code generation |
| flutter_lints ^6.0.0 | dev | Linting |

---

## 9. ML Integration Details

- **Model File**: `assets/models/plant_disease_mobilenetv2.tflite` (~9.05 MB float32 TFLite converted from ONNX via onnx2tf).
- **Input Tensor**: `[1, 224, 224, 3]` float32 (NHWC), normalized to `[0.0, 1.0]`.
- **Output Tensor**: `[1, 38]` float32 raw logits converted to probabilities via softmax in `MlInferenceService`.
- **Supported Mapping**: 
  - All 15 crops (Apple, Blueberry, Cherry, Corn, Grape, Orange, Peach, Chili/Pepper, Potato, Raspberry, Soybean, Squash, Strawberry, Tomato, Paddy) are seeded in `crop` table with localization.
  - All 38 output classes are mapped directly to SQLite disease IDs in `MlInferenceService`.
  - Non-crop inputs below the threshold or unclassifiable result in `DiagnosisResultState.lowConfidence`.
- **Confidence Threshold**: 0.60 (below threshold results in `DiagnosisResultState.lowConfidence`).

---

## 10. AI Implementation Rules

1. Treat the actual source code as the source of truth. The architecture and checklist describe the target; the code describes what exists.
2. Preserve the layered architecture: Presentation -> Application (Cubit) -> Domain (use case) -> Repository (interface) -> Data (impl). Do not skip layers.
3. Do not bypass main.dart composition root by creating extra AppDatabase() instances inside screens.
4. Prefer modifying existing appropriate files over creating new ones. Check the directory structure before creating anything.
5. Do not refactor unrelated code. Touch only what is needed for the task.
6. Do not introduce patterns not already present. No get_it, no freezed, no equatable, no go_router unless explicitly requested.
7. Before implementing any feature, identify the minimum files to create or modify. State them explicitly before writing code.
8. Keep implementations minimal for the MVP. No over-engineering.
9. Do not infer that a component exists because the architecture mentions it. Verify via the file tree and file contents.
10. Do not silently change architectural decisions.
11. New entities must have: a domain entity, a repository interface, a repository impl, and a Drift table registration — in that dependency order.
12. New strings must be added in all three languages in app_localizations.dart.
13. After any schema change in tables.dart, increment AppDatabase.schemaVersion and add a migration in MigrationStrategy.onUpgrade.
14. The sync_operation table does not exist yet. Do not assume sync infrastructure is available.
15. When uncertain, read the relevant source file before making a change.
