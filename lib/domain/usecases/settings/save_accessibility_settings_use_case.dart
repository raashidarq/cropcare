// lib/domain/usecases/settings/save_accessibility_settings_use_case.dart

import '../../entities/accessibility_settings.dart';
import '../../repositories/accessibility_repository.dart';

class SaveAccessibilitySettingsUseCase {
  final AccessibilityRepository repository;

  SaveAccessibilitySettingsUseCase(this.repository);

  Future<void> call(AccessibilitySettings settings) async {
    await repository.saveSettings(settings);
  }
}
