// Guidance, once on screen, must never disappear.
//
// The result screen paints the on-device guideline immediately, then a
// farmer can ask for better AI-written advice via the "Get AI
// Recommendation" button (DiagnosisCubit.fetchTreatmentGuidance - never
// automatic, see that method's own docs for why). That call fails often in
// this app's world: no signal, a server asleep, or - as observed in
// production - a free-tier Gemini quota of 20 requests per day per model.
//
// When it fails the farmer must be left with the guidance they already had.
// The earlier state model emitted a bare error, which blanked the steps and
// left them with less than before they opened the screen.
//
// Also covers the on-device cache: an AI answer already fetched for this
// diagnosis in an earlier visit is shown straight from the device, with no
// new network call - see DiagnosisCubit.loadCachedAiTreatment.

import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/diagnosis/diagnosis_cubit.dart';
import 'package:cropcare/application/diagnosis/diagnosis_state.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/treatment.dart';
import 'package:cropcare/domain/repositories/diagnosis_repository.dart';
import 'package:cropcare/domain/repositories/treatment_repository.dart';
import 'package:cropcare/domain/usecases/diagnosis/get_cached_ai_treatment_use_case.dart';
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

/// Fakes the on-device cache too, so tests can assert what
/// resolveTreatmentUseCase actually wrote and what a later cache read sees -
/// the same round trip the real Drift-backed implementation performs.
class _DiagRepo implements DiagnosisRepository {
  TreatmentResponse? cached;
  int cacheWrites = 0;

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

  @override
  Future<void> cacheAiTreatment(
    String diagnosisId,
    TreatmentResponse treatment,
  ) async {
    cacheWrites++;
    cached = treatment;
  }

  @override
  Future<TreatmentResponse?> getCachedAiTreatment(String diagnosisId) async =>
      cached;
}

DiagnosisCubit _build(_Repo repo, {_DiagRepo? diagRepo}) {
  final diag = diagRepo ?? _DiagRepo();
  return DiagnosisCubit(
    resolveTreatmentUseCase: ResolveTreatmentUseCase(
      treatmentRepository: repo,
      diagnosisRepository: diag,
    ),
    getLocalTreatmentGuidanceUseCase: GetLocalTreatmentGuidanceUseCase(
      treatmentRepository: repo,
    ),
    getCachedAiTreatmentUseCase: GetCachedAiTreatmentUseCase(
      diagnosisRepository: diag,
    ),
  );
}

Future<void> loadThenAsk(DiagnosisCubit c) async {
  await c.loadLocalGuidance(diseaseId: 'tomato_late_blight', languageCode: 'en');
  // Stands in for the farmer tapping "Get AI Recommendation" - the only
  // thing that ever calls this now.
  await c.fetchTreatmentGuidance(
    diagnosisId: 'd1',
    cropId: 'tomato',
    diseaseId: 'tomato_late_blight',
    confidence: 0.9,
    severity: 'high',
    languageCode: 'en',
  );
}

void main() {
  test('the AI answer replaces the on-device one once asked for', () async {
    final repo = _Repo();
    final cubit = _build(repo);
    await loadThenAsk(cubit);

    final state = cubit.state as DiagnosisTreatmentLoaded;
    expect(state.treatment.summary, 'AI summary');
    expect(state.isAi, isTrue);
    expect(repo.remoteCalls, 1);
  });

  test('a failed AI call leaves the on-device guidance on screen', () async {
    final repo = _Repo(remoteError: Exception('no signal'));
    final cubit = _build(repo);
    await loadThenAsk(cubit);

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
    await loadThenAsk(cubit);

    final state = cubit.state as DiagnosisTreatmentLoaded;
    expect(state.treatment.summary, 'On-device summary');
    expect(state.refreshFailed, isTrue);
  });

  test('with no on-device guideline, a failure IS an error state', () async {
    final repo = _Repo(hasLocal: false, remoteError: Exception('no signal'));
    final cubit = _build(repo);
    await loadThenAsk(cubit);

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
    await cubit.fetchTreatmentGuidance(
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

  test('a manual retry after a failure still works', () async {
    final repo = _Repo(remoteError: Exception('no signal'));
    final cubit = _build(repo);
    await loadThenAsk(cubit);
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

  group('on-device cache — reopening a diagnosis must not re-bill it', () {
    test('a successful AI fetch is cached against the diagnosis', () async {
      final repo = _Repo();
      final diagRepo = _DiagRepo();
      final cubit = _build(repo, diagRepo: diagRepo);
      await loadThenAsk(cubit);

      expect(diagRepo.cacheWrites, 1);
      expect(diagRepo.cached?.summary, 'AI summary');
    });

    test('a local-fallback answer is never cached as if it were AI', () async {
      // Caching the on-device fallback here would be pointless (the local
      // guideline table already answers that for free) and would mislabel
      // a local answer as "already fetched from the LLM" on the next open.
      final repo = _Repo(remoteError: Exception('no signal'));
      final diagRepo = _DiagRepo();
      final cubit = _build(repo, diagRepo: diagRepo);
      await loadThenAsk(cubit);

      expect(diagRepo.cacheWrites, 0);
    });

    test(
      'a cached AI answer is shown on the next visit with no new request',
      () async {
        final repo = _Repo();
        final diagRepo = _DiagRepo()..cached = _ai;
        final cubit = _build(repo, diagRepo: diagRepo);

        // Local guidance paints first, as always...
        await cubit.loadLocalGuidance(
          diseaseId: 'tomato_late_blight',
          languageCode: 'en',
        );
        expect(
          (cubit.state as DiagnosisTreatmentLoaded).treatment.summary,
          'On-device summary',
        );

        // ...then the cache check replaces it with the AI answer, without
        // ever calling the remote repository.
        await cubit.loadCachedAiTreatment(diagnosisId: 'd1');
        final state = cubit.state as DiagnosisTreatmentLoaded;
        expect(state.treatment.summary, 'AI summary');
        expect(state.isAi, isTrue);
        expect(repo.remoteCalls, 0);
      },
    );

    test('no cached answer leaves the on-device guidance as-is', () async {
      final repo = _Repo();
      final cubit = _build(repo); // fresh _DiagRepo(), nothing cached

      await cubit.loadLocalGuidance(
        diseaseId: 'tomato_late_blight',
        languageCode: 'en',
      );
      await cubit.loadCachedAiTreatment(diagnosisId: 'd1');

      final state = cubit.state as DiagnosisTreatmentLoaded;
      expect(state.treatment.summary, 'On-device summary');
      expect(state.isAi, isFalse);
    });
  });
}
