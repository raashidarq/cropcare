// lib/application/diagnosis/diagnosis_cubit.dart
//
// Manages treatment guidance for a diagnosis.
//
// Two ways guidance arrives:
//
//  * `loadLocalGuidance` runs when the result screen opens. It reads the
//    guideline shipped with the app — instant, offline, free — so the screen
//    answers "what do I do?" without the farmer having to ask for it.
//  * `fetchTreatmentGuidance` is the explicit upgrade: an LLM call that takes
//    the farmer's own observations into account. It costs mobile data, so it
//    stays an action rather than a side effect of opening a screen.
//
// Before this split there was only the second one, which meant the app's
// entire payload sat behind a button on the screen you opened to get it.

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

  Future<void> fetchTreatmentGuidance({
    required String diagnosisId,
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
  }) async {
    emit(const DiagnosisTreatmentLoading());
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
      emit(DiagnosisTreatmentError(
        message: e.toString().replaceFirst('TreatmentApiException: ', ''),
      ));
    }
  }
}
