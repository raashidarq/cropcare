# CropCare — CODEBASE_MAP.md

> **Purpose:** Compact, accurate description of the **current** Flutter codebase for future AI coding agents.
> **Source hierarchy:** Actual code > `CropCare_System_Architecture.md` > `CropCare_Build_Checklist.md`
> **Last updated:** 2026-08-26 (design system, camera-first capture, bottom-nav shell, OOD image gate, sync-failure UI)

---

## 1. Current Status

### What CropCare currently does
A Flutter mobile app (Android primary) that lets a guest or registered farmer select a crop, capture a leaf photo (or select from gallery), validate image quality on-device, run on-device ML inference using a bundled MobileNetV2 TFLite model, persist scans and diagnoses in local SQLite, query Gemini via FastAPI for localized treatment guidance, listen to treatment recommendations via Text-to-Speech (TTS), escalate low-confidence results to experts via WhatsApp with photo attachments, view filterable scan history, export a portable CSV copy of scan history offline, authenticate/link accounts via FastAPI/Supabase Auth with secure token storage, reset passwords via email, delete accounts securely, submit farmer feedback directly from the app, browse interactive FAQs, review Terms of Service & Privacy Policy, and idempotently sync offline scans, diagnoses, escalations, and images (via Supabase Storage signed URLs) to the cloud.

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
| Photo capture via image_picker (Camera & Gallery support) | Done |
| Photo review / retake | Done |
| Image validation (dimension, decodability, size checks) | Done |
| On-device ML inference (`tflite_flutter`, MobileNetV2 float32) | Done |
| Scan row INSERT to SQLite (status=CREATED) | Done |
| Image validation row INSERT to SQLite | Done |
| Diagnosis row INSERT to SQLite (CONFIDENT, LOW_CONFIDENCE, UNSUPPORTED, ANALYSIS_FAILED) | Done |
| DiagnosisResultScreen (disease name, confidence %, severity, low confidence banner, observations, Gemini treatment card, scan again) | Done |
| Treatment Guidance (FastAPI `POST /interpret-diagnosis` client, ResolveTreatmentUseCase, DiagnosisCubit) | Done |
| Text-to-Speech (TTS) audio playback (`flutter_tts`, `TextToSpeechService`, Android 11+ `<queries>` declared, localized EN/SI/TA reading for both Gemini & offline fallback cards) | Done |
| Escalation & WhatsApp Share Flow (EscalationScreen, EscalationCubit, attached photo, low-confidence advisory) | Done |
| Embedded Scan History (HomeScreen history section, HistoryCubit, filter chips, tap-to-review) | Done |
| Scan History Data Export (ExportScanHistoryUseCase, CSV generation, offline native sharing via `share_plus` from Settings & Home History header) | Done |
| Authentication & Guest-to-Registered User Upgrade (AuthApiClient, AuthRepository, AuthCubit, AuthScreen, OtpEntryScreen, secure storage, post-auth auto-sync hook, phone OTP gated by feature flag) | Done |
| Email Forgot Password Flow (AuthApiClient `POST /auth/forgot-password`, RequestPasswordResetUseCase, AuthCubit state `AuthPasswordResetSent`, ForgotPasswordScreen) | Done |
| Profile Screen & Account Deletion (`ProfileScreen`, `DeleteAccountUseCase`, `AuthApiClient` `DELETE /auth/account`, secure storage wipe, guest mode reset) | Done |
| Farmer Feedback Submission (`FeedbackScreen` with multi-line textbox, category selector, `SubmitFeedbackUseCase`, `AuthApiClient` `POST /feedback`) | Done |
| Terms of Service & Privacy Policy (TermsPrivacyScreen with TabBar, accessible from Settings and Sign-Up consent disclaimer) | Done |
| Interactive FAQ Screen (FaqScreen categorized into Scanning & Diagnosis, Account & Cloud Sync, accessible from Settings) | Done |
| Offline Sync Engine (`sync_operation` outbox Drift table, SyncApiClient with signed URL binary upload + idempotency, ScanTable enrichment, SyncRepositoryImpl, SyncCubit, downstream reference data sync) | Done |
| App-level connectivity listener (auto-sync on network recovery, 3 s debounce, offline→online transition only) | Done |
| Background periodic WorkManager worker (15-min interval, `NETWORK_CONNECTED` constraint, Dart background isolate via `workmanager` plugin) | Done |
| Reorganized Settings Screen (Profile & Account, Preferences, Data & Storage, Support & Legal, App Version) | Done |
| SQLite schema (14 Drift tables + migrations, schemaVersion=7) | Done |
| Full localization string tables (EN/SI/TA — 341 keys, parity enforced by review) | Done |
| Full automated test suite (147 Flutter tests passing) | Done |
| Design system (`lib/core/theme/`: colours, type, spacing, radius; bundled Noto EN/SI/TA fonts) | Done |
| Bottom-navigation shell (Home / History / Account, lazily built tabs) | Done |
| Live camera viewfinder with leaf-framing guide (`camera` package) | Done |
| Pre-inference image content gate (exposure, blur, vegetation) — rejects non-plant photos | Done |
| Offline disease-explanation schema + UI (**ships with no content**) | Schema + UI only |
| Failed-sync & session-expired UI in `OfflineScreen` | Done |
| "Ask about this result" (chat) | Placeholder entry point + brief only |
| Speak-your-observations (voice transcription) | Placeholder entry point + brief only |

