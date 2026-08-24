// lib/application/diagnosis/diagnosis_state.dart
//
// States for DiagnosisCubit handling treatment guidance fetching.

import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/treatment.dart';

abstract class DiagnosisState {
  const DiagnosisState();
}

class DiagnosisInitial extends DiagnosisState {
  const DiagnosisInitial();
}

class DiagnosisTreatmentLoading extends DiagnosisState {
  const DiagnosisTreatmentLoading();
}

class DiagnosisTreatmentLoaded extends DiagnosisState {
  final TreatmentResponse treatment;
  final TreatmentSource source;

  const DiagnosisTreatmentLoaded({
    required this.treatment,
    required this.source,
  });
}

class DiagnosisTreatmentError extends DiagnosisState {
  final String message;

  const DiagnosisTreatmentError({required this.message});
}

class DiagnosisHealthy extends DiagnosisState {
  const DiagnosisHealthy();
}
