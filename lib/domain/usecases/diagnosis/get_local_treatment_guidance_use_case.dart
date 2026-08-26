// lib/domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart
//
// Reads the guidance that ships with the app for a diagnosed disease.
//
// Separate from ResolveTreatmentUseCase on purpose. That one calls the LLM
// endpoint and records a TreatmentSource against the diagnosis, because it
// represents a deliberate request the farmer made. This one just reads a local
// row to put something useful on screen immediately, so it writes nothing.

import '../../entities/treatment.dart';
import '../../repositories/treatment_repository.dart';

class GetLocalTreatmentGuidanceUseCase {
  final TreatmentRepository treatmentRepository;

  GetLocalTreatmentGuidanceUseCase({required this.treatmentRepository});

  /// Returns the on-device guidance for [diseaseId], or null when the app
  /// ships none for it.
  Future<TreatmentResponse?> call({
    required String diseaseId,
    required String languageCode,
  }) {
    return treatmentRepository.getLocalTreatmentGuidance(
      diseaseId: diseaseId,
      languageCode: languageCode,
    );
  }
}