### What is not implemented
- Push notifications.
- Token refresh. `sessionRefreshToken` is stored and never used; a session
  simply dies. The UI surfaces this (TD-019) but the backend work is open.
- Localised disease names. `disease.name_si` / `name_ta` exist and are
  populated only for the 12 classes added in 2026-08; the original 40 are
  still English in all three languages.
- Offline explanation **content**. The tables, read path and UI exist; both
  tables ship empty and nothing seeds them (TD-018).

---

## 2. Repository Structure

```
cropcare/
├── lib/
│   ├── main.dart                    # Entry point; DB + repos + seeders + ML model + cubits
│   ├── app.dart                     # CropCareApp widget; BlocProvider root; routing logic
│   ├── config/
│   │   └── feature_flags.dart       # kPhoneAuthEnabled flag
│   ├── core/
│   │   ├── theme/                   # THE design system — see TD-012
│   │   │   ├── app_colors.dart      # every semantic colour token
│   │   │   ├── app_text_styles.dart # language-aware TextTheme (EN/SI/TA)
│   │   │   ├── app_spacing.dart     # 8pt scale
│   │   │   ├── app_radius.dart      # 8/12/16/full
│   │   │   └── app_theme.dart       # AppTheme.light() / .highContrast()
│   │   └── constants/
│   │       └── crop_visuals.dart    # per-crop icon + accent colour
│   ├── services/
│   │   ├── camera_service.dart          # seam over availableCameras()/CameraController
│   │   ├── connectivity_service.dart    # connectivity_plus wrapper; debounced bool stream
│   │   └── work_manager_helper.dart     # callbackDispatcher + WorkManagerHelper (init/schedule/cancel)
│   ├── application/                 # Cubits (state management, one per feature)
│   │   ├── auth/                    # AuthCubit + AuthState (register, login, phone OTP, upgrade, signout)
│   │   ├── diagnosis/               # DiagnosisCubit + DiagnosisState (treatment guidance fetch)
│   │   ├── escalation/              # EscalationCubit + EscalationState (WhatsApp sharing)
│   │   ├── history/                 # HistoryCubit + HistoryState (scan history list & filtering)
│   │   ├── onboarding/              # AppStateCubit + AppStateState
│   │   ├── scan/                    # ScanCubit + ScanState (camera & ML inference orchestration)
│   │   ├── settings/                # SettingsCubit + SettingsState
│   │   └── sync/                    # SyncCubit + SyncState (pending count & syncNow execution)
│   ├── domain/
│   │   ├── entities/                # Pure Dart models
│   │   │   ├── app_state.dart
│   │   │   ├── crop.dart
│   │   │   ├── diagnosis.dart       # Diagnosis, DiagnosisResultState, TreatmentSource, AlternativePrediction
│   │   │   ├── escalation.dart
│   │   │   ├── local_user.dart
│   │   │   ├── scan.dart            # Scan, ScanStatus
│   │   │   ├── scan_history_item.dart
│   │   │   ├── sync_operation.dart  # SyncOperation, SyncEntityType, SyncOperationStatus
│   │   │   └── treatment.dart       # TreatmentResponse
│   │   ├── repositories/            # Abstract interfaces
│   │   │   ├── app_state_repository.dart
│   │   │   ├── auth_repository.dart
│   │   │   ├── crop_repository.dart
│   │   │   ├── diagnosis_repository.dart
│   │   │   ├── escalation_repository.dart
│   │   │   ├── local_user_repository.dart
│   │   │   ├── scan_repository.dart
│   │   │   ├── sync_repository.dart
│   │   │   └── treatment_repository.dart
│   │   └── usecases/
│   │       ├── auth/                # GetOrCreateGuestUser, UpgradeGuestUser, SignIn, SignOut, RequestPhoneOtp, VerifyPhoneOtp
│   │       ├── crop/                # GetSupportedCropsUseCase
│   │       ├── diagnosis/           # ValidateImage, RunDiagnosis, ResolveTreatment
│   │       ├── escalation/          # CreateEscalationUseCase
│   │       ├── history/             # GetScanHistoryUseCase
│   │       └── onboarding/          # GetAppState, CompleteOnboarding, SetLanguage
│   ├── data/
│   │   ├── local/
│   │   │   ├── database/
│   │   │   │   ├── tables.dart          # All 11 Drift table definitions (schema source of truth)
│   │   │   │   ├── app_database.dart    # Drift DB class, schemaVersion=7, migrations
│   │   │   │   └── app_database.g.dart  # Generated; do not edit
│   │   │   ├── ml/
│   │   │   │   └── ml_inference_service.dart # TFLite model load, 224x224 NHWC preprocess, inference
│   │   │   └── tts/
│   │   │       └── text_to_speech_service.dart # TtsService interface & TextToSpeechService (flutter_tts)
│   │   ├── remote/
│   │   │   ├── auth_api_client.dart     # FastAPI /auth/register & /auth/login client
│   │   │   ├── sync_api_client.dart     # Signed upload URL, PUT image binary, POST /scans, /diagnoses, /escalations
│   │   │   └── treatment_api_client.dart# FastAPI /interpret-diagnosis client
│   │   └── repositories/            # Concrete impls
│   │       ├── app_state_repository_impl.dart
│   │       ├── auth_repository_impl.dart
│   │       ├── crop_repository_impl.dart
│   │       ├── diagnosis_repository_impl.dart
│   │       ├── disease_repository_impl.dart
│   │       ├── escalation_repository_impl.dart
│   │       ├── local_user_repository_impl.dart
│   │       ├── scan_repository_impl.dart
│   │       ├── sync_repository_impl.dart
│   │       └── treatment_repository_impl.dart
│   └── presentation/
│       ├── auth/
│       │   ├── auth_screen.dart             # Tabbed Sign In / Register & Guest Upgrade with Phone/Email method toggle
│       │   └── otp_entry_screen.dart        # Parameterized 6-digit OTP verification screen (countdown, error banners)
│       ├── crop/
│       │   └── crop_selection_screen.dart   # Crop selector with cancel navigation
│       ├── diagnosis/
│       │   └── diagnosis_result_screen.dart # Diagnosis results, Gemini guidance card, TTS button
│       ├── escalation/
│       │   └── escalation_screen.dart       # WhatsApp escalation card, 1-tap Copy Summary to Clipboard, Other Apps sharing
│       ├── home/
│       │   ├── home_screen.dart             # bottom-nav shell: Home / History / Account (TD-016)
│       │   └── widgets/
│       │       ├── home_dashboard.dart      # scan CTA, stats, sync banner, recent scans
│       │       ├── history_view.dart        # full filterable history (its own tab)
│       │       └── scan_history_card.dart   # shared history row
│       ├── onboarding/
│       │   ├── splash_screen.dart
│       │   ├── onboarding_screen.dart
│       │   ├── language_selection_screen.dart
│       │   ├── localization/
│       │   │   ├── app_localizations.dart   # String map (EN/SI/TA)
│       │   │   └── localization_provider.dart
│       │   └── widgets/
│       │       └── change_language_dialog.dart
│       ├── shared/
│       │   └── widgets/
│       │       ├── app_components.dart      # AppCard, AppBanner, AppStatusChip, AppConfidenceMeter, AppSegmentedToggle, ...
│       │       └── app_state_views.dart     # AppLoadingView / AppEmptyView / AppErrorView
│       ├── scan/
│       │   ├── capture_screen.dart          # camera-first: live viewfinder, shutter, in-camera gallery, review
│       │   ├── add_photo_screen.dart        # legacy chooser — no longer on the default path (TD-015)
│       │   ├── widgets/
│       │   │   ├── camera_preview_view.dart # CameraController lifecycle + no-camera fallback
│       │   │   └── leaf_frame_overlay.dart  # framing guide CustomPainter
│       │   └── scan_result_screen.dart
│       └── settings/
│           ├── settings_screen.dart         # Reorganized 4 sections: Profile, Preferences, Data & Storage, Support & Legal
│           ├── profile_screen.dart          # User details, Link Account / Sign Out, Danger Zone (Account Deletion)
│           ├── feedback_screen.dart         # Farmer feedback & bug report submission
│           ├── faq_screen.dart              # Accordion FAQ & Help center
│           └── terms_privacy_screen.dart    # Terms of Service and Privacy Policy tabs
├── docs/
│   └── future/                              # implementation briefs for unbuilt features
│       ├── chat_with_result_implementation.md
│       └── voice_observations_implementation.md
├── assets/
│   ├── fonts/                               # bundled Noto (Latin/Sinhala/Tamil) + OFL.txt
│   ├── icon/
│   │   └── app_icon.png
│   └── models/
│       └── plant_disease_mobilenetv2.tflite # Bundled MobileNetV2 Float32 TFLite model (~9MB)
├── test/
│   ├── application/                         # Cubit unit tests (auth, diagnosis, escalation, history, sync)
│   ├── data/
│   │   ├── local/tts/                       # text_to_speech_service_test.dart
│   │   ├── remote/                          # auth, sync, treatment api client tests
│   │   └── repositories/                    # app_state_repository_impl_test.dart
│   ├── domain/usecases/                     # crop, diagnosis, escalation, history, onboarding tests
│   ├── presentation/                        # Screen widget tests (auth, diagnosis, escalation, home, onboarding, scan)
│   └── widget_test.dart
├── pubspec.yaml
├── CropCare_System_Architecture.md
├── CropCare_Build_Checklist.md
└── CODEBASE_MAP.md
```

