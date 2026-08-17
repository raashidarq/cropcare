import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/repositories/app_state_repository_impl.dart';

void main() {
  late AppDatabase db;
  late AppStateRepositoryImpl repository;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = AppStateRepositoryImpl(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('default values are correct on first run', () async {
    final state = await repository.getAppState();
    expect(state.onboardingCompleted, isFalse);
    expect(state.languageCode, equals('en'));
    expect(state.firstLaunchAt, isNotNull);
  });

  test('onboarding flag persists correctly', () async {
    await repository.completeOnboarding('si');
    final state = await repository.getAppState();
    expect(state.onboardingCompleted, isTrue);
    expect(state.languageCode, equals('si'));
  });

  test('setLanguage does not affect onboarding_completed', () async {
    final initialState = await repository.getAppState();
    expect(initialState.onboardingCompleted, isFalse);

    await repository.setLanguage('ta');
    final stateAfterLanguage = await repository.getAppState();
    expect(stateAfterLanguage.onboardingCompleted, isFalse);
    expect(stateAfterLanguage.languageCode, equals('ta'));

    await repository.completeOnboarding('en');
    final completedState = await repository.getAppState();
    expect(completedState.onboardingCompleted, isTrue);

    await repository.setLanguage('si');
    final finalState = await repository.getAppState();
    expect(finalState.onboardingCompleted, isTrue);
    expect(finalState.languageCode, equals('si'));
  });
}
