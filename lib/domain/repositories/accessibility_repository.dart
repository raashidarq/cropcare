// lib/domain/repositories/accessibility_repository.dart

import '../entities/accessibility_settings.dart';

abstract class AccessibilityRepository {
  Future<AccessibilitySettings> getSettings();
  Future<void> saveSettings(AccessibilitySettings settings);
}
