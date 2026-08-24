# CropCare MVP

CropCare is a mobile agricultural pest & disease detection tool primarily for farmers. It should allow farmers to take photos of their crops, have an ML model perform diagnosis, and then have AI give the next best steps to rectify with experts a tap away.

## Core Features (MVP)

- Simple user flow: Onboarding → Home (Camera) → Diagnosis → Solution → AI Helper -> Share with Agriculture Officer via WhatsApp.
- Authentication and profile management
- Disease detection using ML model
- AI-powered treatment advisory based on the ML diagnosis, Farmer observations, and crop type.

## Tech Stack

- Flutter (Developed using Clean Architecture, Mocking, Widget Tests, and GitHub Actions CI/CD)
  - Language localization system (English/Sinhala/Tamil)
  - On-device ML model (TensorFlow Lite)
  - SQLite local database
  - Offline-first focus with sync operations for when connected online.

- FastAPI (Backend on separate repo) (Developed with GitHub Actions CI/CD, Pytest, Ruff tests)
  - Supabase (Authentication, Database, and Object Storage)
  - Gemini API for AI-powered advisory

## Continuous Integration

**GitHub Actions** - Flutter Analyze & Test
