// lib/domain/usecases/diagnosis/resolve_treatment_use_case.dart
//
// Resolves treatment guidance for a given diagnosis from the LLM endpoint
// and updates the local SQLite diagnosis record accordingly.

import '../../entities/diagnosis.dart';
import '../../entities/treatment.dart';
import '../../repositories/diagnosis_repository.dart';
import '../../repositories/treatment_repository.dart';

class ResolveTreatmentUseCase {
  final TreatmentRepository treatmentRepository;
  final DiagnosisRepository diagnosisRepository;

  ResolveTreatmentUseCase({
    required this.treatmentRepository,
    required this.diagnosisRepository,
  });

  Future<TreatmentResponse> call({
    required String diagnosisId,
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  }) async {
    final response = await treatmentRepository.getTreatmentGuidance(
      cropId: cropId,
      diseaseId: diseaseId,
      confidence: confidence,
      severity: severity,
      languageCode: languageCode,
      userObservations: userObservations,
      authToken: authToken,
    );

    // Record whether treatment guidance came from LLM or local fallback
    final source = response.interpretationId != null
        ? TreatmentSource.llm
        : TreatmentSource.localFallback;
    await diagnosisRepository.updateTreatmentSource(
      diagnosisId,
      source: source,
      llmInterpretationId: response.interpretationId,
    );

    // Cache the AI-written answer on-device so re-opening this diagnosis
    // reads it back instead of re-asking the LLM. Only when it's genuinely
    // the LLM's own answer — caching the on-device fallback here would be
    // pointless (GetLocalTreatmentGuidanceUseCase already reads it directly
    // from the guideline table for free) and would mislabel a local answer
    // as the "already fetched" AI one on the next open.
    if (source == TreatmentSource.llm) {
      await diagnosisRepository.cacheAiTreatment(diagnosisId, response);
    }

    return response;
  }
}
