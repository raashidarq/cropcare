// lib/domain/usecases/settings/get_accessibility_settings_use_case.dart

import '../../entities/accessibility_settings.dart';
import '../../repositories/accessibility_repository.dart';

class GetAccessibilitySettingsUseCase {
  final AccessibilityRepository repository;

  GetAccessibilitySettingsUseCase(this.repository);

  Future<AccessibilitySettings> call() async {
    return await repository.getSettings();
  }
}
