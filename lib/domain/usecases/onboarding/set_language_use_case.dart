import '../../repositories/app_state_repository.dart';

class SetLanguageUseCase {
  final AppStateRepository repository;

  SetLanguageUseCase(this.repository);

  Future<void> call(String languageCode) {
    return repository.setLanguage(languageCode);
  }
}
