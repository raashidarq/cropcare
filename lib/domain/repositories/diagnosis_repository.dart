// lib/domain/repositories/diagnosis_repository.dart
//
// Abstract interface — no Drift/Flutter imports.

import '../entities/diagnosis.dart';
import '../entities/treatment.dart';

abstract class DiagnosisRepository {
  /// Persists a new diagnosis row and returns the saved entity.
  Future<Diagnosis> createDiagnosis(Diagnosis diagnosis);

  /// Returns the diagnosis for [scanId], or null if not yet diagnosed.
  Future<Diagnosis?> getDiagnosisByScanId(String scanId);

  /// Updates the treatment source and related identifiers for a diagnosis.
  Future<void> updateTreatmentSource(
    String diagnosisId, {
    required TreatmentSource source,
    String? guidelineId,
    String? llmInterpretationId,
  });

  /// Caches the AI-written treatment response on-device against this
  /// diagnosis, so a later read never has to ask the LLM again for the
  /// same diagnosis.
  Future<void> cacheAiTreatment(String diagnosisId, TreatmentResponse treatment);

  /// Returns the cached AI-written treatment for [diagnosisId], or null if
  /// nothing has been cached yet (never fetched, or fetch never succeeded).
  Future<TreatmentResponse?> getCachedAiTreatment(String diagnosisId);
}
