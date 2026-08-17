import '../../repositories/app_state_repository.dart';

class CompleteOnboardingUseCase {
  final AppStateRepository repository;

  CompleteOnboardingUseCase(this.repository);

  Future<void> call(String languageCode) {
    return repository.completeOnboarding(languageCode);
  }
}
