import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/onboarding/app_state_cubit.dart';
import 'package:cropcare/domain/entities/app_state.dart';
import 'package:cropcare/domain/repositories/app_state_repository.dart';
import 'package:cropcare/domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/get_app_state_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/set_language_use_case.dart';
import 'package:cropcare/presentation/onboarding/language_selection_screen.dart';
import 'package:cropcare/presentation/onboarding/onboarding_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

class FakeAppStateRepository implements AppStateRepository {
  AppState appState = AppState.initial();

  @override
  Future<AppState> getAppState() async => appState;

  @override
  Future<void> completeOnboarding(String languageCode) async {
    appState = appState.copyWith(
      onboardingCompleted: true,
      languageCode: languageCode,
    );
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    appState = appState.copyWith(languageCode: languageCode);
  }
}

void main() {
  testWidgets('selecting a language applies it and continues into onboarding', (
    WidgetTester tester,
  ) async {
    final repository = FakeAppStateRepository();
    final cubit = AppStateCubit(
      getAppStateUseCase: GetAppStateUseCase(repository),
      completeOnboardingUseCase: CompleteOnboardingUseCase(repository),
      setLanguageUseCase: SetLanguageUseCase(repository),
    );

    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: LocalizationProvider(
          languageCode: 'en',
          child: const MaterialApp(home: LanguageSelectionScreen()),
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('lang_si')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('confirm_language')));
    await tester.pumpAndSettle();

    // Language selection now runs BEFORE the introduction, so the
    // introduction is shown already translated. It applies the language
    // but does not yet mark onboarding complete — that happens at the end
    // of the flow, after the account-or-guest choice.
    expect(find.byType(OnboardingScreen), findsOneWidget);

    expect(repository.appState.languageCode, equals('si'));
    expect(repository.appState.onboardingCompleted, isFalse);
  });
}
