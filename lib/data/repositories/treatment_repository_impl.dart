// lib/data/repositories/treatment_repository_impl.dart
//
// Implementation of TreatmentRepository.
//
// Two entry points, deliberately separate:
//
//  * `getLocalTreatmentGuidance` reads only the on-device guideline table. No
//    network, no cost, no waiting. The app seeds a trilingual guideline for
//    every disease the model can name, so this answers on the common path.
//  * `getTreatmentGuidance` calls the LLM endpoint for advice tailored to the
//    farmer's own observations, falling back to the same local table if the
//    call fails.
//
// They were previously one method, which meant the only way to see any
// guidance at all was to make a metered network request.

import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../local/database/app_database.dart';
import '../remote/treatment_api_client.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentApiClient apiClient;
  final AppDatabase? db;

  TreatmentRepositoryImpl({
    required this.apiClient,
    this.db,
  });

  @override
  Future<TreatmentResponse?> getLocalTreatmentGuidance({
    required String diseaseId,
    required String languageCode,
  }) async {
    return _readLocalGuideline(
      diseaseId: diseaseId,
      languageCode: languageCode,
    );
  }

  @override
  Future<TreatmentResponse> getTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  }) async {
    try {
      return await apiClient.fetchTreatmentGuidance(
        cropId: cropId,
        diseaseId: diseaseId,
        confidence: confidence,
        severity: severity,
        languageCode: languageCode,
        userObservations: userObservations,
        authToken: authToken,
      );
    } catch (e) {
      // Offline fallback: the same on-device guideline the screen may already
      // be showing. Returning it again is harmless and keeps the contract
      // (this method never returns null).
      final local = await _readLocalGuideline(
        diseaseId: diseaseId,
        languageCode: languageCode,
      );
      if (local != null) return local;
      rethrow;
    }
  }

  /// Reads and localises the guideline row for [diseaseId], or null if there
  /// is none. A null `interpretationId` on the result is what marks it as
  /// on-device rather than LLM-authored; callers rely on that.
  Future<TreatmentResponse?> _readLocalGuideline({
    required String diseaseId,
    required String languageCode,
  }) async {
    final database = db;
    if (database == null) return null;

    final guideline = await (database.select(database.treatmentGuidelineTable)
          ..where((t) => t.diseaseId.equals(diseaseId)))
        .getSingleOrNull();
    if (guideline == null) return null;

    // Falls back to English per field rather than per row: a partially
    // translated guideline should still show its translated fields.
    String pick(String? si, String? ta, String? en) {
      final value = switch (languageCode) {
        'si' => si,
        'ta' => ta,
        _ => en,
      };
      return value ?? en ?? '';
    }

    final summary = pick(
      guideline.summarySi,
      guideline.summaryTa,
      guideline.summaryEn,
    );
    final whatToDo = pick(
      guideline.whatToDoSi,
      guideline.whatToDoTa,
      guideline.whatToDoEn,
    );
    final whatToAvoid = pick(
      guideline.whatToAvoidSi,
      guideline.whatToAvoidTa,
      guideline.whatToAvoidEn,
    );

    // An entirely blank row is worse than no row: it renders an empty card.
    if (summary.isEmpty && whatToDo.isEmpty && whatToAvoid.isEmpty) return null;

    return TreatmentResponse(
      summary: summary,
      whatToDo: whatToDo,
      whatToAvoid: whatToAvoid,
      recheckAfterDays: guideline.recheckAfterDays,
      interpretationId: null, // null denotes on-device guidance
    );
  }
}
