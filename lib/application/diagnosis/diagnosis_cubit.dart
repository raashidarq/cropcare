// lib/application/diagnosis/diagnosis_cubit.dart
//
// Manages treatment guidance for a diagnosis.
//
// Three ways guidance arrives, tried in this order when the result screen
// opens:
//
//  * `loadLocalGuidance` reads the guideline shipped with the app — instant,
//    offline, free — so the screen answers "what do I do?" without the
//    farmer having to ask for it.
//  * `loadCachedAiTreatment` then checks whether this diagnosis was already
//    sent to the LLM in an earlier visit, and if so, shows that answer
//    straight from the device with no network call at all. This is what
//    stops re-opening the SAME diagnosis from re-billing the request every
//    single time — before this existed, the AI answer lived only in this
//    cubit's own state and vanished the moment the screen was disposed.
//  * `fetchTreatmentGuidance` calls the LLM for a fresh answer. Unlike the
//    two reads above, this is NEVER automatic — it runs only when the
//    farmer taps to ask for it, from the diagnosis result screen's own
//    button. That used to run on its own the moment local guidance
//    finished loading; it stopped being automatic because a farmer who left
//    the screen mid-request had no way to know a request was even in
//    flight, let alone cancel it — and because "ask, then answer" is a much
//    more legible shape for a request that reads what they just typed.
//
// Crucially, a failed AI call leaves whatever was already on screen (local
// or a stale cached AI answer) rather than replacing it with an error — the
// farmer is never left with less than they started with.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/diagnosis.dart';
import '../../domain/usecases/diagnosis/get_cached_ai_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'diagnosis_state.dart';

class DiagnosisCubit extends Cubit<DiagnosisState> {
  final ResolveTreatmentUseCase resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetCachedAiTreatmentUseCase? getCachedAiTreatmentUseCase;

  DiagnosisCubit({
    required this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
    this.getCachedAiTreatmentUseCase,
  }) : super(const DiagnosisInitial());

  void checkDiagnosis(Diagnosis diagnosis) {
    if (isClosed) return;
    if (diagnosis.isHealthy || diagnosis.diseaseId == null) {
      emit(const DiagnosisHealthy());
    } else {
      emit(const DiagnosisInitial());
    }
  }

  /// Puts the app's own guidance on screen straight away.
  ///
  /// Deliberately quiet: if there is no local guideline, or the read fails,
  /// the state is left alone so the screen falls back to offering the online
  /// request. Nothing here is worth an error banner — the farmer did not ask
  /// for this, it is the screen doing its job.
  Future<void> loadLocalGuidance({
    required String diseaseId,
    required String languageCode,
  }) async {
    final useCase = getLocalTreatmentGuidanceUseCase;
    if (useCase == null) return;
    if (state is! DiagnosisInitial) return;

    try {
      final treatment = await useCase(
        diseaseId: diseaseId,
        languageCode: languageCode,
      );
      if (treatment == null) return;
      // The screen may have been left, or a request the farmer made in the
      // meantime may have already answered — either way, this read no
      // longer has anything useful to contribute.
      if (isClosed || state is! DiagnosisInitial) return;
      emit(DiagnosisTreatmentLoaded(
        treatment: treatment,
        source: TreatmentSource.localFallback,
      ));
    } catch (_) {
      // Leave the state as it was; the online path is still offered.
    }
  }

  /// Shows the AI answer this diagnosis already got in an earlier visit,
  /// straight from the device — no network call, no quota spent.
  ///
  /// Deliberately quiet on both "nothing cached" and failure, the same as
  /// [loadLocalGuidance]: this is the screen checking for something better
  /// to show, not a request the farmer made, so there is nothing here worth
  /// surfacing as an error.
  Future<void> loadCachedAiTreatment({required String diagnosisId}) async {
    final useCase = getCachedAiTreatmentUseCase;
    if (useCase == null) return;

    try {
      final cached = await useCase(diagnosisId: diagnosisId);
      if (cached == null) return;

      final current = state;
      // Something already better, or already in flight, wins - a cache
      // read racing behind a fresh fetch must never clobber it.
      if (current is DiagnosisTreatmentLoaded &&
          (current.isAi || current.isRefreshing)) {
        return;
      }
      if (isClosed) return;
      emit(DiagnosisTreatmentLoaded(
        treatment: cached,
        source: TreatmentSource.llm,
      ));
    } catch (_) {
      // Leave the state as it was; whatever loaded first stays on screen.
    }
  }

  Future<void> fetchTreatmentGuidance({
    required String diagnosisId,
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
  }) async {
    if (isClosed) return;
    final previous = state;

    // Keep whatever is already on screen while the better version is fetched.
    // Emitting a bare loading state here is what used to make the farmer's
    // steps vanish behind a spinner.
    if (previous is DiagnosisTreatmentLoaded) {
      emit(previous.copyWith(isRefreshing: true, refreshFailed: false));
    } else {
      emit(const DiagnosisTreatmentLoading());
    }

    try {
      final treatment = await resolveTreatmentUseCase(
        diagnosisId: diagnosisId,
        cropId: cropId,
        diseaseId: diseaseId,
        confidence: confidence,
        severity: severity,
        languageCode: languageCode,
        userObservations: userObservations,
      );
      // The screen that asked for this may be long gone by the time the
      // network call returns - emitting into a closed cubit throws
      // (BlocBase.emit: "Cannot emit new states after calling close"). The
      // result is still correctly cached by resolveTreatmentUseCase before
      // this check runs, so a farmer who left mid-request still finds the
      // answer waiting next time, even though this specific emit is skipped.
      if (isClosed) return;
      // Which source actually answered is decided inside
      // TreatmentRepositoryImpl: it calls the API first and only falls back
      // to the on-device guideline table if that throws. A null
      // interpretationId is the fallback's signature. Reporting llm
      // unconditionally (as this did before) mislabelled every offline
      // answer as an AI one.
      emit(DiagnosisTreatmentLoaded(
        treatment: treatment,
        source: treatment.interpretationId != null
            ? TreatmentSource.llm
            : TreatmentSource.localFallback,
      ));
    } catch (e) {
      if (isClosed) return;
      // The whole point of the state shape: if there was guidance before, the
      // farmer keeps it. An error only replaces the screen when there was
      // nothing to lose.
      if (previous is DiagnosisTreatmentLoaded) {
        emit(previous.copyWith(isRefreshing: false, refreshFailed: true));
        return;
      }
      emit(DiagnosisTreatmentError(
        message: e.toString().replaceFirst('TreatmentApiException: ', ''),
      ));
    }
  }
}
