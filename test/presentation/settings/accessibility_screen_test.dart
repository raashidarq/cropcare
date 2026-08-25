// test/presentation/settings/accessibility_screen_test.dart

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/application/onboarding/app_state_cubit.dart';
import 'package:cropcare/application/settings/accessibility_cubit.dart';
import 'package:cropcare/data/local/tts/text_to_speech_service.dart';
import 'package:cropcare/domain/entities/accessibility_settings.dart';
import 'package:cropcare/domain/entities/app_state.dart';
import 'package:cropcare/domain/repositories/accessibility_repository.dart';
import 'package:cropcare/domain/repositories/app_state_repository.dart';
import 'package:cropcare/domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/get_app_state_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/set_language_use_case.dart';
import 'package:cropcare/domain/usecases/settings/get_accessibility_settings_use_case.dart';
import 'package:cropcare/domain/usecases/settings/save_accessibility_settings_use_case.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/settings/accessibility_screen.dart';

class _FakeAppStateRepository implements AppStateRepository {
  @override
  Future<AppState> getAppState() async => const AppState(
        onboardingCompleted: true,
        languageCode: 'en',
      );

  @override
  Future<void> completeOnboarding(String languageCode) async {}

  @override
  Future<void> setLanguage(String languageCode) async {}
}

class _FakeAccessibilityRepository implements AccessibilityRepository {
  AccessibilitySettings current = const AccessibilitySettings();

  @override
  Future<AccessibilitySettings> getSettings() async => current;

  @override
  Future<void> saveSettings(AccessibilitySettings settings) async {
    current = settings;
  }
}

class _FakeTtsService implements TtsService {
  String? spokenText;
  String? spokenLanguage;

  @override
  ValueListenable<bool> get isPlaying => ValueNotifier<bool>(false);

  @override
  Future<void> speak({required String text, required String languageCode}) async {
    spokenText = text;
    spokenLanguage = languageCode;
  }

  @override
  Future<void> stop() async {}

  @override
  void dispose() {}
}

void main() {
  late _FakeAppStateRepository appStateRepo;
  late AppStateCubit appStateCubit;
  late _FakeAccessibilityRepository accRepo;
  late AccessibilityCubit accCubit;
  late _FakeTtsService fakeTts;

  setUp(() {
    appStateRepo = _FakeAppStateRepository();
    appStateCubit = AppStateCubit(
      getAppStateUseCase: GetAppStateUseCase(appStateRepo),
      completeOnboardingUseCase: CompleteOnboardingUseCase(appStateRepo),
      setLanguageUseCase: SetLanguageUseCase(appStateRepo),
    );

    accRepo = _FakeAccessibilityRepository();
    accCubit = AccessibilityCubit(
      getAccessibilitySettingsUseCase: GetAccessibilitySettingsUseCase(accRepo),
      saveAccessibilitySettingsUseCase: SaveAccessibilitySettingsUseCase(accRepo),
    );

    fakeTts = _FakeTtsService();
  });

  tearDown(() {
    appStateCubit.close();
    accCubit.close();
  });

  Widget buildTestScreen() {
    return LocalizationProvider(
      languageCode: 'en',
      child: MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider.value(value: appStateCubit),
            BlocProvider.value(value: accCubit),
          ],
          child: AccessibilityScreen(ttsService: fakeTts),
        ),
      ),
    );
  }

  testWidgets('AccessibilityScreen renders all controls and elements', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(find.text('Accessibility & Display'), findsOneWidget);
    expect(find.text('Tomato Early Blight'), findsOneWidget);
    expect(find.byKey(const Key('accessibility_text_size_selector')), findsOneWidget);
    expect(find.byKey(const Key('accessibility_high_contrast_switch')), findsOneWidget);
    expect(find.byKey(const Key('accessibility_auto_read_switch')), findsOneWidget);
    expect(find.byKey(const Key('accessibility_speech_rate_selector')), findsOneWidget);
    expect(find.byKey(const Key('accessibility_test_voice_button')), findsOneWidget);
    expect(find.byKey(const Key('accessibility_haptic_switch')), findsOneWidget);
    expect(find.byKey(const Key('accessibility_reset_button')), findsOneWidget);
  });

  testWidgets('Toggling high contrast and auto read switches updates cubit state', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    // Toggle High Contrast
    await tester.tap(find.byKey(const Key('accessibility_high_contrast_switch')));
    await tester.pumpAndSettle();
    expect(accCubit.state.isHighContrast, isTrue);

    // Toggle Auto Read
    await tester.tap(find.byKey(const Key('accessibility_auto_read_switch')));
    await tester.pumpAndSettle();
    expect(accCubit.state.autoReadDiagnosis, isTrue);

    // Toggle Haptic
    await tester.tap(find.byKey(const Key('accessibility_haptic_switch')));
    await tester.pumpAndSettle();
    expect(accCubit.state.hapticFeedbackEnabled, isFalse);
  });

  testWidgets('Tapping test voice invokes TtsService', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('accessibility_test_voice_button')));
    await tester.pumpAndSettle();

    expect(fakeTts.spokenText, isNotNull);
    expect(fakeTts.spokenLanguage, equals('en'));
  });

  testWidgets('Tapping reset button restores defaults', (tester) async {
    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await accCubit.setHighContrast(true);
    await accCubit.setTextScaleFactor(1.45);

    await tester.pumpWidget(buildTestScreen());
    await tester.pumpAndSettle();

    expect(accCubit.state.isHighContrast, isTrue);
    expect(accCubit.state.textScaleFactor, equals(1.45));

    await tester.tap(find.byKey(const Key('accessibility_reset_button')));
    await tester.pumpAndSettle();

    expect(accCubit.state.isHighContrast, isFalse);
    expect(accCubit.state.textScaleFactor, equals(1.0));
  });
}
