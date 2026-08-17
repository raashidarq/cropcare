import 'package:flutter/material.dart';

import 'app.dart';
import 'application/onboarding/app_state_cubit.dart';
import 'data/local/database/app_database.dart';
import 'data/repositories/app_state_repository_impl.dart';
import 'data/repositories/crop_repository_impl.dart';
import 'data/repositories/local_user_repository_impl.dart';
import 'domain/usecases/auth/get_or_create_guest_user_use_case.dart';
import 'domain/usecases/crop/get_supported_crops_use_case.dart';
import 'domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'domain/usecases/onboarding/get_app_state_use_case.dart';
import 'domain/usecases/onboarding/set_language_use_case.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = AppDatabase();
  final appStateRepository = AppStateRepositoryImpl(database);
  final localUserRepository = LocalUserRepositoryImpl(database);
  final cropRepository = CropRepositoryImpl(database);

  final getAppStateUseCase = GetAppStateUseCase(appStateRepository);
  final completeOnboardingUseCase = CompleteOnboardingUseCase(appStateRepository);
  final setLanguageUseCase = SetLanguageUseCase(appStateRepository);
  final getOrCreateGuestUserUseCase = GetOrCreateGuestUserUseCase(localUserRepository);
  final getSupportedCropsUseCase = GetSupportedCropsUseCase(cropRepository);

  final user = await getOrCreateGuestUserUseCase();

  final appStateCubit = AppStateCubit(
    getAppStateUseCase: getAppStateUseCase,
    completeOnboardingUseCase: completeOnboardingUseCase,
    setLanguageUseCase: setLanguageUseCase,
  );

  runApp(CropCareApp(
    appStateCubit: appStateCubit,
    user: user,
    getSupportedCropsUseCase: getSupportedCropsUseCase,
  ));
}
