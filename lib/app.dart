import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/auth/auth_cubit.dart';
import 'application/onboarding/app_state_cubit.dart';
import 'application/onboarding/app_state_state.dart';
import 'domain/entities/local_user.dart';
import 'domain/usecases/crop/get_supported_crops_use_case.dart';
import 'domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import 'domain/usecases/diagnosis/validate_image_use_case.dart';
import 'domain/usecases/escalation/create_escalation_use_case.dart';
import 'domain/usecases/history/get_scan_history_use_case.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/onboarding/localization/localization_provider.dart';
import 'presentation/onboarding/splash_screen.dart';

class CropCareApp extends StatelessWidget {
  final AppStateCubit appStateCubit;
  final LocalUser user;
  final AuthCubit? authCubit;
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final ValidateImageUseCase validateImageUseCase;
  final RunDiagnosisUseCase runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final GetScanHistoryUseCase? getScanHistoryUseCase;

  const CropCareApp({
    super.key,
    required this.appStateCubit,
    required this.user,
    this.authCubit,
    required this.getSupportedCropsUseCase,
    required this.validateImageUseCase,
    required this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
    this.getScanHistoryUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: appStateCubit,
      child: BlocBuilder<AppStateCubit, AppStateState>(
        builder: (context, state) {
          final isCompleted = state is AppStateOnboardingComplete;

          return LocalizationProvider(
            languageCode: state.languageCode,
            child: MaterialApp(
              title: 'CropCare',
              debugShowCheckedModeBanner: false,
              theme: ThemeData(
                colorScheme: ColorScheme.fromSeed(
                  seedColor: Colors.green,
                  brightness: Brightness.light,
                ),
                useMaterial3: true,
              ),
              home: state is AppStateLoading
                  ? const Scaffold(
                      body: Center(child: CircularProgressIndicator()),
                    )
                  : isCompleted
                      ? HomeScreen(
                          user: user,
                          authCubit: authCubit,
                          getSupportedCropsUseCase: getSupportedCropsUseCase,
                          validateImageUseCase: validateImageUseCase,
                          runDiagnosisUseCase: runDiagnosisUseCase,
                          resolveTreatmentUseCase: resolveTreatmentUseCase,
                          createEscalationUseCase: createEscalationUseCase,
                          getScanHistoryUseCase: getScanHistoryUseCase,
                        )
                      : const SplashScreen(),
            ),
          );
        },
      ),
    );
  }
}