---

## 3. Important Files

| File | Responsibility | Key Classes/Functions | Layer | Important Dependencies | Known Callers |
|---|---|---|---|---|---|
| `lib/main.dart` | Entry point; DB init, seed crops/diseases, load ML model, wire all repos, use cases & Cubits | `main()` | — | `AppDatabase`, all `RepositoryImpl`s, `MlInferenceService`, all use cases, Cubits | None (root) |
| `lib/app.dart` | Root widget; routing via `AppStateCubit`; wraps `LocalizationProvider` | `CropCareApp` | Presentation | `AppStateCubit`, `LocalizationProvider`, `HomeScreen` | `main.dart` |
| `lib/data/local/database/tables.dart` | Drift table definitions — schema source of truth (11 tables) | 11 table classes | Local Data | `drift` | `app_database.dart` |
| `lib/data/local/database/app_database.dart` | Drift DB class; migrations up to schemaVersion=7; index creation | `AppDatabase`, `AppDatabase.forTesting()` | Local Data | `drift`, `sqlite3_flutter_libs`, `path_provider` | All `RepositoryImpl` files |
| `lib/data/local/ml/ml_inference_service.dart` | Loads bundled TFLite model, preprocesses image (224x224 NHWC), runs inference, applies softmax, maps class index to disease ID | `MlInferenceService`, `InferenceResult` | Local Data / ML | `tflite_flutter`, `image` | `RunDiagnosisUseCase`, `main.dart` |
| `lib/data/local/tts/text_to_speech_service.dart` | Audio speech synthesis for localized treatment guidance | `TtsService`, `TextToSpeechService` | Local Data / Audio | `flutter_tts` | `DiagnosisResultScreen` |
| `lib/data/remote/sync_api_client.dart` | Signed URL generation, image binary upload, idempotent REST sync, reference data fetch | `SyncApiClient` | Remote Data | `http` | `SyncRepositoryImpl` |
| `lib/data/repositories/sync_repository_impl.dart` | Outbox processor; reads pending ops, executes two-step image + metadata sync, enriches local scan records, syncs downstream reference data, tracks retries | `SyncRepositoryImpl` | Repository | `AppDatabase`, `SyncApiClient` | `SyncCubit`, `main.dart` |
| `lib/data/repositories/treatment_repository_impl.dart` | Fetches remote AI recommendations with seamless automatic fallback to local SQLite guidelines when offline | `TreatmentRepositoryImpl` | Repository | `TreatmentApiClient`, `AppDatabase` | `ResolveTreatmentUseCase`, `main.dart` |
| `lib/application/sync/sync_cubit.dart` | Manages pending sync count, token-authenticated sync execution, and reference data sync | `SyncCubit`, `SyncState` | Application | `SyncRepository`, `AuthRepository` | `SettingsScreen`, `AuthScreen`, `main.dart` |
| `lib/core/theme/app_colors.dart` | Every semantic colour token; single severity→colour mapping | `AppColors` | Core | — | Every screen |
| `lib/core/theme/app_text_styles.dart` | Language-aware TextTheme; picks Noto face per language with the other two as fallback | `AppTextStyles` | Core | bundled fonts | `AppTheme` |
| `lib/presentation/shared/widgets/app_components.dart` | Canonical cards, banners, chips, confidence meter, segmented toggle | `AppCard`, `AppBanner`, `AppStatusChip`, `AppConfidenceMeter`, `AppSegmentedToggle` | Presentation | theme tokens | Most screens |
| `lib/domain/usecases/diagnosis/validate_image_use_case.dart` | Technical + **content** gate before inference; the OOD fix (TD-014) | `ValidateImageUseCase`, `ImageRejectionReason` | Domain | `image` | `ScanCubit`, `RunDiagnosisUseCase` |
| `lib/services/camera_service.dart` | Testable seam over the camera plugin; empty list when no camera | `CameraService`, `DefaultCameraService` | Services | `camera` | `CaptureScreen` |
| `lib/presentation/diagnosis/diagnosis_result_screen.dart` | Renders ML diagnosis results, AI / Offline treatment guidance card, and TTS read-aloud button | `DiagnosisResultScreen`, `_TreatmentLoadedCard` | Presentation | `Diagnosis`, `Scan`, `DiagnosisCubit`, `TtsService` | `CaptureScreen`, `HomeScreen` |
| `lib/presentation/settings/settings_screen.dart` | Account linking/signout, language selector, and Offline Data & Cloud Sync card | `SettingsScreen` | Presentation | `SettingsCubit`, `AuthCubit`, `SyncCubit`, `AppStateCubit` | `HomeScreen` |
| `lib/presentation/auth/auth_screen.dart` | Tabbed sign-in/register screen with automatic post-auth cloud sync hook | `AuthScreen` | Presentation | `AuthCubit`, `SyncCubit` | `SettingsScreen` |
| `lib/presentation/escalation/escalation_screen.dart` | Low-confidence advisory, WhatsApp formatted sharing with leaf photo attachment | `EscalationScreen` | Presentation | `EscalationCubit`, `share_plus` | `DiagnosisResultScreen`, `HomeScreen` |

