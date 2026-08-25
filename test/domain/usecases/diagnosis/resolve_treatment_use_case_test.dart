import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/treatment.dart';
import 'package:cropcare/domain/repositories/diagnosis_repository.dart';
import 'package:cropcare/domain/repositories/treatment_repository.dart';
import 'package:cropcare/domain/usecases/diagnosis/resolve_treatment_use_case.dart';

class FakeTreatmentRepository implements TreatmentRepository {
  TreatmentResponse? responseToReturn;
  Exception? exceptionToThrow;

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
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return responseToReturn!;
  }
}

class FakeDiagnosisRepository implements DiagnosisRepository {
  String? updatedDiagnosisId;
  TreatmentSource? updatedSource;
  String? updatedLlmInterpretationId;

  @override
  Future<Diagnosis> createDiagnosis(Diagnosis diagnosis) async => diagnosis;

  @override
  Future<Diagnosis?> getDiagnosisByScanId(String scanId) async => null;

  @override
  Future<void> updateTreatmentSource(
    String diagnosisId, {
    required TreatmentSource source,
    String? guidelineId,
    String? llmInterpretationId,
  }) async {
    updatedDiagnosisId = diagnosisId;
    updatedSource = source;
    updatedLlmInterpretationId = llmInterpretationId;
  }
}

void main() {
  group('ResolveTreatmentUseCase', () {
    test('resolves treatment successfully and updates diagnosis table', () async {
      final fakeTreatmentRepo = FakeTreatmentRepository()
        ..responseToReturn = const TreatmentResponse(
          summary: 'Test summary',
          whatToDo: 'Test what to do',
          whatToAvoid: 'Test what to avoid',
          recheckAfterDays: 7,
          interpretationId: 'interp-uuid-999',
        );
      final fakeDiagRepo = FakeDiagnosisRepository();

      final useCase = ResolveTreatmentUseCase(
        treatmentRepository: fakeTreatmentRepo,
        diagnosisRepository: fakeDiagRepo,
      );

      final result = await useCase(
        diagnosisId: 'diag-1',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        confidence: 0.88,
        severity: 'moderate',
        languageCode: 'en',
        userObservations: 'Spots on lower leaves',
      );

      expect(result.summary, equals('Test summary'));
      expect(result.whatToDo, equals('Test what to do'));
      expect(result.recheckAfterDays, equals(7));
      expect(result.interpretationId, equals('interp-uuid-999'));

      expect(fakeDiagRepo.updatedDiagnosisId, equals('diag-1'));
      expect(fakeDiagRepo.updatedSource, equals(TreatmentSource.llm));
      expect(fakeDiagRepo.updatedLlmInterpretationId, equals('interp-uuid-999'));
    });

    test('resolves offline fallback treatment and updates source to offlineFallback', () async {
      final fakeTreatmentRepo = FakeTreatmentRepository()
        ..responseToReturn = const TreatmentResponse(
          summary: 'Offline guideline summary',
          whatToDo: 'Prune infected leaves',
          whatToAvoid: 'Avoid overhead watering',
          recheckAfterDays: 5,
          interpretationId: null, // Null denotes offline fallback
        );
      final fakeDiagRepo = FakeDiagnosisRepository();

      final useCase = ResolveTreatmentUseCase(
        treatmentRepository: fakeTreatmentRepo,
        diagnosisRepository: fakeDiagRepo,
      );

      final result = await useCase(
        diagnosisId: 'diag-2',
        cropId: 'tomato',
        diseaseId: 'tomato_late_blight',
        confidence: 0.95,
        severity: 'high',
        languageCode: 'en',
      );

      expect(result.summary, equals('Offline guideline summary'));
      expect(result.interpretationId, isNull);

      expect(fakeDiagRepo.updatedDiagnosisId, equals('diag-2'));
      expect(fakeDiagRepo.updatedSource, equals(TreatmentSource.localFallback));
      expect(fakeDiagRepo.updatedLlmInterpretationId, isNull);
    });
  });
}
