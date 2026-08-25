// test/application/settings/accessibility_cubit_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/application/settings/accessibility_cubit.dart';
import 'package:cropcare/domain/entities/accessibility_settings.dart';
import 'package:cropcare/domain/repositories/accessibility_repository.dart';
import 'package:cropcare/domain/usecases/settings/get_accessibility_settings_use_case.dart';
import 'package:cropcare/domain/usecases/settings/save_accessibility_settings_use_case.dart';

class _FakeAccessibilityRepository implements AccessibilityRepository {
  AccessibilitySettings _current = const AccessibilitySettings();

  @override
  Future<AccessibilitySettings> getSettings() async => _current;

  @override
  Future<void> saveSettings(AccessibilitySettings settings) async {
    _current = settings;
  }
}

void main() {
  late _FakeAccessibilityRepository repo;
  late AccessibilityCubit cubit;

  setUp(() {
    repo = _FakeAccessibilityRepository();
    cubit = AccessibilityCubit(
      getAccessibilitySettingsUseCase: GetAccessibilitySettingsUseCase(repo),
      saveAccessibilitySettingsUseCase: SaveAccessibilitySettingsUseCase(repo),
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state has default settings', () {
    expect(cubit.state.textScaleFactor, equals(1.0));
    expect(cubit.state.isHighContrast, isFalse);
    expect(cubit.state.autoReadDiagnosis, isFalse);
    expect(cubit.state.speechRate, equals(0.5));
    expect(cubit.state.hapticFeedbackEnabled, isTrue);
  });

  test('setTextScaleFactor updates scale and persists', () async {
    await cubit.setTextScaleFactor(1.45);

    expect(cubit.state.textScaleFactor, equals(1.45));
    final saved = await repo.getSettings();
    expect(saved.textScaleFactor, equals(1.45));
  });

  test('setHighContrast updates contrast mode and persists', () async {
    await cubit.setHighContrast(true);

    expect(cubit.state.isHighContrast, isTrue);
    final saved = await repo.getSettings();
    expect(saved.isHighContrast, isTrue);
  });

  test('setAutoReadDiagnosis and setSpeechRate update audio settings', () async {
    await cubit.setAutoReadDiagnosis(true);
    await cubit.setSpeechRate(0.35);

    expect(cubit.state.autoReadDiagnosis, isTrue);
    expect(cubit.state.speechRate, equals(0.35));
    final saved = await repo.getSettings();
    expect(saved.autoReadDiagnosis, isTrue);
    expect(saved.speechRate, equals(0.35));
  });

  test('setHapticFeedback updates haptic setting', () async {
    await cubit.setHapticFeedback(false);

    expect(cubit.state.hapticFeedbackEnabled, isFalse);
    final saved = await repo.getSettings();
    expect(saved.hapticFeedbackEnabled, isFalse);
  });

  test('resetToDefaults restores initial settings', () async {
    await cubit.setTextScaleFactor(1.45);
    await cubit.setHighContrast(true);

    await cubit.resetToDefaults();

    expect(cubit.state.textScaleFactor, equals(1.0));
    expect(cubit.state.isHighContrast, isFalse);
  });
}
