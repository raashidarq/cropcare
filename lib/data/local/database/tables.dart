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

  /// ISO8601 timestamp of the sync run currently holding the advisory lock,
  /// or null when no run is active.
  ///
  /// Sync can be triggered from the UI, the connectivity listener, the
  /// post-auth hook, AND a WorkManager background isolate. The isolate has
  /// its own memory, so an in-process flag cannot exclude it — the lock has
  /// to live somewhere both can see, i.e. the database. Treated as stale
  /// after a timeout so a crashed run cannot deadlock sync forever.
  TextColumn get syncLockedAt => text().nullable()();

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
  TextColumn get email => text().nullable()();
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

// ============================================================
// ESCALATION — expert escalation & WhatsApp share record
// ============================================================
class EscalationTable extends Table {
  @override
  String get tableName => 'escalation';

  TextColumn get id => text()();

  TextColumn get scanId =>
      text().references(ScanTable, #id)();

  TextColumn get diagnosisId =>
      text().references(DiagnosisTable, #id)();

  TextColumn get notes => text().nullable()();

  TextColumn get sharedVia =>
      text().withDefault(const Constant('WHATSAPP'))();

  TextColumn get sharedAt => text().nullable()();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// SYNC OPERATION — Outbox for background/offline cloud sync
// ============================================================
class SyncOperationTable extends Table {
  @override
  String get tableName => 'sync_operation';

  TextColumn get id => text()();

  /// The local id of the scan, diagnosis, or escalation
  TextColumn get entityId => text()();

  /// 'SCAN' | 'DIAGNOSIS' | 'ESCALATION'
  TextColumn get entityType => text()();

  /// 'CREATE' | 'UPDATE'
  TextColumn get operationType =>
      text().withDefault(const Constant('CREATE'))();

  /// JSON payload representation for idempotent upsert
  TextColumn get payloadJson => text()();

  /// 'PENDING' | 'IN_PROGRESS' | 'COMPLETED' | 'FAILED' |
  /// 'PERMANENTLY_FAILED' | 'AUTH_REQUIRED'
  ///
  /// PERMANENTLY_FAILED: retrying will not help (the server rejected the
  /// payload, or the transient-retry budget is exhausted). Surfaced to the
  /// user rather than silently dropped.
  /// AUTH_REQUIRED: the session expired mid-sync. Held, not retried, until
  /// the user signs in again — retrying with a dead token just burns the
  /// retry budget and loses the backlog silently.
  TextColumn get status =>
      text().withDefault(const Constant('PENDING'))();

  IntColumn get retryCount =>
      integer().withDefault(const Constant(0))();

  /// Remote URL of an image that has ALREADY been uploaded for this
  /// operation. Set immediately after a successful upload, before the
  /// metadata POST is attempted.
  ///
  /// Image upload happens before the metadata POST, so without this a
  /// failure of the POST would make the retry re-upload the same bytes from
  /// scratch — expensive on a metered rural connection, and it orphans a
  /// blob in remote storage every attempt.
  TextColumn get uploadedImageUrl => text().nullable()();

  TextColumn get lastError => text().nullable()();

  TextColumn get createdAt => text()();
  TextColumn get updatedAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}


// ============================================================
// DISEASE EXPLANATION — offline "what am I looking at" content
// ============================================================
//
// Distinct from treatment_guideline: that answers "what do I DO about it",
// this answers "what IS this, and how sure should I be". Kept in its own
// table because it is authored, reviewed and shipped on a different cadence
// from treatment advice, and because a farmer may want the explanation for a
// result they never ask for treatment on.
//
// Follows the per-language-column convention used by crop, disease and
// treatment_guideline rather than a row-per-language, so a single lookup
// returns every language and the repository picks the column.
//
// Content is authored elsewhere; nothing seeds this table in code.
class DiseaseExplanationTable extends Table {
  @override
  String get tableName => 'disease_explanation';

  TextColumn get id => text()();

  TextColumn get diseaseId =>
      text().references(DiseaseTable, #id)();

  /// What the plant itself is — crop, habit, what a healthy one looks like.
  TextColumn get plantDescriptionEn => text().nullable()();
  TextColumn get plantDescriptionSi => text().nullable()();
  TextColumn get plantDescriptionTa => text().nullable()();

  /// What the scan result suggests, in plain language, including how much
  /// weight to put on it.
  TextColumn get resultMeaningEn => text().nullable()();
  TextColumn get resultMeaningSi => text().nullable()();
  TextColumn get resultMeaningTa => text().nullable()();

  /// Content revision, e.g. 'ex-2026.03' — mirrors guideline_version.
  TextColumn get explanationVersion => text().nullable()();

  TextColumn get updatedAt => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// DISEASE CONFUSION — "this is easily mistaken for ..."
// ============================================================
//
// One row per look-alike condition for a given disease. A separate table
// rather than a JSON blob on disease_explanation because these are queried
// as a list, ordered, and each look-alike carries its own trilingual text.
//
// [confusedWithDiseaseId] points at another row in `disease` when the
// look-alike is something the model itself can predict. It is nullable
// because the most dangerous look-alikes often are NOT diseases at all —
// nutrient deficiency, water stress, spray burn — and those have no disease
// row to point at; those use [confusedWithLabel*] instead.
class DiseaseConfusionTable extends Table {
  @override
  String get tableName => 'disease_confusion';

  TextColumn get id => text()();

  /// The diagnosed disease this look-alike is listed under.
  // Two columns reference `disease`, so both need explicit reference names
  // or Drift cannot generate distinct manager filters for them.
  @ReferenceName('confusionsForDisease')
  TextColumn get diseaseId =>
      text().references(DiseaseTable, #id)();

  /// The look-alike, when it is itself a known disease.
  @ReferenceName('confusionsNamingDisease')
  TextColumn get confusedWithDiseaseId =>
      text().nullable().references(DiseaseTable, #id)();

  /// The look-alike's name, when it is not a row in `disease`.
  TextColumn get confusedWithLabelEn => text().nullable()();
  TextColumn get confusedWithLabelSi => text().nullable()();
  TextColumn get confusedWithLabelTa => text().nullable()();

  /// How to tell the two apart in the field.
  TextColumn get distinguishingSymptomsEn => text().nullable()();
  TextColumn get distinguishingSymptomsSi => text().nullable()();
  TextColumn get distinguishingSymptomsTa => text().nullable()();

  /// Display order; lower first.
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}

// ============================================================
// CHAT MESSAGE — follow-up questions about one diagnosis
// ============================================================
//
// The local transcript is the authoritative one. The backend keeps no session:
// the app is offline-first, so a conversation has to survive a dropped
// connection, an app restart, and a device that has been in a field with no
// signal for a week. Every read is by diagnosis.
class ChatMessageTable extends Table {
  @override
  String get tableName => 'chat_message';

  TextColumn get id => text()();

  TextColumn get diagnosisId =>
      text().references(DiagnosisTable, #id)();

  /// 'USER' | 'ASSISTANT'
  TextColumn get role => text()();

  TextColumn get content => text()();

  /// The language the exchange happened in. Kept per message because a farmer
  /// can change language mid-conversation, and a Sinhala answer rendered under
  /// a Tamil heading is worse than one that says which language it is in.
  TextColumn get languageCode => text()();

  /// 'PENDING' | 'SENT' | 'FAILED'
  ///
  /// Only ever non-SENT on a USER message: a question typed with no signal is
  /// kept and marked, so it is visibly still there rather than silently lost.
  TextColumn get status => text().withDefault(const Constant('SENT'))();

  TextColumn get createdAt => text()();

  @override
  Set<Column> get primaryKey => {id};
}
