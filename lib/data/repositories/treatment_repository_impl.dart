// lib/data/repositories/treatment_repository_impl.dart
//
// Implementation of TreatmentRepository forwarding to TreatmentApiClient
// with automatic offline fallback to local SQLite treatment guidelines.

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
      // Offline fallback: Query local SQLite treatment guideline table
      if (db != null) {
        final guideline = await (db!.select(db!.treatmentGuidelineTable)
              ..where((t) => t.diseaseId.equals(diseaseId)))
            .getSingleOrNull();

        if (guideline != null) {
          final summary = (languageCode == 'si'
                  ? guideline.summarySi
                  : languageCode == 'ta'
                      ? guideline.summaryTa
                      : guideline.summaryEn) ??
              guideline.summaryEn ??
              '';

          final whatToDo = (languageCode == 'si'
                  ? guideline.whatToDoSi
                  : languageCode == 'ta'
                      ? guideline.whatToDoTa
                      : guideline.whatToDoEn) ??
              guideline.whatToDoEn ??
              '';

          final whatToAvoid = (languageCode == 'si'
                  ? guideline.whatToAvoidSi
                  : languageCode == 'ta'
                      ? guideline.whatToAvoidTa
                      : guideline.whatToAvoidEn) ??
              guideline.whatToAvoidEn ??
              '';

          return TreatmentResponse(
            summary: summary,
            whatToDo: whatToDo,
            whatToAvoid: whatToAvoid,
            recheckAfterDays: guideline.recheckAfterDays,
            interpretationId: null, // null denotes offline fallback
          );
        }
      }
      rethrow;
    }
  }
}
