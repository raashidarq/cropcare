// lib/application/settings/accessibility_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/accessibility_settings.dart';
import '../../domain/usecases/settings/get_accessibility_settings_use_case.dart';
import '../../domain/usecases/settings/save_accessibility_settings_use_case.dart';
import 'accessibility_state.dart';

class AccessibilityCubit extends Cubit<AccessibilityState> {
  final GetAccessibilitySettingsUseCase getAccessibilitySettingsUseCase;
  final SaveAccessibilitySettingsUseCase saveAccessibilitySettingsUseCase;

  AccessibilityCubit({
    required this.getAccessibilitySettingsUseCase,
    required this.saveAccessibilitySettingsUseCase,
  }) : super(const AccessibilityState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    emit(state.copyWith(isLoading: true));
    try {
      final settings = await getAccessibilitySettingsUseCase();
      emit(state.copyWith(settings: settings, isLoading: false));
    } catch (_) {
      emit(state.copyWith(isLoading: false));
    }
  }

  Future<void> updateSettings(AccessibilitySettings newSettings) async {
    emit(state.copyWith(settings: newSettings));
    await saveAccessibilitySettingsUseCase(newSettings);
  }

  Future<void> setTextScaleFactor(double scaleFactor) async {
    final updated = state.settings.copyWith(textScaleFactor: scaleFactor);
    await updateSettings(updated);
  }

  Future<void> setHighContrast(bool enabled) async {
    final updated = state.settings.copyWith(isHighContrast: enabled);
    await updateSettings(updated);
  }

  Future<void> setAutoReadDiagnosis(bool enabled) async {
    final updated = state.settings.copyWith(autoReadDiagnosis: enabled);
    await updateSettings(updated);
  }

  Future<void> setSpeechRate(double rate) async {
    final updated = state.settings.copyWith(speechRate: rate);
    await updateSettings(updated);
  }

  Future<void> setHapticFeedback(bool enabled) async {
    final updated = state.settings.copyWith(hapticFeedbackEnabled: enabled);
    await updateSettings(updated);
  }

  Future<void> resetToDefaults() async {
    const defaults = AccessibilitySettings();
    await updateSettings(defaults);
  }
}
