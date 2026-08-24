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
  }

  // ---------------------------------------------------------------------------
  // Mapping helpers
  // ---------------------------------------------------------------------------

  Diagnosis _mapToEntity(DiagnosisTableData row) {
    List<AlternativePrediction> alternatives = [];
    if (row.alternativesJson != null) {
      final decoded = jsonDecode(row.alternativesJson!) as List<dynamic>;
      alternatives = decoded
          .map((e) => AlternativePrediction(
                diseaseId: e['disease_id'] as String,
                confidence: (e['confidence'] as num).toDouble(),
              ))
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
