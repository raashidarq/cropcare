import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';

import 'app.dart';
import 'application/auth/auth_cubit.dart';
import 'application/onboarding/app_state_cubit.dart';
import 'application/settings/accessibility_cubit.dart';
import 'application/sync/sync_cubit.dart';
import 'data/local/database/app_database.dart';
import 'data/local/ml/ml_inference_service.dart';
import 'data/local/preferences/sync_preferences.dart';
import 'data/remote/auth_api_client.dart';
import 'data/remote/sync_api_client.dart';
import 'data/remote/treatment_api_client.dart';
import 'services/connectivity_service.dart';
import 'services/work_manager_helper.dart';
import 'data/repositories/accessibility_repository_impl.dart';
import 'data/repositories/app_state_repository_impl.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/crop_repository_impl.dart';
import 'data/repositories/diagnosis_repository_impl.dart';
import 'data/repositories/disease_explanation_repository_impl.dart';
import 'data/repositories/disease_repository_impl.dart';
import 'data/repositories/escalation_repository_impl.dart';
import 'data/repositories/local_user_repository_impl.dart';
import 'data/repositories/scan_repository_impl.dart';
import 'data/repositories/sync_repository_impl.dart';
import 'data/repositories/treatment_repository_impl.dart';
import 'domain/usecases/auth/delete_account_use_case.dart';
import 'domain/usecases/auth/get_or_create_guest_user_use_case.dart';
import 'domain/usecases/auth/request_password_reset_use_case.dart';
import 'domain/usecases/auth/request_phone_change_otp_use_case.dart';
import 'domain/usecases/auth/request_phone_otp_use_case.dart';
import 'domain/usecases/auth/sign_in_use_case.dart';
import 'domain/usecases/auth/sign_out_use_case.dart';
import 'domain/usecases/auth/update_email_use_case.dart';
import 'domain/usecases/auth/upgrade_guest_user_use_case.dart';
import 'domain/usecases/auth/verify_phone_change_otp_use_case.dart';
import 'domain/usecases/auth/verify_phone_otp_use_case.dart';
import 'domain/usecases/crop/get_supported_crops_use_case.dart';
import 'domain/usecases/diagnosis/get_disease_explanation_use_case.dart';
import 'domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import 'domain/usecases/diagnosis/validate_image_use_case.dart';
import 'domain/usecases/escalation/create_escalation_use_case.dart';
import 'domain/usecases/feedback/submit_feedback_use_case.dart';
import 'domain/usecases/history/export_scan_history_use_case.dart';
import 'domain/usecases/history/get_scan_history_use_case.dart';
import 'domain/usecases/onboarding/complete_onboarding_use_case.dart';
import 'domain/usecases/onboarding/get_app_state_use_case.dart';
import 'domain/usecases/onboarding/set_language_use_case.dart';
import 'domain/usecases/settings/get_accessibility_settings_use_case.dart';
import 'domain/usecases/settings/save_accessibility_settings_use_case.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ── Background worker ─────────────────────────────────────────────────────
  await WorkManagerHelper.initialize();
  await WorkManagerHelper.scheduleSyncWork();

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
  final treatmentRepository = TreatmentRepositoryImpl(
    apiClient: treatmentApiClient,
    db: database,
  );
  final authApiClient = AuthApiClient();
  final authRepository = AuthRepositoryImpl(
    apiClient: authApiClient,
    localUserRepository: localUserRepository,
  );
  final syncApiClient = SyncApiClient();
  final syncRepository = SyncRepositoryImpl(
    db: database,
    apiClient: syncApiClient,
  );

  // Reclaim operations stranded mid-flight by a previous run that was killed
  // (OS shutdown, crash, background execution limit). Without this they sit
  // in IN_PROGRESS forever and are skipped by every future sync, so those
  // scans never reach the cloud and nothing ever says so.
  try {
    final recovered = await syncRepository.recoverStalledOperations();
    if (recovered > 0) {
      debugPrint('CropCare: recovered $recovered stalled sync operation(s).');
    }
  } catch (e) {
    debugPrint('CropCare: stalled-sync recovery failed: $e');
  }

  // Clear out attempts that produced no usable result. Before validation was
  // moved ahead of scan creation, every rejected photo left an "Unknown" row
  // behind; this removes the ones already on device.
  try {
    final purged = await scanRepository.purgeFailedScans();
    if (purged > 0) {
      debugPrint('CropCare: removed $purged failed scan(s) from history.');
    }
  } catch (e) {
    debugPrint('CropCare: failed-scan purge skipped: $e');
  }

  // ── Reference data seeding ────────────────────────────────────────────────
  // Crops must be seeded first (disease has FK → crop).
  final getSupportedCropsUseCase = GetSupportedCropsUseCase(cropRepository);
  await getSupportedCropsUseCase(); // triggers _seedCrops() if table empty

  final diseaseRepo = DiseaseRepositoryImpl(database);
  await diseaseRepo.seedDiseasesIfEmpty(); // seeds after crops are guaranteed present

  // The `model_version` row referenced by every Diagnosis FK was never
  // actually seeded anywhere — insert it once here, alongside the other
  // reference-data seeding above.
  await database.into(database.modelVersionTable).insertOnConflictUpdate(
        ModelVersionTableCompanion.insert(
          id: 'cropcare-v1.0',
          releasedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

  // ── ML ────────────────────────────────────────────────────────────────────
  // A missing/corrupt model asset must not crash app startup — a farmer
  // should still be able to open the app (browse history, change settings,
  // etc.) even if diagnosis itself is temporarily unavailable. Any scan
  // attempted while the interpreter failed to load will fail gracefully
  // per-scan (RunDiagnosisUseCase catches the resulting StateError and
  // returns an ANALYSIS_FAILED diagnosis) rather than crashing the app.
  final mlInferenceService = MlInferenceService();
  try {
    await mlInferenceService.loadModel();
  } catch (e, st) {
    debugPrint('CropCare: failed to load ML model — diagnosis will be '
        'unavailable until the app is restarted with a working model '
        'asset. Error: $e\n$st');
  }

  // ── Use cases ─────────────────────────────────────────────────────────────
  final getAppStateUseCase = GetAppStateUseCase(appStateRepository);
  final completeOnboardingUseCase = CompleteOnboardingUseCase(appStateRepository);
  final setLanguageUseCase = SetLanguageUseCase(appStateRepository);
  final getOrCreateGuestUserUseCase = GetOrCreateGuestUserUseCase(localUserRepository);
  final upgradeGuestUserUseCase = UpgradeGuestUserUseCase(authRepository);
  final signInUseCase = SignInUseCase(authRepository);
  final signOutUseCase = SignOutUseCase(authRepository);
  final requestPhoneOtpUseCase = RequestPhoneOtpUseCase(authRepository);
  final verifyPhoneOtpUseCase = VerifyPhoneOtpUseCase(authRepository);
  final requestPasswordResetUseCase = RequestPasswordResetUseCase(authRepository);
  final deleteAccountUseCase = DeleteAccountUseCase(authRepository);
  final updateEmailUseCase = UpdateEmailUseCase(authRepository);
  final requestPhoneChangeOtpUseCase = RequestPhoneChangeOtpUseCase(authRepository);
  final verifyPhoneChangeOtpUseCase = VerifyPhoneChangeOtpUseCase(authRepository);
  final submitFeedbackUseCase = SubmitFeedbackUseCase(authRepository);
  final validateImageUseCase = ValidateImageUseCase();
  final runDiagnosisUseCase = RunDiagnosisUseCase(
    inferenceService: mlInferenceService,
    diagnosisRepository: diagnosisRepository,
    scanRepository: scanRepository,
    db: database,
  );
  final getDiseaseExplanationUseCase = GetDiseaseExplanationUseCase(
    DiseaseExplanationRepositoryImpl(database),
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
  final exportScanHistoryUseCase = ExportScanHistoryUseCase(scanRepository);

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
    requestPhoneOtpUseCase: requestPhoneOtpUseCase,
    verifyPhoneOtpUseCase: verifyPhoneOtpUseCase,
    requestPasswordResetUseCase: requestPasswordResetUseCase,
    deleteAccountUseCase: deleteAccountUseCase,
    updateEmailUseCase: updateEmailUseCase,
    requestPhoneChangeOtpUseCase: requestPhoneChangeOtpUseCase,
    verifyPhoneChangeOtpUseCase: verifyPhoneChangeOtpUseCase,
  );

  final connectivityService = ConnectivityService();

  final syncCubit = SyncCubit(
    syncRepository: syncRepository,
    authRepository: authRepository,
    scanRepository: scanRepository,
    connectivityService: connectivityService,
    syncPreferences: SyncPreferences(),
  );
  // Restores the saved preference, and forces it off when there is no
  // session to sync with.
  await syncCubit.loadAutoSyncPreference();

  final accessibilityRepository = AccessibilityRepositoryImpl();
  final getAccessibilitySettingsUseCase = GetAccessibilitySettingsUseCase(accessibilityRepository);
  final saveAccessibilitySettingsUseCase = SaveAccessibilitySettingsUseCase(accessibilityRepository);
  final accessibilityCubit = AccessibilityCubit(
    getAccessibilitySettingsUseCase: getAccessibilitySettingsUseCase,
    saveAccessibilitySettingsUseCase: saveAccessibilitySettingsUseCase,
  );

  runApp(CropCareApp(
    appStateCubit: appStateCubit,
    accessibilityCubit: accessibilityCubit,
    user: user,
    authCubit: authCubit,
    syncCubit: syncCubit,
    getSupportedCropsUseCase: getSupportedCropsUseCase,
    validateImageUseCase: validateImageUseCase,
    runDiagnosisUseCase: runDiagnosisUseCase,
    resolveTreatmentUseCase: resolveTreatmentUseCase,
    getDiseaseExplanationUseCase: getDiseaseExplanationUseCase,
    createEscalationUseCase: createEscalationUseCase,
    getScanHistoryUseCase: getScanHistoryUseCase,
    exportScanHistoryUseCase: exportScanHistoryUseCase,
    submitFeedbackUseCase: submitFeedbackUseCase,
  ));
}
