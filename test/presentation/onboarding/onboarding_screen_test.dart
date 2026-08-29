import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/onboarding/app_state_cubit.dart';
import 'package:cropcare/application/onboarding/app_state_state.dart';
import 'package:cropcare/domain/entities/app_state.dart';
import 'package:cropcare/domain/repositories/app_state_repository.dart';
import 'package:cropcare/domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/get_app_state_use_case.dart';
import 'package:cropcare/domain/usecases/onboarding/set_language_use_case.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/onboarding/onboarding_screen.dart';

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
  testWidgets(
    'Skip jumps to the closing account step rather than leaving the flow',
    (WidgetTester tester) async {
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
            child: const MaterialApp(
              home: OnboardingScreen(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Language is now chosen BEFORE onboarding, so skipping no longer
      // routes to language selection. It jumps to the final step, where the
      // account-or-guest choice still has to be made.
      expect(find.byKey(const Key('onboarding_skip_button')), findsOneWidget);

      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('onboarding_create_account_button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('onboarding_continue_guest_button')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Tapping Create Account at the final step completes onboarding without '
    'throwing',
    (WidgetTester tester) async {
      // Regression test for two live bugs, both about what happens when
      // onboarding actually completes:
      //
      // 1. Completing onboarding used to be done via a BuildContext
      //    captured by LanguageSelectionScreen and handed to this screen as
      //    a callback. LanguageSelectionScreen is replaced - and its
      //    context torn down - the instant navigation lands here, so by the
      //    time a farmer actually reached this final step and tapped
      //    Create Account, that captured context was already deactivated.
      //    Navigator.of(context) on it threw "Null check operator used on
      //    a null value". Completing onboarding now uses THIS screen's own
      //    context instead, which stays valid for as long as its own
      //    buttons are tappable.
      //
      // 2. This screen used to also push its own, separately-constructed
      //    `HomeScreen(openAccountOnLaunch: ...)`, missing every real
      //    dependency (authCubit, syncCubit, every use case) that app.dart
      //    wires into the real one. Screens reading those via
      //    `context.read` threw `ProviderNotFoundException` - a real,
      //    reproducible release-build bug (TD-032), confirmed live via adb
      //    logcat against a genuine `flutter build apk --release` build:
      //    "Provider<SyncCubit> not found for BlocConsumer<SyncCubit,
      //    SyncState>", swallowed on-screen as a blank grey box by
      //    Flutter's release-mode default ErrorWidget. This screen now
      //    leaves HomeScreen construction entirely to app.dart's own
      //    reactive root BlocBuilder, and only has to get the cubit into
      //    the right state with the right one-shot signal.
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
            child: const MaterialApp(
              home: OnboardingScreen(languageCode: 'en'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('onboarding_skip_button')));
      await tester.pumpAndSettle();

      final errors = <FlutterErrorDetails>[];
      final originalOnError = FlutterError.onError;
      FlutterError.onError = errors.add;

      await tester.tap(
        find.byKey(const Key('onboarding_create_account_button')),
      );
      await tester.pumpAndSettle();

      FlutterError.onError = originalOnError;

      expect(errors, isEmpty);
      expect(repository.appState.onboardingCompleted, isTrue);
      final state = cubit.state;
      expect(state, isA<AppStateOnboardingComplete>());
      expect(
        (state as AppStateOnboardingComplete).openAccountOnLaunch,
        isTrue,
        reason: 'Create Account was tapped, so app.dart should open the '
            'account screen once it builds the real HomeScreen',
      );
    },
  );
}
