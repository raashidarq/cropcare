import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/application/onboarding/app_state_cubit.dart';
import 'package:cropcare/domain/entities/app_state.dart';
import 'package:cropcare/domain/repositories/app_state_repository.dart';
import 'package:cropcare/domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/get_app_state_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/set_language_use_case.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/settings/settings_screen.dart';

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

void main() {
  testWidgets('SettingsScreen renders reorganized sections: Profile, Preferences, Data & Storage, Support & Legal', (tester) async {
    final repo = _FakeAppStateRepository();
    final appStateCubit = AppStateCubit(
      getAppStateUseCase: GetAppStateUseCase(repo),
      completeOnboardingUseCase: CompleteOnboardingUseCase(repo),
      setLanguageUseCase: SetLanguageUseCase(repo),
    );

    tester.view.physicalSize = const Size(800, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: BlocProvider.value(
            value: appStateCubit,
            child: const SettingsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Profile & Account
    expect(find.byKey(const Key('settings_profile_row')), findsOneWidget);
    expect(find.text('User Profile'), findsOneWidget);

    // 2. Preferences
    expect(find.byKey(const Key('settings_language_row')), findsOneWidget);
    expect(find.byKey(const Key('settings_notifications_row')), findsOneWidget);
    expect(find.byKey(const Key('settings_accessibility_row')), findsOneWidget);

    // 3. Data & Storage
    expect(find.byKey(const Key('settings_offline_data_row')), findsOneWidget);
    expect(find.byKey(const Key('settings_export_data_row')), findsOneWidget);
    expect(find.byKey(const Key('settings_export_button')), findsOneWidget);

    // 4. Support & Legal
    expect(find.byKey(const Key('settings_faq_row')), findsOneWidget);
    expect(find.byKey(const Key('settings_feedback_row')), findsOneWidget);
    expect(find.byKey(const Key('settings_terms_privacy_row')), findsOneWidget);
    expect(find.text('Help & FAQ'), findsOneWidget);
    expect(find.text('Send Feedback'), findsOneWidget);
    expect(find.text('Terms & Privacy Policy'), findsOneWidget);
  });
}
