import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/auth/auth_cubit.dart';
import 'application/onboarding/app_state_cubit.dart';
import 'application/onboarding/app_state_state.dart';
import 'application/settings/accessibility_cubit.dart';
import 'application/settings/accessibility_state.dart';
import 'application/sync/sync_cubit.dart';
import 'data/repositories/accessibility_repository_impl.dart';
import 'domain/entities/local_user.dart';
import 'domain/usecases/crop/get_supported_crops_use_case.dart';
import 'domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import 'domain/usecases/diagnosis/validate_image_use_case.dart';
import 'domain/usecases/escalation/create_escalation_use_case.dart';
import 'domain/usecases/feedback/submit_feedback_use_case.dart';
import 'domain/usecases/history/export_scan_history_use_case.dart';
import 'domain/usecases/history/get_scan_history_use_case.dart';
import 'domain/usecases/settings/get_accessibility_settings_use_case.dart';
import 'domain/usecases/settings/save_accessibility_settings_use_case.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/onboarding/localization/localization_provider.dart';
import 'presentation/onboarding/splash_screen.dart';

class CropCareApp extends StatelessWidget {
  final AppStateCubit appStateCubit;
  final AccessibilityCubit? accessibilityCubit;
  final LocalUser user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final ValidateImageUseCase validateImageUseCase;
  final RunDiagnosisUseCase runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final GetScanHistoryUseCase? getScanHistoryUseCase;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  const CropCareApp({
    super.key,
    required this.appStateCubit,
    this.accessibilityCubit,
    required this.user,
    this.authCubit,
    this.syncCubit,
    required this.getSupportedCropsUseCase,
    required this.validateImageUseCase,
    required this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
    this.getScanHistoryUseCase,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
  });

  @override
  Widget build(BuildContext context) {
    final accRepository = AccessibilityRepositoryImpl();
    final accCubit = accessibilityCubit ??
        AccessibilityCubit(
          getAccessibilitySettingsUseCase: GetAccessibilitySettingsUseCase(accRepository),
          saveAccessibilitySettingsUseCase: SaveAccessibilitySettingsUseCase(accRepository),
        );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: appStateCubit),
        BlocProvider.value(value: accCubit),
      ],
      child: BlocBuilder<AppStateCubit, AppStateState>(
        builder: (context, state) {
          final isCompleted = state is AppStateOnboardingComplete;

          return BlocBuilder<AccessibilityCubit, AccessibilityState>(
            builder: (context, accState) {
              final isHighContrast = accState.isHighContrast;
              final textScale = accState.textScaleFactor;

              final baseTheme = ThemeData(
                colorScheme: isHighContrast
                    ? ColorScheme.fromSeed(
                        seedColor: Colors.green.shade900,
                        contrastLevel: 1.0,
                        brightness: Brightness.light,
                      )
                    : ColorScheme.fromSeed(
                        seedColor: Colors.green,
                        brightness: Brightness.light,
                      ),
                useMaterial3: true,
              );

              return LocalizationProvider(
                languageCode: state.languageCode,
                child: MaterialApp(
                  title: 'CropCare',
                  debugShowCheckedModeBanner: false,
                  theme: baseTheme,
                  builder: (context, child) {
                    final mediaQuery = MediaQuery.of(context);
                    return MediaQuery(
                      data: mediaQuery.copyWith(
                        textScaler: TextScaler.linear(textScale),
                      ),
                      child: child ?? const SizedBox.shrink(),
                    );
                  },
                  home: state is AppStateLoading
                      ? const Scaffold(
                          body: Center(child: CircularProgressIndicator()),
                        )
                      : isCompleted
                          ? HomeScreen(
                              user: user,
                              authCubit: authCubit,
                              syncCubit: syncCubit,
                              getSupportedCropsUseCase: getSupportedCropsUseCase,
                              validateImageUseCase: validateImageUseCase,
                              runDiagnosisUseCase: runDiagnosisUseCase,
                              resolveTreatmentUseCase: resolveTreatmentUseCase,
                              createEscalationUseCase: createEscalationUseCase,
                              getScanHistoryUseCase: getScanHistoryUseCase,
                              exportScanHistoryUseCase: exportScanHistoryUseCase,
                              submitFeedbackUseCase: submitFeedbackUseCase,
                            )
                          : const SplashScreen(),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
