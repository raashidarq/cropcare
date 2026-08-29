import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/onboarding/complete_onboarding_use_case.dart';
import '../../domain/usecases/onboarding/get_app_state_use_case.dart';
import '../../domain/usecases/onboarding/set_language_use_case.dart';
import 'app_state_state.dart';

class AppStateCubit extends Cubit<AppStateState> {
  final GetAppStateUseCase getAppStateUseCase;
  final CompleteOnboardingUseCase completeOnboardingUseCase;
  final SetLanguageUseCase setLanguageUseCase;

  AppStateCubit({
    required this.getAppStateUseCase,
    required this.completeOnboardingUseCase,
    required this.setLanguageUseCase,
  }) : super(const AppStateLoading()) {
    loadAppState();
  }

  Future<void> loadAppState() async {
    emit(AppStateLoading(languageCode: state.languageCode));
    final appState = await getAppStateUseCase();
    if (appState.onboardingCompleted) {
      emit(AppStateOnboardingComplete(appState));
    } else {
      emit(AppStateOnboardingNeeded(appState));
    }
  }

  Future<void> completeOnboarding(
    String languageCode, {
    bool openAccountOnLaunch = false,
  }) async {
    await completeOnboardingUseCase(languageCode);
    final updatedState = await getAppStateUseCase();
    emit(AppStateOnboardingComplete(
      updatedState,
      openAccountOnLaunch: openAccountOnLaunch,
    ));
  }

  Future<void> setLanguage(String languageCode) async {
    await setLanguageUseCase(languageCode);
    final updatedState = await getAppStateUseCase();
    if (updatedState.onboardingCompleted) {
      emit(AppStateOnboardingComplete(updatedState));
    } else {
      emit(AppStateOnboardingNeeded(updatedState));
    }
  }
}
