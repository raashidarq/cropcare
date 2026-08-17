import 'package:flutter/material.dart';

import 'app.dart';
import 'application/onboarding/app_state_cubit.dart';
import 'data/local/database/app_database.dart';
import 'data/repositories/app_state_repository_impl.dart';
import 'domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'domain/usecases/onboarding/get_app_state_use_case.dart';
import 'domain/usecases/onboarding/set_language_use_case.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final repository = AppStateRepositoryImpl(database);

  final getAppStateUseCase = GetAppStateUseCase(repository);
  final completeOnboardingUseCase = CompleteOnboardingUseCase(repository);
  final setLanguageUseCase = SetLanguageUseCase(repository);

  final appStateCubit = AppStateCubit(
    getAppStateUseCase: getAppStateUseCase,
    completeOnboardingUseCase: completeOnboardingUseCase,
    setLanguageUseCase: setLanguageUseCase,
  );

  runApp(CropCareApp(appStateCubit: appStateCubit));
}
