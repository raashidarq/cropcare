// lib/data/repositories/accessibility_repository_impl.dart

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/accessibility_settings.dart';
import '../../domain/repositories/accessibility_repository.dart';

class AccessibilityRepositoryImpl implements AccessibilityRepository {
  static const _kSettingsKey = 'cropcare_accessibility_settings';
  final FlutterSecureStorage _storage;

  AccessibilitySettings _cachedSettings = const AccessibilitySettings();

  AccessibilityRepositoryImpl({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<AccessibilitySettings> getSettings() async {
    try {
      final raw = await _storage.read(key: _kSettingsKey);
      if (raw != null && raw.isNotEmpty) {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cachedSettings = AccessibilitySettings(
          textScaleFactor: (map['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
          isHighContrast: map['isHighContrast'] as bool? ?? false,
          autoReadDiagnosis: map['autoReadDiagnosis'] as bool? ?? false,
          speechRate: (map['speechRate'] as num?)?.toDouble() ?? 0.5,
          hapticFeedbackEnabled: map['hapticFeedbackEnabled'] as bool? ?? true,
        );
      }
    } catch (_) {}
    return _cachedSettings;
  }

  @override
  Future<void> saveSettings(AccessibilitySettings settings) async {
    _cachedSettings = settings;
    try {
      final payload = jsonEncode({
        'textScaleFactor': settings.textScaleFactor,
        'isHighContrast': settings.isHighContrast,
        'autoReadDiagnosis': settings.autoReadDiagnosis,
        'speechRate': settings.speechRate,
        'hapticFeedbackEnabled': settings.hapticFeedbackEnabled,
      });
      await _storage.write(key: _kSettingsKey, value: payload);
    } catch (_) {}
  }
}
