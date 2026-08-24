// lib/domain/repositories/diagnosis_repository.dart
//
// Abstract interface — no Drift/Flutter imports.

import '../entities/diagnosis.dart';

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
}
