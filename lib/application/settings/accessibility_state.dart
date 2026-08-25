// lib/application/settings/accessibility_state.dart

import '../../domain/entities/accessibility_settings.dart';

class AccessibilityState {
  final AccessibilitySettings settings;
  final bool isLoading;

  const AccessibilityState({
    this.settings = const AccessibilitySettings(),
    this.isLoading = false,
  });

  double get textScaleFactor => settings.textScaleFactor;
  bool get isHighContrast => settings.isHighContrast;
  bool get autoReadDiagnosis => settings.autoReadDiagnosis;
  double get speechRate => settings.speechRate;
  bool get hapticFeedbackEnabled => settings.hapticFeedbackEnabled;

  AccessibilityState copyWith({
    AccessibilitySettings? settings,
    bool? isLoading,
  }) {
    return AccessibilityState(
      settings: settings ?? this.settings,
      isLoading: isLoading ?? this.isLoading,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilityState &&
          runtimeType == other.runtimeType &&
          settings == other.settings &&
          isLoading == other.isLoading;

  @override
  int get hashCode => settings.hashCode ^ isLoading.hashCode;
}