---

## 4. Architecture in Practice

| Layer | Implemented | Partially | Planned Only | Not Present |
|---|---|---|---|---|
| Presentation | Splash, Onboarding, LanguageSelection, Home, CropSelection, Capture, ScanResult, DiagnosisResult (with TTS & Offline badges), Settings, Auth (with auto-sync hook), Escalation | — | — | — |
| Application / Cubit | AppStateCubit, ScanCubit, AuthCubit, DiagnosisCubit, HistoryCubit, EscalationCubit, SyncCubit | SettingsCubit | — | — |
| Domain / Use Cases | GetAppState, CompleteOnboarding, SetLanguage, GetOrCreateGuestUser, UpgradeGuestUser, SignIn, SignOut, GetSupportedCrops, CaptureScan, GetScanById, ValidateImage, RunDiagnosis, ResolveTreatment, CreateEscalation, GetScanHistory | — | SyncPendingOperations (encapsulated in repository) | — |
| Domain / Entities | AppState, Crop, LocalUser, Scan (+ ScanStatus), Diagnosis (+ DiagnosisResultState, TreatmentSource), Escalation, SyncOperation, Treatment, ScanHistoryItem | — | — | — |
| Domain / Repository interfaces | AppStateRepository, AuthRepository, CropRepository, DiagnosisRepository, EscalationRepository, LocalUserRepository, ScanRepository, SyncRepository, TreatmentRepository | — | — | — |
| Repository (impl) | AppStateRepositoryImpl, AuthRepositoryImpl, CropRepositoryImpl, DiagnosisRepositoryImpl, DiseaseRepositoryImpl, EscalationRepositoryImpl, LocalUserRepositoryImpl, ScanRepositoryImpl, SyncRepositoryImpl, TreatmentRepositoryImpl | — | — | — |
| Local Data (SQLite) | All 11 tables defined: app_state, local_user, crop, disease, treatment_guideline, model_version, scan, image_validation, diagnosis, escalation, sync_operation | — | — | — |
| ML Inference | On-device TFLite MobileNetV2 (float32, 224x224 NHWC, 38-class softmax) via `tflite_flutter` + `image` | — | — | — |
| Remote Data | FastAPI clients: AuthApiClient, TreatmentApiClient, SyncApiClient (outbox upload + reference data sync) | — | — | — |
| Platform Services | Camera (`image_picker`, `camera`), Permissions (`permission_handler`), Secure Storage (`flutter_secure_storage`), Sharing (`share_plus`), TTS (`flutter_tts`, Android 11+ `<queries>`), Connectivity (`connectivity_plus`, `ACCESS_NETWORK_STATE`), WorkManager (`workmanager` plugin, 15-min periodic background isolate) | — | — | — |
| Sync Engine | Outbox table (`sync_operation`), auto-enqueue in repositories, two-stage binary image upload via signed URLs, scan record enrichment, idempotent upserts, post-auth auto-trigger, manual UI sync, downstream reference data sync, connectivity listener (auto-sync on reconnect), periodic WorkManager background worker | — | — | — |

