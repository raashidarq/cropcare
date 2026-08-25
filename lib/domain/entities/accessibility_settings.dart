// lib/domain/entities/accessibility_settings.dart

class AccessibilitySettings {
  final double textScaleFactor;
  final bool isHighContrast;
  final bool autoReadDiagnosis;
  final double speechRate;
  final bool hapticFeedbackEnabled;

  const AccessibilitySettings({
    this.textScaleFactor = 1.0,
    this.isHighContrast = false,
    this.autoReadDiagnosis = false,
    this.speechRate = 0.5,
    this.hapticFeedbackEnabled = true,
  });

  AccessibilitySettings copyWith({
    double? textScaleFactor,
    bool? isHighContrast,
    bool? autoReadDiagnosis,
    double? speechRate,
    bool? hapticFeedbackEnabled,
  }) {
    return AccessibilitySettings(
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      isHighContrast: isHighContrast ?? this.isHighContrast,
      autoReadDiagnosis: autoReadDiagnosis ?? this.autoReadDiagnosis,
      speechRate: speechRate ?? this.speechRate,
      hapticFeedbackEnabled: hapticFeedbackEnabled ?? this.hapticFeedbackEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AccessibilitySettings &&
          runtimeType == other.runtimeType &&
          textScaleFactor == other.textScaleFactor &&
          isHighContrast == other.isHighContrast &&
          autoReadDiagnosis == other.autoReadDiagnosis &&
          speechRate == other.speechRate &&
          hapticFeedbackEnabled == other.hapticFeedbackEnabled;

  @override
  int get hashCode =>
      textScaleFactor.hashCode ^
      isHighContrast.hashCode ^
      autoReadDiagnosis.hashCode ^
      speechRate.hashCode ^
      hapticFeedbackEnabled.hashCode;
}
