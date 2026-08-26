// lib/data/repositories/diagnosis_repository_impl.dart
//
// Concrete implementation of DiagnosisRepository.
// Persists diagnosis results to the 'diagnosis' SQLite table (Drift).
// Also provides getDiagnosisByScanId for reading back a saved diagnosis.

import 'dart:convert';

import 'package:drift/drift.dart';

import '../../domain/entities/diagnosis.dart';
import '../../domain/repositories/diagnosis_repository.dart';
import '../local/database/app_database.dart';
import '../local/ml/ml_inference_service.dart';

class DiagnosisRepositoryImpl implements DiagnosisRepository {
  final AppDatabase db;

  DiagnosisRepositoryImpl(this.db);

  @override
  Future<Diagnosis> createDiagnosis(Diagnosis diagnosis) async {
    final companion = DiagnosisTableCompanion.insert(
      id: diagnosis.id,
      scanId: diagnosis.scanId,
      diseaseId: Value(diagnosis.diseaseId),
      modelVersionId: diagnosis.modelVersionId,
      confidence: diagnosis.confidence,
      resultState: _resultStateToString(diagnosis.resultState),
      severity: Value(diagnosis.severity),
      alternativesJson: Value(
        diagnosis.alternatives.isNotEmpty
            ? jsonEncode(diagnosis.alternatives
                .map((a) => {'disease_id': a.diseaseId, 'confidence': a.confidence})
                .toList())
            : null,
      ),
      treatmentSource: _treatmentSourceToString(diagnosis.treatmentSource),
      treatmentGuidelineId: Value(diagnosis.treatmentGuidelineId),
      inferredAt: diagnosis.inferredAt,
    );

    await db.into(db.diagnosisTable).insertOnConflictUpdate(companion);

    // Enqueue outbox sync operation
    final syncOpId = 'sync_diag_${diagnosis.id}';
    final payloadJson = jsonEncode({
      'local_diagnosis_id': diagnosis.id,
      'local_scan_id': diagnosis.scanId,
      'disease_id': diagnosis.diseaseId,
      'confidence': diagnosis.confidence,
      'result_state': _resultStateToString(diagnosis.resultState),
      'severity': diagnosis.severity,
      'model_version_id': diagnosis.modelVersionId,
      'treatment_source': _treatmentSourceToString(diagnosis.treatmentSource),
      'llm_interpretation_id': diagnosis.llmInterpretationId,
      'inferred_at': diagnosis.inferredAt,
    });

    final nowIso = DateTime.now().toIso8601String();
    await db.into(db.syncOperationTable).insertOnConflictUpdate(
          SyncOperationTableCompanion.insert(
            id: syncOpId,
            entityId: diagnosis.id,
            entityType: 'DIAGNOSIS',
            operationType: const Value('CREATE'),
            payloadJson: payloadJson,
            status: const Value('PENDING'),
            retryCount: const Value(0),
            createdAt: nowIso,
            updatedAt: nowIso,
          ),
        );

    return diagnosis;
  }

  @override
  Future<Diagnosis?> getDiagnosisByScanId(String scanId) async {
    final row = await (db.select(db.diagnosisTable)
          ..where((t) => t.scanId.equals(scanId)))
        .getSingleOrNull();

    if (row == null) return null;
    return _mapToEntity(row);
  }