---

## 5. Implemented Runtime Flows

### 1. App Startup
```
main()
  -> AppDatabase() [open cropcare.db, migrate to v4]
  -> LocalUserRepositoryImpl.getOrCreateGuestUser() [INSERT or SELECT local_user]
  -> CropRepositoryImpl -> GetSupportedCropsUseCase() [Seed 15 crops if empty]
  -> DiseaseRepositoryImpl.seedDiseasesIfEmpty() [Seed 38 PlantVillage + Paddy classes & treatment guidelines]
  -> MlInferenceService.loadModel() [Load assets/models/plant_disease_mobilenetv2.tflite]
  -> AppStateCubit (init -> loadAppState())
  -> runApp(CropCareApp(...))
```

### 2. Image Capture, ML Diagnosis & Treatment Flow
```
HomeScreen scan CTA -> CaptureScreen (live viewfinder, gallery inline)
  [AddPhotoScreen is no longer on this path — TD-015]
CaptureScreen (photo captured) -> ScanCubit.confirmPhoto()
  -> CaptureScanUseCase -> ScanRepositoryImpl.createScan() [INSERT scan + enqueue outbox SCAN operation]
  -> ValidateImageUseCase (exists / size / decodable / dimensions
       / exposure / blur / vegetation-coverage)
       -> if REJECTED: RunDiagnosisUseCase.rejectInvalidImage()
            [writes image_validation, marks scan INVALID_IMAGE,
             CANCELS the queued upload, deletes the local file]
          ScanCubit emits ScanImageInvalid -> CaptureScreen shows the reason
  -> RunDiagnosisUseCase:
       -> INSERT image_validation
       -> MlInferenceService.runInference()
       -> DiagnosisRepositoryImpl.createDiagnosis() [INSERT diagnosis + enqueue outbox DIAGNOSIS operation]
  -> ScanDiagnosed -> DiagnosisResultScreen
       [offline explanation loads automatically; treatment does NOT]
  -> user taps "Get Treatment Guidance" (TD-017)
  -> DiagnosisCubit.fetchTreatmentGuidance() -> TreatmentRepositoryImpl:
       -> Try: TreatmentApiClient (POST /interpret-diagnosis)
       -> Catch: Query local SQLite treatment_guideline table
  -> TreatmentLoaded (Gemini AI or Offline Guideline badge)
  -> User taps "Read Aloud" -> TextToSpeechService.speak(summary + whatToDo + whatToAvoid in active language)
```

