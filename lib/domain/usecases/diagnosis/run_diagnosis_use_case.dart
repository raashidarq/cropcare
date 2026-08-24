// lib/domain/usecases/diagnosis/run_diagnosis_use_case.dart
//
// Orchestrates: validate → infer → persist.
// Called by ScanCubit after a scan row has been created.
//
// Dependency on MlInferenceService is via the data layer import — this is
// intentional for MVP. If a domain-layer interface is needed later, extract
// an abstract InferenceService and inject it here.

import 'dart:math';

import 'package:drift/drift.dart';

import '../../../data/local/database/app_database.dart';
import '../../../data/local/ml/ml_inference_service.dart';
import '../../entities/diagnosis.dart';
import '../../repositories/diagnosis_repository.dart';
import 'validate_image_use_case.dart';

class RunDiagnosisUseCase {
  final MlInferenceService inferenceService;
  final DiagnosisRepository diagnosisRepository;
  final AppDatabase db; // needed to write image_validation row

  static const String _modelVersionId = 'cropcare-v1.0';

  static String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    return [
      values.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    ].join('-');
  }

  RunDiagnosisUseCase({
    required this.inferenceService,
    required this.diagnosisRepository,
    required this.db,
  });

  /// Runs ML inference on the image at [imageLocalPath] for [scanId].
  ///
  /// Always returns a [Diagnosis]:
  ///   - resultState.confident       → high-confidence prediction
  ///   - resultState.lowConfidence   → prediction below threshold
  ///   - resultState.unsupported     → crop not in our system
  ///   - resultState.analysisFailed  → exception during inference
  ///
  /// Also writes the [image_validation] row for this scan.
  Future<Diagnosis> call({
    required String scanId,
    required String imageLocalPath,
    required ImageValidationResult validationResult,
  }) async {
    // ── 1. Persist image_validation row ────────────────────────────────────
    await _writeImageValidation(
      scanId: scanId,
      validationResult: validationResult,
    );

    // ── 2. Short-circuit if image is unusable ──────────────────────────────
    if (!validationResult.isUsable) {
      final failedDiagnosis = Diagnosis(
        id: _generateUuid(),
        scanId: scanId,
        modelVersionId: _modelVersionId,
        confidence: 0.0,
        resultState: DiagnosisResultState.analysisFailed,
        treatmentSource: TreatmentSource.localFallback,
        inferredAt: DateTime.now().toIso8601String(),
      );
      return diagnosisRepository.createDiagnosis(failedDiagnosis);
    }

    // ── 3. Run ML inference ────────────────────────────────────────────────
    try {
      final result = await inferenceService.runInference(imageLocalPath);

      // Determine result state
      final DiagnosisResultState state;
      if (!result.isSupported) {
        state = DiagnosisResultState.unsupported;
      } else if (result.confidence >= MlInferenceService.confidenceThreshold) {
        state = DiagnosisResultState.confident;
      } else {
        state = DiagnosisResultState.lowConfidence;
      }

      // Build top-N alternatives (skip the top itself, only supported diseases)
      final alternatives = result.topFive
          .skip(1)
          .where((pair) => MlInferenceService.classNameAt(pair.$1).isNotEmpty)
          .map((pair) => AlternativePrediction(
                diseaseId: pair.$1.toString(), // stored as class index string for now
                confidence: pair.$2,
              ))
          .take(3)
          .toList();

      final diagnosis = Diagnosis(
        id: _generateUuid(),
        scanId: scanId,
        diseaseId: result.diseaseId,
        modelVersionId: _modelVersionId,
        confidence: result.confidence,
        resultState: state,
        alternatives: alternatives,
        treatmentSource: TreatmentSource.localFallback,
        inferredAt: DateTime.now().toIso8601String(),
      );

      return await diagnosisRepository.createDiagnosis(diagnosis);
    } catch (e) {
      // Inference threw — record as analysis_failed
      final failedDiagnosis = Diagnosis(
        id: _generateUuid(),
        scanId: scanId,
        modelVersionId: _modelVersionId,
        confidence: 0.0,
        resultState: DiagnosisResultState.analysisFailed,
        treatmentSource: TreatmentSource.localFallback,
        inferredAt: DateTime.now().toIso8601String(),
      );
      return diagnosisRepository.createDiagnosis(failedDiagnosis);
    }
  }

  // ---------------------------------------------------------------------------

  Future<void> _writeImageValidation({
    required String scanId,
    required ImageValidationResult validationResult,
  }) async {
    final companion = ImageValidationTableCompanion.insert(
      id: _generateUuid(),
      scanId: scanId,
      isUsable: validationResult.isUsable ? 1 : 0,
      rejectionReason: validationResult.rejectionReason != null
          ? Value(ValidateImageUseCase.rejectionReasonToString(
              validationResult.rejectionReason!))
          : const Value(null),
      checkedAt: DateTime.now().toIso8601String(),
    );
    await db.into(db.imageValidationTable).insertOnConflictUpdate(companion);
  }
}
