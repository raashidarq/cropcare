// lib/application/diagnosis/diagnosis_cubit.dart
//
// Manages treatment guidance for a diagnosis.
//
// Two ways guidance arrives:
//
//  * `loadLocalGuidance` runs when the result screen opens. It reads the
//    guideline shipped with the app — instant, offline, free — so the screen
//    answers "what do I do?" without the farmer having to ask for it.
//  * `fetchTreatmentGuidance` calls the LLM for better, more specific advice.
//    It now runs automatically once the local guidance is showing, rather than
//    waiting for a tap.
//
// The earlier design kept the LLM call behind a button on the grounds that it
// costs mobile data. That reasoning conflated two very different things: a
// scan IMAGE upload is megabytes and genuinely worth guarding, but this is a
// text request and a page of JSON back — a rustle of data. Making a farmer
// tap for it, and wait, bought them nothing.
//
// So both run: the on-device guideline paints immediately, and the AI answer
// replaces it when it arrives. Crucially, a failed AI call leaves the local
// guidance on screen rather than replacing it with an error — the farmer is
// never left with less than they started with.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/diagnosis.dart';
import '../../domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'diagnosis_state.dart';

class DiagnosisCubit extends Cubit<DiagnosisState> {
  final ResolveTreatmentUseCase resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;

  DiagnosisCubit({
    required this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
  }) : super(const DiagnosisInitial());

  void checkDiagnosis(Diagnosis diagnosis) {
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
      // A request the farmer made in the meantime wins.
      if (state is! DiagnosisInitial) return;
      emit(DiagnosisTreatmentLoaded(
        treatment: treatment,
        source: TreatmentSource.localFallback,
      ));
    } catch (_) {
      // Leave the state as it was; the online path is still offered.
    }
  }

  /// True once an automatic AI fetch has been attempted for this screen, so
  /// reopening a scan does not silently re-bill the request every time.
  bool _autoFetchAttempted = false;

  /// Fetches AI guidance without being asked, once per screen.
  ///
  /// Silent on failure beyond the flag on the state: the farmer did not ask
  /// for this, and they already have the on-device guidance in front of them.
  Future<void> autoFetchAiGuidance({
    required String diagnosisId,
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
  }) async {
    if (_autoFetchAttempted) return;
    _autoFetchAttempted = true;

    final current = state;
    // Already AI-written; nothing to improve on.
    if (current is DiagnosisTreatmentLoaded && current.isAi) return;

    await fetchTreatmentGuidance(
      diagnosisId: diagnosisId,
      cropId: cropId,
      diseaseId: diseaseId,
      confidence: confidence,
      severity: severity,
      languageCode: languageCode,
      userObservations: userObservations,
    );
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
    // A manual retry re-arms the automatic path too, so a later observation
    // edit can still refresh.
    _autoFetchAttempted = true;
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