### 3. Offline Outbox & Reference Data Sync Flow
```
Repositories (Scan, Diagnosis, Escalation) -> Insert/Update entity & enqueue row in sync_operation (status='PENDING')
Trigger: User taps "Sync Now" in Settings OR logs in / upgrades account via AuthScreen
SyncCubit.syncNow(token?):
  -> AuthRepository.getStoredToken() (or passed session token)
  -> SyncRepositoryImpl.getPendingOperations():
       -> For each SCAN: SyncApiClient.getSignedUploadUrl() -> PUT image bytes -> POST /scans -> Enrich local ScanTable (image_remote_url, remote_scan_id)
       -> For each DIAGNOSIS: POST /diagnoses
       -> For each ESCALATION: POST /escalations
       -> Update sync_operation status='COMPLETED'
  -> SyncRepositoryImpl.syncReferenceData():
       -> SyncApiClient.fetchReferenceData(since: app_state.last_sync_at)
       -> Upsert CropTable, DiseaseTable, TreatmentGuidelineTable
       -> Update app_state.last_sync_at
```

---

## 6. State Management

| Cubit | File | State Types | Controls | Calls |
|---|---|---|---|---|
| `AppStateCubit` | `application/onboarding/app_state_cubit.dart` | `AppStateLoading`, `AppStateOnboardingNeeded`, `AppStateOnboardingComplete` | App routing & language code | `GetAppStateUseCase`, `CompleteOnboardingUseCase`, `SetLanguageUseCase` |
| `ScanCubit` | `application/scan/scan_cubit.dart` | `ScanInitial` through `ScanDiagnosed`, `ScanImageInvalid`, `ScanError` (11 states) | Camera lifecycle, capture, image validation, ML inference | `CaptureScanUseCase`, `ValidateImageUseCase`, `RunDiagnosisUseCase`, `CameraPermissionService` |
| `AuthCubit` | `application/auth/auth_cubit.dart` | `AuthInitial`, `AuthLoading`, `AuthSuccess`, `AuthError`, `AuthRateLimited` | User authentication & guest account upgrade | `UpgradeGuestUserUseCase`, `SignInUseCase`, `SignOutUseCase` |
| `DiagnosisCubit` | `application/diagnosis/diagnosis_cubit.dart` | `DiagnosisInitial`, `DiagnosisHealthy`, `DiagnosisTreatmentLoading`, `DiagnosisTreatmentLoaded`, `DiagnosisTreatmentError` | LLM & offline treatment guidance fetching | `ResolveTreatmentUseCase` |
| `EscalationCubit` | `application/escalation/escalation_cubit.dart` | `EscalationInitial`, `EscalationSharing`, `EscalationSharedSuccess`, `EscalationError` | WhatsApp message formatting & photo share | `CreateEscalationUseCase`, `SharePlus` |
| `HistoryCubit` | `application/history/history_cubit.dart` | `HistoryInitial`, `HistoryLoading`, `HistoryLoaded`, `HistoryEmpty`, `HistoryError` | Scan history list and active filter chips | `GetScanHistoryUseCase` |
| `SyncCubit` | `application/sync/sync_cubit.dart` | `SyncInitial`, `SyncInProgress`, `SyncSuccess`, `SyncError` — all now carry `failedOperations` and `needsReauth` | Outbox count, manual & post-auth sync, reference data sync, surfacing + retrying failed ops, releasing an auth hold | `SyncRepository`, `AuthRepository` |
| `SettingsCubit` | `application/settings/settings_cubit.dart` | `SettingsState` | Section expansion state | — |

