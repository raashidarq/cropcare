import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/app_state.dart';
import 'package:cropcare/domain/repositories/app_state_repository.dart';
import 'package:cropcare/domain/usecases/onboarding/set_language_use_case.dart';

class FakeAppStateRepository implements AppStateRepository {
  String? completedLanguageCode;
  String? setLanguageCode;

  @override
  Future<AppState> getAppState() async => AppState.initial();

  @override
  Future<void> completeOnboarding(String languageCode) async {
    completedLanguageCode = languageCode;
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    setLanguageCode = languageCode;
  }
}

void main() {
  test('SetLanguageUseCase calls repository.setLanguage', () async {
    final fakeRepo = FakeAppStateRepository();
    final useCase = SetLanguageUseCase(fakeRepo);

    await useCase('si');

    expect(fakeRepo.setLanguageCode, equals('si'));
  });
}
