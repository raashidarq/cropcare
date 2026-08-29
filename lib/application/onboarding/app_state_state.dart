import '../../domain/entities/app_state.dart';

abstract class AppStateState {
  final String languageCode;
  const AppStateState({required this.languageCode});
}

class AppStateLoading extends AppStateState {
  const AppStateLoading({super.languageCode = 'en'});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStateLoading && languageCode == other.languageCode;

  @override
  int get hashCode => languageCode.hashCode;
}

class AppStateOnboardingNeeded extends AppStateState {
  final AppState appState;

  AppStateOnboardingNeeded(this.appState)
      : super(languageCode: appState.languageCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStateOnboardingNeeded && appState == other.appState;

  @override
  int get hashCode => appState.hashCode;
}

class AppStateOnboardingComplete extends AppStateState {
  final AppState appState;

  /// Not persisted - a one-shot signal for the frame that completes
  /// onboarding. Set when the user tapped "Create an account" on the final
  /// onboarding step, so app.dart's HomeScreen can open the account screen
  /// on launch without onboarding_screen.dart having to construct its own,
  /// separately-wired HomeScreen to do it (see TD-032).
  final bool openAccountOnLaunch;

  AppStateOnboardingComplete(this.appState, {this.openAccountOnLaunch = false})
      : super(languageCode: appState.languageCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStateOnboardingComplete && appState == other.appState;

  @override
  int get hashCode => appState.hashCode;
}