---

## 7. Data Models

### Domain Entities
- **`AppState`**: `onboardingCompleted`, `languageCode`, `firstLaunchAt`
- **`Crop`**: `id`, `nameEn`, `nameSi`, `nameTa`, `isSupported`, `iconAsset`
- **`LocalUser`**: `id`, `remoteUserId`, `email`, `phoneNumber`, `isGuest`, `sessionToken`, `createdAt`, `updatedAt`
- **`Scan`**: `id`, `remoteScanId`, `userId`, `cropId`, `imageLocalPath`, `imageRemoteUrl`, `status`, `capturedAt`, `createdAt`, `updatedAt`
- **`Diagnosis`**: `id`, `scanId`, `diseaseId`, `modelVersionId`, `confidence`, `resultState`, `severity`, `alternatives`, `treatmentSource`, `treatmentGuidelineId`, `llmInterpretationId`, `inferredAt`
- **`Escalation`**: `id`, `scanId`, `diagnosisId`, `notes`, `sharedVia`, `sharedAt`, `createdAt`
- **`SyncOperation`**: `id`, `entityId`, `entityType`, `operationType`, `payloadJson`, `status`, `retryCount`, `lastError`, `createdAt`, `updatedAt`
- **`TreatmentResponse`**: `summary`, `whatToDo`, `whatToAvoid`, `recheckAfterDays`, `interpretationId`
- **`ScanHistoryItem`**: `scan`, `diagnosis`, `crop`

### SQLite Tables (Drift — `schemaVersion = 7`)
1. **`app_state`**: Singleton app configuration row.
2. **`local_user`**: Guest and authenticated user profiles & tokens.
3. **`crop`**: 15 seeded crop records.
4. **`disease`**: 38 seeded PlantVillage disease classes + paddy.
5. **`treatment_guideline`**: Local offline fallback guidelines.
6. **`model_version`**: Model registry table.
7. **`scan`**: Image path, crop FK, status lifecycle, imageRemoteUrl, remoteScanId.
8. **`image_validation`**: On-device image quality validation results.
9. **`diagnosis`**: Inference results, confidence scores, treatment source, and interpretation IDs.
10. **`escalation`**: Expert escalation & WhatsApp share records (added in v3).
11. **`sync_operation`**: Outbox for offline cloud sync operations (added in v4).
    Gained `uploaded_image_url` in v5 so a retry does not re-upload an image
    that already succeeded. Status vocabulary now includes
    `PERMANENTLY_FAILED` and `AUTH_REQUIRED` (TD-019).
12. **`disease_explanation`**: Offline "what is this / what does the result
    suggest" content, per language (added in v6). **Ships empty** — TD-018.
13. **`disease_confusion`**: Look-alike conditions per disease, with
    distinguishing symptoms (added in v6). **Ships empty** —
    `confused_with_disease_id` is nullable because the most dangerous
    look-alikes are often not diseases at all.

---

## 8. Dependencies and Integrations