  @override
  Future<void> updateTreatmentSource(
    String diagnosisId, {
    required TreatmentSource source,
    String? guidelineId,
    String? llmInterpretationId,
  }) async {
    await (db.update(db.diagnosisTable)..where((t) => t.id.equals(diagnosisId)))
        .write(DiagnosisTableCompanion(
      treatmentSource: Value(_treatmentSourceToString(source)),
      treatmentGuidelineId: Value(guidelineId),
      llmInterpretationId: Value(llmInterpretationId),
    ));

    final row = await (db.select(db.diagnosisTable)
          ..where((t) => t.id.equals(diagnosisId)))
        .getSingleOrNull();
    if (row != null) {
      final syncOpId = 'sync_diag_$diagnosisId';
      final payloadJson = jsonEncode({
        'local_diagnosis_id': row.id,
        'local_scan_id': row.scanId,
        'disease_id': row.diseaseId,
        'confidence': row.confidence,
        'result_state': row.resultState,
        'severity': row.severity,
        'model_version_id': row.modelVersionId,
        'treatment_source': row.treatmentSource,
        'llm_interpretation_id': row.llmInterpretationId,
        'inferred_at': row.inferredAt,
      });

      final nowIso = DateTime.now().toIso8601String();
      await db.into(db.syncOperationTable).insertOnConflictUpdate(
            SyncOperationTableCompanion.insert(
              id: syncOpId,
              entityId: diagnosisId,
              entityType: 'DIAGNOSIS',
              operationType: const Value('UPDATE'),
              payloadJson: payloadJson,
              status: const Value('PENDING'),
              retryCount: const Value(0),
              createdAt: nowIso,
              updatedAt: nowIso,
            ),
          );
    }
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------------

  /// Repairs alternatives stored before `RunDiagnosisUseCase` was fixed.
  ///
  /// Those rows hold the model's raw class index as a string ("12"), not a
  /// disease id, so they rendered to the farmer as a bare number under "Not
  /// what you see?". Mapping happens on read rather than as a migration
  /// because the fix is cheap, total, and needs no schema change — and a
  /// migration would still have to handle rows synced down from elsewhere.
  ///
  /// Returns an empty string for anything unresolvable, which the caller
  /// filters out.
  static String _resolveAlternativeId(String stored) {
    final index = int.tryParse(stored);
    if (index == null) return stored; // already a real disease id
    return MlInferenceService.diseaseIdAt(index) ?? '';
  }

  Diagnosis _mapToEntity(DiagnosisTableData row) {
    List<AlternativePrediction> alternatives = [];
    if (row.alternativesJson != null) {
      final decoded = jsonDecode(row.alternativesJson!) as List<dynamic>;
      alternatives = decoded
          .map((e) => AlternativePrediction(
                diseaseId: _resolveAlternativeId(e['disease_id'] as String),
                confidence: (e['confidence'] as num).toDouble(),
              ))
          // Rows written before the id fix can hold a class index this app
          // has no disease for. Drop those rather than render a number.
          .where((a) => a.diseaseId.isNotEmpty)
          .toList();
    }

    return Diagnosis(
      id: row.id,
      scanId: row.scanId,
      diseaseId: row.diseaseId,
      modelVersionId: row.modelVersionId,
      confidence: row.confidence,
      resultState: _resultStateFromString(row.resultState),
      severity: row.severity,
      alternatives: alternatives,
      treatmentSource: _treatmentSourceFromString(row.treatmentSource),
      treatmentGuidelineId: row.treatmentGuidelineId,
      llmInterpretationId: row.llmInterpretationId,
      inferredAt: row.inferredAt,
    );
  }

  String _resultStateToString(DiagnosisResultState state) {
    switch (state) {
      case DiagnosisResultState.confident:
        return 'CONFIDENT';
      case DiagnosisResultState.lowConfidence:
        return 'LOW_CONFIDENCE';
      case DiagnosisResultState.unsupported:
        return 'UNSUPPORTED';
      case DiagnosisResultState.analysisFailed:
        return 'ANALYSIS_FAILED';
    }
  }

  DiagnosisResultState _resultStateFromString(String value) {
    switch (value) {
      case 'CONFIDENT':
        return DiagnosisResultState.confident;
      case 'LOW_CONFIDENCE':
        return DiagnosisResultState.lowConfidence;
      case 'UNSUPPORTED':
        return DiagnosisResultState.unsupported;
      default:
        return DiagnosisResultState.analysisFailed;
    }
  }

  String _treatmentSourceToString(TreatmentSource source) {
    switch (source) {
      case TreatmentSource.localFallback:
        return 'LOCAL_FALLBACK';
      case TreatmentSource.llm:
        return 'LLM';
    }
  }

  TreatmentSource _treatmentSourceFromString(String value) {
    return value == 'LLM' ? TreatmentSource.llm : TreatmentSource.localFallback;
  }
}
