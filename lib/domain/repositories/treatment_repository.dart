// lib/domain/repositories/treatment_repository.dart
//
// Abstract interface for resolving treatment guidance.

import '../entities/treatment.dart';

abstract class TreatmentRepository {
  /// Fetches treatment guidance from the remote LLM endpoint.
  Future<TreatmentResponse> getTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  });
}