| Package | In pubspec.yaml | Current Usage |
|---|---|---|
| `flutter_bloc ^8.1.3` | Yes | AppStateCubit, ScanCubit, AuthCubit, DiagnosisCubit, HistoryCubit, EscalationCubit, SyncCubit, SettingsCubit |
| `drift ^2.9.0` | Yes | All local SQLite persistence (11 tables) |
| `sqlite3_flutter_libs ^0.5.0` | Yes | Native SQLite binaries for Drift |
| `path_provider ^2.1.0` | Yes | DB file location; scan image storage directory |
| `path ^1.8.3` | Yes | File path manipulation |
| `image_picker ^1.0.4` | Yes | Camera capture in CaptureScreen |
| `camera ^0.10.5+9` | Yes | Native camera integration |
| `permission_handler ^11.0.0` | Yes | Camera permission in ScanCubit |
| `tflite_flutter ^0.12.0` | Yes | On-device ML inference for plant disease classification |
| `image ^4.1.7` | Yes | Image decoding, resizing (224x224), pixel normalization for ML tensor input |
| `http ^1.2.0` | Yes | REST communication with FastAPI backend (Auth, Treatment, Sync) |
| `flutter_secure_storage ^9.2.2` | Yes | Encrypted JWT access and refresh token storage |
| `share_plus ^10.1.4` | Yes | WhatsApp escalation card with leaf photo attachment |
| `flutter_tts ^4.2.2` | Yes | Localized Text-to-Speech playback for treatment guidance |
| `connectivity_plus ^6.1.4` | Yes | `ConnectivityService` — debounced online/offline stream for auto-sync on reconnect |
| `workmanager ^0.6.0` | Yes | `WorkManagerHelper` + `callbackDispatcher` — 15-min periodic Dart background isolate outbox flush |
| `camera ^0.10.5+9` | Yes | Live viewfinder in `CaptureScreen` via `CameraService` (was an unused dependency before 2026-08-26) |
| Bundled Noto fonts (assets, not a package) | assets/fonts | Latin/Sinhala/Tamil faces; `google_fonts` deliberately NOT used — TD-013 |
| `drift_dev ^2.9.0` | dev | Code generation |
| `build_runner ^2.4.0` | dev | Code generation |
| `flutter_lints ^6.0.0` | dev | Linting |

---

## 9. AI Implementation Rules

1. Treat the actual source code as the source of truth. The architecture and checklist describe the target; the code describes what exists.
2. Preserve the layered architecture: Presentation -> Application (Cubit) -> Domain (use case) -> Repository (interface) -> Data (impl). Do not skip layers.
3. Do not bypass `main.dart` composition root by creating extra `AppDatabase()` instances inside screens.
4. Prefer modifying existing appropriate files over creating new ones. Check the directory structure before creating anything.
5. Do not refactor unrelated code. Touch only what is needed for the task.
6. Do not introduce patterns not already present. No `get_it`, no `freezed`, no `equatable`, no `go_router` unless explicitly requested.
7. Before implementing any feature, identify the minimum files to create or modify. State them explicitly before writing code.
8. Keep implementations minimal for the MVP. No over-engineering.
9. Do not infer that a component exists because the architecture mentions it. Verify via the file tree and file contents.
10. Do not silently change architectural decisions.
11. New entities must have: a domain entity, a repository interface, a repository impl, and a Drift table registration — in that dependency order.
22. **Do not fabricate agronomic content.** Treatment guidance, disease names and symptom descriptions must come from a citable source, recorded in `ml/CONTENT_SOURCES.md`. Wrong advice for a real disease is worse than an empty section (TD-026).
23. **On-device guidance is written as short single-action sentences.** The app splits prose into steps at sentence boundaries; a paragraph renders as one unreadable step (TD-020, TD-026).
24. **Every diagnosable class needs offline guidance in all three languages.** Enforced by `treatment_guideline_coverage_test.dart`. A diagnosis with nothing to do about it is worse than no diagnosis (TD-026).
25. **`ml/taxonomy.py` is the single source of truth for the model's class list.** The training notebook is generated from it (`python ml/build_notebook.py`) and the Dart class list is generated by it. A hand-edited class list that has drifted from the app's disease ids is a silent mismapping, not an error (TD-025).
26. **Never show a raw model artefact to a user** — a class index, a logit, a bare percentage with no framing. Alternatives are named, not numbered (TD-022).
12. New strings must be added in all three languages in `app_localizations.dart`.
13. After any schema change in `tables.dart`, increment `AppDatabase.schemaVersion` and add a migration in `MigrationStrategy.onUpgrade`.
14. The `sync_operation` table exists in schema version 4 for outbox queueing.
15. When uncertain, read the relevant source file before making a change.
16. **Never use `Colors.*` swatches or raw `Color(0x...)` for anything that
    carries meaning.** Use `AppColors` (TD-012). Alpha-blended colour is for
    decorative backgrounds and scrims only, never behind text.
17. Use `AppSpacing` / `AppRadius` rather than raw numbers, and
    `Theme.of(context).textTheme.*` rather than inline `TextStyle(fontSize:)`.
    Never multiply a font size by the accessibility text scale — the app
    applies it globally via `MediaQuery` in `app.dart`; doing it again squares
    the effect.
18. Build screens out of `lib/presentation/shared/widgets/` rather than
    re-deriving cards, banners, chips and empty/error states per screen.
19. **Never render a raw exception string to the user.** `AppErrorView` has a
    `technicalDetail` slot that is collapsed by default.
20. The ML model cannot detect out-of-distribution input (TD-014). Do not add
    UI that implies more certainty than a closed-set softmax can support, and
    do not remove the pre-inference content gate in `ValidateImageUseCase`.
21. `disease_explanation` / `disease_confusion` are intentionally empty. Do not
    add seed content to satisfy a test — assert the empty path instead.
