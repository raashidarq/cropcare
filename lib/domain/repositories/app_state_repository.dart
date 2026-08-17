import '../entities/app_state.dart';

abstract class AppStateRepository {
  Future<AppState> getAppState();
  Future<void> completeOnboarding(String languageCode);
  Future<void> setLanguage(String languageCode);
}
