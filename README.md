# CropCare MVP

CropCare is a mobile agricultural pest & disease detection tool primarily for farmers. It should allow farmers to take photos of their crops, have an ML model perform diagnosis, and then have AI give the next best steps to rectify with experts a tap away.

## Core Features (MVP)

- Simple user flow: Onboarding → Home (Camera) → Diagnosis → Solution → AI Helper
- Authentication and profile management
- Disease detection using ML model
- AI-powered advisory with prompt-based interaction

## Tech Stack

- Flutter
- FastAPI (Backend)
  - Supabase (Authentication, Database, and Object Storage)
  - ML model
    ...

## Continuous Integration

**GitHub Actions** - Flutter Analyze & Test

## Folder Structure

cropcare/
├── android/
├── ios/
├── assets/
│ ├── models/ # .tflite model file(s) from Day 0
│ ├── i18n/ # en.json, si.json, ta.json
│ └── icons/
│
├── lib/
│ ├── main.dart
│ ├── app.dart # MaterialApp, routing, DI wiring
│ │
│ ├── core/
│ │ ├── constants/
│ │ ├── theme/
│ │ ├── localization/
│ │ ├── errors/ # shared Failure/Exception types
│ │ └── utils/ # uuid generator, connectivity checker, date helpers
│ │
│ ├── presentation/ # UI only — screens + widgets, one folder per feature
│ │ ├── onboarding/
│ │ ├── auth/
│ │ ├── scan/ # crop_select, capture, gallery
│ │ ├── diagnosis/ # result screen, treatment display, TTS button
│ │ ├── escalation/
│ │ ├── history/
│ │ └── settings/
│ │
│ ├── application/ # Cubits/BLoCs — mirrors presentation, 1:1 with each feature
│ │ ├── onboarding/
│ │ ├── auth/
│ │ ├── scan/
│ │ ├── diagnosis/
│ │ ├── escalation/
│ │ ├── history/
│ │ ├── settings/
│ │ └── sync/ # SyncStatusCubit
│ │
│ ├── domain/ # framework-free — no Flutter, no SQLite, no Supabase imports
│ │ ├── entities/ # Scan, Diagnosis, Crop, Disease, Escalation, TreatmentGuidance
│ │ ├── repositories/ # abstract contracts only (interfaces)
│ │ └── usecases/
│ │ ├── scan/ # capture_scan, validate_image
│ │ ├── diagnosis/ # run_diagnosis, resolve_treatment_guidance
│ │ ├── escalation/ # escalate_to_expert
│ │ └── sync/ # sync_pending_operations
│ │
│ ├── data/
│ │ ├── local/
│ │ │ ├── database/ # Drift tables + database class
│ │ │ ├── datasources/ # local_scan_datasource, local_diagnosis_datasource
│ │ │ └── ml/ # tflite wrapper, preprocessing, image quality checks
│ │ ├── remote/
│ │ │ ├── supabase/ # client provider, auth wrapper
│ │ │ ├── datasources/ # remote_scan_datasource, gemini_datasource
│ │ │ └── dto/ # JSON ↔ entity mapping
│ │ ├── repositories/ # concrete implementations of domain/repositories contracts
│ │ └── sync/ # SyncEngine, outbox processor
│ │
│ └── platform/ # thin wrappers: camera, gallery, permissions, tts, notifications, connectivity
│
├── test/ # mirrors lib/ 1:1
│ ├── domain/usecases/
│ ├── data/repositories/
│ ├── application/ # cubit tests
│ └── presentation/ # widget tests
│
├── supabase/
│ ├── migrations/ # versioned SQL — the remote DDL, tracked in git
│ └── functions/
│ └── interpret-diagnosis/ # Gemini edge function
│
├── .github/
│ └── workflows/
│ └── ci.yml # flutter analyze + flutter test on push
│
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
