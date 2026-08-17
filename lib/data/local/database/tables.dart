// lib/data/local/database/tables.dart
//
// Drift table definitions — one class per SQL table.
// These are the ONLY source of truth for the local schema.
// Do NOT add business logic here; keep it pure schema.

import 'package:drift/drift.dart';

// ============================================================
// APP STATE — singleton row (id always = 1)
// ============================================================
class AppStateTable extends Table {
  @override
  String get tableName => 'app_state';

  /// Singleton enforced at the app layer (INSERT with id=1 only).
  /// A CHECK constraint cannot be expressed via Drift's column DSL without
  /// recursive getter issues; enforcement is handled by the repository.
  IntColumn get id => integer()();

  IntColumn get onboardingCompleted =>
      integer().withDefault(const Constant(0))();

  /// 'en' | 'si' | 'ta'
  TextColumn get languageCode =>
      text().withDefault(const Constant('en'))();

  /// ISO8601 — nullable
  TextColumn get firstLaunchAt => text().nullable()();

  TextColumn get lastSyncAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// LOCAL USER
// ============================================================
class LocalUserTable extends Table {
  @override
  String get tableName => 'local_user';

  /// Local UUID; becomes server user id after auth.
  TextColumn get id => text()();

  TextColumn get remoteUserId => text().nullable()();
  TextColumn get phoneNumber => text().nullable()();

  IntColumn get isGuest => integer().withDefault(const Constant(1))();

  TextColumn get sessionToken => text().nullable()();
  TextColumn get sessionRefreshToken => text().nullable()();
  TextColumn get sessionExpiresAt => text().nullable()();

  /// ISO8601 — NOT NULL
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// CROP — reference data
// ============================================================
class CropTable extends Table {
  @override
  String get tableName => 'crop';

  /// e.g. 'tomato'
  TextColumn get id => text()();

  TextColumn get nameEn => text()();
  TextColumn get nameSi => text().nullable()();
  TextColumn get nameTa => text().nullable()();

  IntColumn get isSupported =>
      integer().withDefault(const Constant(1))();

  TextColumn get iconAsset => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// DISEASE — reference data
// ============================================================
class DiseaseTable extends Table {
  @override
  String get tableName => 'disease';

  /// e.g. 'tomato_late_blight'
  TextColumn get id => text()();

  TextColumn get cropId =>
      text().references(CropTable, #id)();

  TextColumn get nameEn => text()();
  TextColumn get nameSi => text().nullable()();
  TextColumn get nameTa => text().nullable()();

  /// 'low' | 'moderate' | 'high' — nullable
  TextColumn get severityDefault => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// TREATMENT GUIDELINE — offline fallback only
// ============================================================
class TreatmentGuidelineTable extends Table {
  @override
  String get tableName => 'treatment_guideline';

  TextColumn get id => text()();

  TextColumn get diseaseId =>
      text().references(DiseaseTable, #id)();

  /// e.g. 'tg-2026.03'
  TextColumn get guidelineVersion => text()();

  TextColumn get summaryEn => text().nullable()();
  TextColumn get summarySi => text().nullable()();
  TextColumn get summaryTa => text().nullable()();

  TextColumn get whatToDoEn => text().nullable()();
  TextColumn get whatToDoSi => text().nullable()();
  TextColumn get whatToDoTa => text().nullable()();

  TextColumn get whatToAvoidEn => text().nullable()();
  TextColumn get whatToAvoidSi => text().nullable()();
  TextColumn get whatToAvoidTa => text().nullable()();

  IntColumn get recheckAfterDays => integer().nullable()();
  TextColumn get publishedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// MODEL VERSION — ML model registry
// ============================================================
class ModelVersionTable extends Table {
  @override
  String get tableName => 'model_version';

  /// e.g. 'cropcare-v1.0'
  TextColumn get id => text()();

  TextColumn get releasedAt => text().nullable()();

  IntColumn get isActive =>
      integer().withDefault(const Constant(1))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// SCAN — core entity; created locally, synced later
// ============================================================
class ScanTable extends Table {
  @override
  String get tableName => 'scan';

  /// Local UUID; becomes scan_id on server.
  TextColumn get id => text()();

  TextColumn get remoteScanId => text().nullable()();

  TextColumn get userId =>
      text().references(LocalUserTable, #id)();

  TextColumn get cropId =>
      text().references(CropTable, #id)();

  TextColumn get imageLocalPath => text()();

  /// Populated after image sync.
  TextColumn get imageRemoteUrl => text().nullable()();

  /// Lifecycle state — app-layer enforcement only (see schema spec).
  /// 'CREATED'|'VALIDATING'|'ANALYZING'|'DIAGNOSED'|'COMPLETED'|
  /// 'ESCALATED'|'SHARED'|'RESOLVED'|'USER_CANCELLED'|
  /// 'INVALID_IMAGE'|'ANALYSIS_FAILED'
  TextColumn get status => text()();

  TextColumn get capturedAt => text()();
  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// IMAGE VALIDATION — one per scan
// ============================================================
class ImageValidationTable extends Table {
  @override
  String get tableName => 'image_validation';

  TextColumn get id => text()();

  TextColumn get scanId =>
      text().references(ScanTable, #id)();

  IntColumn get isUsable => integer()();

  /// 'BLURRY'|'TOO_DARK'|'TOO_BRIGHT'|'LOW_RESOLUTION'|
  /// 'NO_PLANT_DETECTED'|'UNSUPPORTED_FORMAT' — nullable
  TextColumn get rejectionReason => text().nullable()();

  TextColumn get checkedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// DIAGNOSIS — AI inference result; one per scan
// ============================================================
class DiagnosisTable extends Table {
  @override
  String get tableName => 'diagnosis';

  TextColumn get id => text()();

  TextColumn get scanId =>
      text().references(ScanTable, #id)();

  /// NULL if result_state = 'UNSUPPORTED'
  TextColumn get diseaseId =>
      text().nullable().references(DiseaseTable, #id)();

  TextColumn get modelVersionId =>
      text().references(ModelVersionTable, #id)();

  /// 0.0–1.0
  RealColumn get confidence => real()();

  /// 'CONFIDENT'|'LOW_CONFIDENCE'|'UNSUPPORTED'|'ANALYSIS_FAILED'
  TextColumn get resultState => text()();

  /// 'low'|'moderate'|'high' — nullable
  TextColumn get severity => text().nullable()();

  /// JSON array of {disease_id, confidence}
  TextColumn get alternativesJson => text().nullable()();

  /// 'LLM' | 'LOCAL_FALLBACK'
  TextColumn get treatmentSource => text()();

  /// Set only when treatment_source = 'LOCAL_FALLBACK'
  TextColumn get treatmentGuidelineId =>
      text().nullable().references(TreatmentGuidelineTable, #id)();

  /// Set only when treatment_source = 'LLM'.
  /// FK to llm_interpretation is intentionally omitted per schema spec
  /// (llm_interpretation table is not part of this scope).
  TextColumn get llmInterpretationId => text().nullable()();

  TextColumn get inferredAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
