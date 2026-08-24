import 'package:flutter/material.dart';

import 'app.dart';
import 'application/auth/auth_cubit.dart';
import 'application/onboarding/app_state_cubit.dart';
import 'data/local/database/app_database.dart';
import 'data/local/ml/ml_inference_service.dart';
import 'data/remote/auth_api_client.dart';
import 'data/remote/treatment_api_client.dart';
import 'data/repositories/app_state_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/crop_repository_impl.dart';
import 'data/repositories/diagnosis_repository_impl.dart';
import 'data/repositories/disease_repository_impl.dart';
import 'data/repositories/escalation_repository_impl.dart';
import 'data/repositories/local_user_repository_impl.dart';
import 'data/repositories/scan_repository_impl.dart';
import 'data/repositories/treatment_repository_impl.dart';
import 'domain/usecases/auth/get_or_create_guest_user_use_case.dart';
import 'domain/usecases/auth/sign_in_use_case.dart';
import 'domain/usecases/auth/sign_out_use_case.dart';
import 'domain/usecases/auth/upgrade_guest_user_use_case.dart';
import 'domain/usecases/crop/get_supported_crops_use_case.dart';
import 'domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import 'domain/usecases/diagnosis/validate_image_use_case.dart';
import 'domain/usecases/escalation/create_escalation_use_case.dart';
import 'domain/usecases/history/get_scan_history_use_case.dart';
import 'domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'domain/usecases/onboarding/get_app_state_use_case.dart';
import 'domain/usecases/onboarding/set_language_use_case.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Database ──────────────────────────────────────────────────────────────
  final database = AppDatabase();

  // ── Repositories ──────────────────────────────────────────────────────────
  final appStateRepository = AppStateRepositoryImpl(database);
  final localUserRepository = LocalUserRepositoryImpl(database);
  final cropRepository = CropRepositoryImpl(database);
  final scanRepository = ScanRepositoryImpl(database);
  final diagnosisRepository = DiagnosisRepositoryImpl(database);
  final escalationRepository = EscalationRepositoryImpl(database);
  final treatmentApiClient = TreatmentApiClient();
  final treatmentRepository = TreatmentRepositoryImpl(apiClient: treatmentApiClient);
  final authApiClient = AuthApiClient();
  final authRepository = AuthRepositoryImpl(
    apiClient: authApiClient,
    localUserRepository: localUserRepository,
  );

  // ── Reference data seeding ────────────────────────────────────────────────
  // Crops must be seeded first (disease has FK → crop).
  final getSupportedCropsUseCase = GetSupportedCropsUseCase(cropRepository);
  await getSupportedCropsUseCase(); // triggers _seedCrops() if table empty

  final diseaseRepo = DiseaseRepositoryImpl(database);
  await diseaseRepo.seedDiseasesIfEmpty(); // seeds after crops are guaranteed present

  // ── ML ────────────────────────────────────────────────────────────────────
  final mlInferenceService = MlInferenceService();
  await mlInferenceService.loadModel();

  // ── Use cases ─────────────────────────────────────────────────────────────
  final getAppStateUseCase = GetAppStateUseCase(appStateRepository);
  final completeOnboardingUseCase = CompleteOnboardingUseCase(appStateRepository);
  final setLanguageUseCase = SetLanguageUseCase(appStateRepository);
  final getOrCreateGuestUserUseCase = GetOrCreateGuestUserUseCase(localUserRepository);
  final upgradeGuestUserUseCase = UpgradeGuestUserUseCase(authRepository);
  final signInUseCase = SignInUseCase(authRepository);
  final signOutUseCase = SignOutUseCase(authRepository);
  final validateImageUseCase = ValidateImageUseCase();
  final runDiagnosisUseCase = RunDiagnosisUseCase(
    inferenceService: mlInferenceService,
    diagnosisRepository: diagnosisRepository,
    db: database,
  );
  final resolveTreatmentUseCase = ResolveTreatmentUseCase(
    treatmentRepository: treatmentRepository,
    diagnosisRepository: diagnosisRepository,
  );
  final createEscalationUseCase = CreateEscalationUseCase(
    escalationRepository: escalationRepository,
    scanRepository: scanRepository,
  );
  final getScanHistoryUseCase = GetScanHistoryUseCase(scanRepository);

  // ── Bootstrap ─────────────────────────────────────────────────────────────
  final user = await getOrCreateGuestUserUseCase();

  final appStateCubit = AppStateCubit(
    getAppStateUseCase: getAppStateUseCase,
    completeOnboardingUseCase: completeOnboardingUseCase,
    setLanguageUseCase: setLanguageUseCase,
  );

  final authCubit = AuthCubit(
    initialUser: user,
    upgradeGuestUserUseCase: upgradeGuestUserUseCase,
    signInUseCase: signInUseCase,
    signOutUseCase: signOutUseCase,
  );

  runApp(CropCareApp(
    appStateCubit: appStateCubit,
    user: user,
    authCubit: authCubit,
    getSupportedCropsUseCase: getSupportedCropsUseCase,
    validateImageUseCase: validateImageUseCase,
    runDiagnosisUseCase: runDiagnosisUseCase,
    resolveTreatmentUseCase: resolveTreatmentUseCase,
    createEscalationUseCase: createEscalationUseCase,
    getScanHistoryUseCase: getScanHistoryUseCase,
  ));
}
