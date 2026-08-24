// lib/application/diagnosis/diagnosis_cubit.dart
//
// Manages the state of treatment guidance retrieval for a diagnosis.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/diagnosis.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'diagnosis_state.dart';

class DiagnosisCubit extends Cubit<DiagnosisState> {
  final ResolveTreatmentUseCase resolveTreatmentUseCase;

  DiagnosisCubit({
    required this.resolveTreatmentUseCase,
  }) : super(const DiagnosisInitial());

  void checkDiagnosis(Diagnosis diagnosis) {
    if (diagnosis.isHealthy || diagnosis.diseaseId == null) {
      emit(const DiagnosisHealthy());
    } else {
      emit(const DiagnosisInitial());
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
      emit(DiagnosisTreatmentLoaded(
        treatment: treatment,
        source: TreatmentSource.llm,
      ));
    } catch (e) {
      emit(DiagnosisTreatmentError(
        message: e.toString().replaceFirst('TreatmentApiException: ', ''),
      ));
    }
  }
}
