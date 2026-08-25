// test/data/repositories/accessibility_repository_impl_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:cropcare/domain/entities/accessibility_settings.dart';
import 'package:cropcare/data/repositories/accessibility_repository_impl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
  });

  test('AccessibilityRepositoryImpl returns default settings initially', () async {
    final repository = AccessibilityRepositoryImpl();
    final settings = await repository.getSettings();

    expect(settings.textScaleFactor, equals(1.0));
    expect(settings.isHighContrast, isFalse);
    expect(settings.autoReadDiagnosis, isFalse);
    expect(settings.speechRate, equals(0.5));
    expect(settings.hapticFeedbackEnabled, isTrue);
  });

  test('AccessibilityRepositoryImpl saves and retrieves modified settings', () async {
    final repository = AccessibilityRepositoryImpl();
    const updated = AccessibilitySettings(
      textScaleFactor: 1.3,
      isHighContrast: true,
      autoReadDiagnosis: true,
      speechRate: 0.7,
      hapticFeedbackEnabled: false,
    );

    await repository.saveSettings(updated);

    final retrieved = await repository.getSettings();
    expect(retrieved.textScaleFactor, equals(1.3));
    expect(retrieved.isHighContrast, isTrue);
    expect(retrieved.autoReadDiagnosis, isTrue);
    expect(retrieved.speechRate, equals(0.7));
    expect(retrieved.hapticFeedbackEnabled, isFalse);
  });
}
