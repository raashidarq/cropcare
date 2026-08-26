// Guidance, once on screen, must never disappear.
//
// The result screen paints the on-device guideline immediately and then tries
// to replace it with better AI-written advice. That second call fails often in
// this app's world: no signal, a server asleep, or - as observed in production
// - a free-tier Gemini quota of 20 requests per day per model.
//
// When it fails the farmer must be left with the guidance they already had.
// The earlier state model emitted a bare error, which blanked the steps and
// left them with less than before they opened the screen.

import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/diagnosis/diagnosis_cubit.dart';
import 'package:cropcare/application/diagnosis/diagnosis_state.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/treatment.dart';
import 'package:cropcare/domain/repositories/diagnosis_repository.dart';
import 'package:cropcare/domain/repositories/treatment_repository.dart';
import 'package:cropcare/domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart';
import 'package:cropcare/domain/usecases/diagnosis/resolve_treatment_use_case.dart';

const _local = TreatmentResponse(
  summary: 'On-device summary',
  whatToDo: 'Remove infected leaves. Spray copper.',
  whatToAvoid: 'Do not compost them.',
  recheckAfterDays: 7,
  interpretationId: null,
);

const _ai = TreatmentResponse(
  summary: 'AI summary',
  whatToDo: 'Remove infected leaves today.',
  whatToAvoid: 'Do not spray at noon.',
  recheckAfterDays: 5,
  interpretationId: 'interp-1',
);

class _Repo implements TreatmentRepository {
  final bool hasLocal;
  final Object? remoteError;
  int remoteCalls = 0;

  _Repo({this.hasLocal = true, this.remoteError});

  @override
  Future<TreatmentResponse?> getLocalTreatmentGuidance({
    required String diseaseId,
    required String languageCode,
  }) async =>
      hasLocal ? _local : null;

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
    remoteCalls++;
    if (remoteError != null) throw remoteError!;
    return _ai;
  }
}

class _DiagRepo implements DiagnosisRepository {
  @override
  Future<Diagnosis> createDiagnosis(Diagnosis d) async => d;

  @override
  Future<Diagnosis?> getDiagnosisByScanId(String scanId) async => null;

  @override
  Future<void> updateTreatmentSource(
    String diagnosisId, {
    required TreatmentSource source,
    String? llmInterpretationId,
    String? guidelineId,
  }) async {}
}

DiagnosisCubit _build(_Repo repo) => DiagnosisCubit(
      resolveTreatmentUseCase: ResolveTreatmentUseCase(
        treatmentRepository: repo,
        diagnosisRepository: _DiagRepo(),
      ),
      getLocalTreatmentGuidanceUseCase: GetLocalTreatmentGuidanceUseCase(
        treatmentRepository: repo,
      ),
    );

Future<void> loadThenFetch(DiagnosisCubit c) async {
  await c.loadLocalGuidance(diseaseId: 'tomato_late_blight', languageCode: 'en');
  await c.autoFetchAiGuidance(
    diagnosisId: 'd1',
    cropId: 'tomato',
    diseaseId: 'tomato_late_blight',
    confidence: 0.9,
    severity: 'high',
    languageCode: 'en',
  );
}

void main() {
  test('the AI answer replaces the on-device one when it arrives', () async {
    final repo = _Repo();
    final cubit = _build(repo);
    await loadThenFetch(cubit);

    final state = cubit.state as DiagnosisTreatmentLoaded;
    expect(state.treatment.summary, 'AI summary');
    expect(state.isAi, isTrue);
    expect(repo.remoteCalls, 1);
  });

  test('a failed AI call leaves the on-device guidance on screen', () async {
    final repo = _Repo(remoteError: Exception('no signal'));
    final cubit = _build(repo);
    await loadThenFetch(cubit);

    // The whole point. Not an error state - the steps are still there.
    final state = cubit.state as DiagnosisTreatmentLoaded;
    expect(state.treatment.summary, 'On-device summary');
    expect(state.refreshFailed, isTrue);
    expect(state.isRefreshing, isFalse);
  });

  test('a quota error behaves the same as no signal', () async {
    // Observed in production: the free tier allows 20 requests per day per
    // model, so this is not an edge case.
    final repo = _Repo(
      remoteError: Exception('429 You exceeded your current quota'),
    );
    final cubit = _build(repo);
    await loadThenFetch(cubit);

    final state = cubit.state as DiagnosisTreatmentLoaded;
    expect(state.treatment.summary, 'On-device summary');
    expect(state.refreshFailed, isTrue);
  });

  test('with no on-device guideline, a failure IS an error state', () async {
    final repo = _Repo(hasLocal: false, remoteError: Exception('no signal'));
    final cubit = _build(repo);
    await loadThenFetch(cubit);

    // Nothing was lost here, because there was nothing to lose.
    expect(cubit.state, isA<DiagnosisTreatmentError>());
  });

  test('the steps stay visible while the better version is fetched', () async {
    final repo = _Repo();
    final cubit = _build(repo);
    await cubit.loadLocalGuidance(
      diseaseId: 'tomato_late_blight',
      languageCode: 'en',
    );

    final states = <DiagnosisState>[];
    final sub = cubit.stream.listen(states.add);
    await cubit.autoFetchAiGuidance(
      diagnosisId: 'd1',
      cropId: 'tomato',
      diseaseId: 'tomato_late_blight',
      confidence: 0.9,
      severity: 'high',
      languageCode: 'en',
    );
    await sub.cancel();

    // No bare loading state: that is what used to blank the screen.
    expect(states.any((s) => s is DiagnosisTreatmentLoading), isFalse);
    final refreshing = states.whereType<DiagnosisTreatmentLoaded>().first;
    expect(refreshing.isRefreshing, isTrue);
    expect(refreshing.treatment.summary, 'On-device summary');
  });

  test('the automatic fetch runs only once per screen', () async {
    final repo = _Repo();
    final cubit = _build(repo);
    await loadThenFetch(cubit);
    await cubit.autoFetchAiGuidance(
      diagnosisId: 'd1',
      cropId: 'tomato',
      diseaseId: 'tomato_late_blight',
      confidence: 0.9,
      severity: 'high',
      languageCode: 'en',
    );

    // Reopening a scan should not re-bill the request every time, and on a
    // 20-per-day quota that matters.
    expect(repo.remoteCalls, 1);
  });

  test('a manual retry after a failure still works', () async {
    final repo = _Repo(remoteError: Exception('no signal'));
    final cubit = _build(repo);
    await loadThenFetch(cubit);
    expect((cubit.state as DiagnosisTreatmentLoaded).refreshFailed, isTrue);

    // "Retry AI" is a real second attempt, not a no-op.
    await cubit.fetchTreatmentGuidance(
      diagnosisId: 'd1',
      cropId: 'tomato',
      diseaseId: 'tomato_late_blight',
      confidence: 0.9,
      severity: 'high',
      languageCode: 'en',
    );
    expect(repo.remoteCalls, 2);
  });
}
