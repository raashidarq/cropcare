// lib/domain/repositories/treatment_repository.dart
//
// Abstract interface for resolving treatment guidance.

import '../entities/treatment.dart';

abstract class TreatmentRepository {
  /// Reads the guidance shipped with the app for [diseaseId], without
  /// touching the network. Returns null when nothing is stored for it.
  ///
  /// This exists so the result screen can show something immediately. The app
  /// seeds a trilingual guideline for every disease the model can name, so on
  /// the common path this returns real advice instantly, offline, and for
  /// free — which is what a farmer standing in a field actually needs.
  /// [getTreatmentGuidance] then becomes an opt-in upgrade rather than the
  /// only way to see anything at all.
  Future<TreatmentResponse?> getLocalTreatmentGuidance({
    required String diseaseId,
    required String languageCode,
  });

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
