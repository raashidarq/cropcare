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

  AppStateOnboardingComplete(this.appState)
      : super(languageCode: appState.languageCode);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppStateOnboardingComplete && appState == other.appState;

  @override
  int get hashCode => appState.hashCode;
}
