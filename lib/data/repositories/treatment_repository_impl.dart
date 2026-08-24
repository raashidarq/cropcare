// lib/data/repositories/treatment_repository_impl.dart
//
// Implementation of TreatmentRepository forwarding to TreatmentApiClient.

import '../../domain/entities/treatment.dart';
import '../../domain/repositories/treatment_repository.dart';
import '../remote/treatment_api_client.dart';

class TreatmentRepositoryImpl implements TreatmentRepository {
  final TreatmentApiClient apiClient;

  TreatmentRepositoryImpl({required this.apiClient});

  @override
  Future<TreatmentResponse> getTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  }) {
    return apiClient.fetchTreatmentGuidance(
      cropId: cropId,
      diseaseId: diseaseId,
      confidence: confidence,
      severity: severity,
      languageCode: languageCode,
      userObservations: userObservations,
      authToken: authToken,
    );
  }
}
