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

    // Record that this diagnosis has resolved LLM treatment guidance
    await diagnosisRepository.updateTreatmentSource(
      diagnosisId,
      source: TreatmentSource.llm,
      llmInterpretationId: response.interpretationId,
    );

    return response;
  }
}
