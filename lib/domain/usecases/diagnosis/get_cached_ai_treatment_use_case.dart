// lib/domain/usecases/diagnosis/get_cached_ai_treatment_use_case.dart
//
// Reads back an AI-written treatment response already fetched for this
// diagnosis, if there is one.
//
// Separate from GetLocalTreatmentGuidanceUseCase on purpose, the same way
// that one is separate from ResolveTreatmentUseCase: this reads a local row
// and writes nothing. What makes it different from the local-guideline read
// is WHAT it reads — this is the better, AI-written answer a farmer already
// paid one real request for, not the guideline that ships with the app.
// Checking this first is what stops re-opening a diagnosis from silently
// re-asking the LLM for something already answered.

import '../../entities/treatment.dart';
import '../../repositories/diagnosis_repository.dart';

class GetCachedAiTreatmentUseCase {
  final DiagnosisRepository diagnosisRepository;

  GetCachedAiTreatmentUseCase({required this.diagnosisRepository});

  /// Returns the cached AI-written treatment for [diagnosisId], or null if
  /// none has been fetched (or cached) yet.
  Future<TreatmentResponse?> call({required String diagnosisId}) {
    return diagnosisRepository.getCachedAiTreatment(diagnosisId);
  }
}
