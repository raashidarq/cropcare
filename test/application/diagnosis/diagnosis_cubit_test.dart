import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/diagnosis/diagnosis_cubit.dart';
import 'package:cropcare/application/diagnosis/diagnosis_state.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/treatment.dart';
import 'package:cropcare/domain/repositories/diagnosis_repository.dart';
import 'package:cropcare/domain/repositories/treatment_repository.dart';
import 'package:cropcare/domain/usecases/diagnosis/resolve_treatment_use_case.dart';

class _FakeTreatmentRepository implements TreatmentRepository {
  TreatmentResponse? response;
  Exception? exception;

  // The screen reads on-device guidance on open; these fakes exercise the
  // explicit online request, so there is nothing local to hand back.
  @override
  Future<TreatmentResponse?> getLocalTreatmentGuidance({
    required String diseaseId,
    required String languageCode,
  }) async =>
      null;

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
    if (exception != null) throw exception!;
    return response!;
  }
}

class _FakeDiagnosisRepository implements DiagnosisRepository {
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
  }) async {}

  @override
  Future<void> cacheAiTreatment(
    String diagnosisId,
    TreatmentResponse treatment,
  ) async {}

  @override
  Future<TreatmentResponse?> getCachedAiTreatment(String diagnosisId) async =>
      null;
}

void main() {
  group('DiagnosisCubit', () {
    late _FakeTreatmentRepository fakeTreatmentRepo;
    late _FakeDiagnosisRepository fakeDiagnosisRepo;
    late ResolveTreatmentUseCase resolveTreatmentUseCase;

    setUp(() {
      fakeTreatmentRepo = _FakeTreatmentRepository();
      fakeDiagnosisRepo = _FakeDiagnosisRepository();
      resolveTreatmentUseCase = ResolveTreatmentUseCase(
        treatmentRepository: fakeTreatmentRepo,
        diagnosisRepository: fakeDiagnosisRepo,
      );
    });

    test('checkDiagnosis emits DiagnosisHealthy for healthy plant', () {
      final cubit = DiagnosisCubit(resolveTreatmentUseCase: resolveTreatmentUseCase);
      const healthyDiagnosis = Diagnosis(
        id: 'd1',
        scanId: 's1',
        diseaseId: 'tomato_healthy',
        modelVersionId: 'cropcare-v1.0',
        confidence: 0.98,
        resultState: DiagnosisResultState.confident,
        treatmentSource: TreatmentSource.localFallback,
        inferredAt: '2026-08-24T12:00:00Z',
      );

      cubit.checkDiagnosis(healthyDiagnosis);
      expect(cubit.state, isA<DiagnosisHealthy>());
    });

    test('fetchTreatmentGuidance emits Loading then Loaded on success', () async {
      fakeTreatmentRepo.response = const TreatmentResponse(
        summary: 'Treatment summary text',
        whatToDo: 'Prune leaves',
        whatToAvoid: 'Don’t overwater',
        recheckAfterDays: 5,
        interpretationId: 'interp-1',
      );

      final cubit = DiagnosisCubit(resolveTreatmentUseCase: resolveTreatmentUseCase);

      final states = <DiagnosisState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.fetchTreatmentGuidance(
        diagnosisId: 'd1',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        confidence: 0.85,
        severity: 'moderate',
        languageCode: 'en',
      );

      await Future.delayed(Duration.zero);
      expect(states.length, equals(2));
      expect(states[0], isA<DiagnosisTreatmentLoading>());
      expect(states[1], isA<DiagnosisTreatmentLoaded>());

      final loadedState = states[1] as DiagnosisTreatmentLoaded;
      expect(loadedState.treatment.summary, equals('Treatment summary text'));

      await subscription.cancel();
    });

    test('fetchTreatmentGuidance emits Loading then Error on failure', () async {
      fakeTreatmentRepo.exception = Exception('Network down');

      final cubit = DiagnosisCubit(resolveTreatmentUseCase: resolveTreatmentUseCase);

      final states = <DiagnosisState>[];
      final subscription = cubit.stream.listen(states.add);

      await cubit.fetchTreatmentGuidance(
        diagnosisId: 'd1',
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        confidence: 0.85,
        severity: 'moderate',
        languageCode: 'en',
      );

      await Future.delayed(Duration.zero);
      expect(states.length, equals(2));
      expect(states[0], isA<DiagnosisTreatmentLoading>());
      expect(states[1], isA<DiagnosisTreatmentError>());

      await subscription.cancel();
    });

    test(
      'a fetch that outlives the cubit does not throw '
      '(StateError: Cannot emit new states after calling close)',
      () async {
        // Regression test for a live crash: the diagnosis result screen used
        // to fire an AI fetch automatically, and a farmer leaving the screen
        // mid-request disposed the cubit while that fetch was still
        // in-flight. The network call resolved afterwards and tried to
        // emit() into an already-closed Cubit, which flutter_bloc throws
        // for rather than silently ignoring.
        fakeTreatmentRepo.response = const TreatmentResponse(
          summary: 'Treatment summary text',
          whatToDo: 'Prune leaves',
          whatToAvoid: 'Don’t overwater',
          recheckAfterDays: 5,
          interpretationId: 'interp-1',
        );

        final cubit = DiagnosisCubit(resolveTreatmentUseCase: resolveTreatmentUseCase);

        final fetch = cubit.fetchTreatmentGuidance(
          diagnosisId: 'd1',
          cropId: 'tomato',
          diseaseId: 'tomato_early_blight',
          confidence: 0.85,
          severity: 'moderate',
          languageCode: 'en',
        );
        // The screen is left before the network call (a real Future.value
        // here, so already scheduled but not yet resolved) completes.
        await cubit.close();

        // Must not throw StateError - the emit inside fetchTreatmentGuidance
        // is expected to see isClosed and skip itself.
        await fetch;
      },
    );
  });
}
