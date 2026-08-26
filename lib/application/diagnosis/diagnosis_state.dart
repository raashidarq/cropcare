// lib/application/diagnosis/diagnosis_state.dart
//
// States for DiagnosisCubit handling treatment guidance.
//
// The important property here is that guidance, once on screen, never
// disappears. The screen shows on-device guidance immediately and then tries
// to replace it with better AI-written guidance. If that attempt fails — no
// signal, server down — the farmer must be left with what they already had,
// not with an error where their steps used to be.
//
// That is why refreshing and failing-to-refresh are flags on the loaded state
// rather than states of their own: modelling them separately is what made an
// AI failure blank the screen.

import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/treatment.dart';

abstract class DiagnosisState {
  const DiagnosisState();
}

class DiagnosisInitial extends DiagnosisState {
  const DiagnosisInitial();
}

/// Nothing to show yet. Only used before any guidance has arrived — once
/// something is on screen, a refresh uses [DiagnosisTreatmentLoaded.isRefreshing].
class DiagnosisTreatmentLoading extends DiagnosisState {
  const DiagnosisTreatmentLoading();
}

class DiagnosisTreatmentLoaded extends DiagnosisState {
  final TreatmentResponse treatment;
  final TreatmentSource source;

  /// A better version is being fetched. The current [treatment] stays on
  /// screen throughout.
  final bool isRefreshing;

  /// The last attempt to fetch AI guidance failed. [treatment] is still the
  /// on-device guidance and is still worth reading.
  final bool refreshFailed;

  const DiagnosisTreatmentLoaded({
    required this.treatment,
    required this.source,
    this.isRefreshing = false,
    this.refreshFailed = false,
  });

  bool get isAi => source == TreatmentSource.llm;

  DiagnosisTreatmentLoaded copyWith({
    TreatmentResponse? treatment,
    TreatmentSource? source,
    bool? isRefreshing,
    bool? refreshFailed,
  }) {
    return DiagnosisTreatmentLoaded(
      treatment: treatment ?? this.treatment,
      source: source ?? this.source,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      refreshFailed: refreshFailed ?? this.refreshFailed,
    );
  }
}

/// Failed with nothing to fall back on — the app ships no guideline for this
/// disease and the request did not succeed either.
class DiagnosisTreatmentError extends DiagnosisState {
  final String message;

  const DiagnosisTreatmentError({required this.message});
}

class DiagnosisHealthy extends DiagnosisState {
  const DiagnosisHealthy();
}
