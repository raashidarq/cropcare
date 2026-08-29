import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'application/auth/auth_cubit.dart';
import 'application/onboarding/app_state_cubit.dart';
import 'application/onboarding/app_state_state.dart';
import 'application/settings/accessibility_cubit.dart';
import 'application/settings/accessibility_state.dart';
import 'application/sync/sync_cubit.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/accessibility_repository_impl.dart';
import 'domain/entities/local_user.dart';
import 'domain/usecases/crop/get_supported_crops_use_case.dart';
import 'domain/usecases/diagnosis/get_disease_explanation_use_case.dart';
import 'domain/usecases/chat/delete_chat_message_use_case.dart';
import 'domain/usecases/chat/get_chat_history_use_case.dart';
import 'domain/usecases/chat/send_chat_message_use_case.dart';
import 'domain/usecases/diagnosis/get_cached_ai_treatment_use_case.dart';
import 'domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart';
import 'domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import 'domain/usecases/diagnosis/validate_image_use_case.dart';
import 'domain/usecases/escalation/create_escalation_use_case.dart';
import 'domain/usecases/feedback/submit_feedback_use_case.dart';
import 'domain/usecases/history/export_scan_history_use_case.dart';
import 'domain/usecases/history/delete_scan_use_case.dart';
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
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetCachedAiTreatmentUseCase? getCachedAiTreatmentUseCase;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final GetScanHistoryUseCase? getScanHistoryUseCase;
  final DeleteScanUseCase? deleteScanUseCase;
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
    this.getLocalTreatmentGuidanceUseCase,
    this.getCachedAiTreatmentUseCase,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.getScanHistoryUseCase,
    this.deleteScanUseCase,
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
        // Only consulted here for theme/language, which legitimately belong
        // at the MaterialApp level. WHICH SCREEN is shown is decided further
        // down, inside _AppRoot's own BlocBuilder - see its doc comment.
        builder: (context, state) {
          return BlocBuilder<AccessibilityCubit, AccessibilityState>(
            builder: (context, accState) {
              final isHighContrast = accState.isHighContrast;
              final textScale = accState.textScaleFactor;

              // Theme is rebuilt per language so the correct script face is
              // primary (see AppTextStyles), and per contrast setting.
              final baseTheme = isHighContrast
                  ? AppTheme.highContrast(state.languageCode)
                  : AppTheme.light(state.languageCode);

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
                  // A single, stable widget - see _AppRoot's own doc comment
                  // for why picking the screen has to happen INSIDE it
                  // rather than out here (TD-033).
                  home: _AppRoot(
                    user: user,
                    authCubit: authCubit,
                    syncCubit: syncCubit,
                    getSupportedCropsUseCase: getSupportedCropsUseCase,
                    validateImageUseCase: validateImageUseCase,
                    runDiagnosisUseCase: runDiagnosisUseCase,
                    resolveTreatmentUseCase: resolveTreatmentUseCase,
                    getLocalTreatmentGuidanceUseCase: getLocalTreatmentGuidanceUseCase,
                    getCachedAiTreatmentUseCase: getCachedAiTreatmentUseCase,
                    getChatHistoryUseCase: getChatHistoryUseCase,
                    sendChatMessageUseCase: sendChatMessageUseCase,
                    deleteChatMessageUseCase: deleteChatMessageUseCase,
                    getDiseaseExplanationUseCase: getDiseaseExplanationUseCase,
                    createEscalationUseCase: createEscalationUseCase,
                    getScanHistoryUseCase: getScanHistoryUseCase,
                    deleteScanUseCase: deleteScanUseCase,
                    exportScanHistoryUseCase: exportScanHistoryUseCase,
                    submitFeedbackUseCase: submitFeedbackUseCase,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// Decides which screen is on the Navigator's root route, and is the
/// FIX for a real, live bug (TD-033): [MaterialApp.home] used to be set
/// directly to `state is AppStateLoading ? Spinner : isCompleted ? HomeScreen(...)
/// : SplashScreen()`, computed by [CropCareApp]'s own `build()`. That reads
/// as reactive, but it is not, reliably: once the root route has been built
/// once, MaterialApp handing the Navigator a *different* `home` widget on a
/// later ancestor rebuild is not guaranteed to make the Route rebuild its
/// displayed content — Route/Overlay reconciliation is a different, murkier
/// mechanism than an ordinary widget update. In practice this meant
/// finishing onboarding (or any other AppStateCubit transition reached after
/// the first frame) could leave the OLD screen on screen forever, with every
/// button on it visibly doing nothing — because the app itself was, all the
/// way underneath, actually in the new state.
///
/// The fix: `home` is now this single, stable widget, constructed the same
/// way on every rebuild. It owns its own `BlocBuilder&lt;AppStateCubit,
/// AppStateState&gt;`, which subscribes directly at this point in the tree
/// — the same reliable
/// mechanism every other screen in this app already uses to react to a
/// Cubit. That subscription rebuilds this widget's own subtree the instant
/// AppStateCubit emits, regardless of what the Navigator or any ancestor
/// does, which is what a Route swap was never guaranteed to do.
class _AppRoot extends StatelessWidget {
  final LocalUser user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final ValidateImageUseCase validateImageUseCase;
  final RunDiagnosisUseCase runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetCachedAiTreatmentUseCase? getCachedAiTreatmentUseCase;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final GetScanHistoryUseCase? getScanHistoryUseCase;
  final DeleteScanUseCase? deleteScanUseCase;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  const _AppRoot({
    required this.user,
    this.authCubit,
    this.syncCubit,
    required this.getSupportedCropsUseCase,
    required this.validateImageUseCase,
    required this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
    this.getCachedAiTreatmentUseCase,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
    this.getScanHistoryUseCase,
    this.deleteScanUseCase,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppStateCubit, AppStateState>(
      builder: (context, state) {
        if (state is AppStateLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (state is AppStateOnboardingComplete) {
          return HomeScreen(
            user: user,
            authCubit: authCubit,
            syncCubit: syncCubit,
            getSupportedCropsUseCase: getSupportedCropsUseCase,
            validateImageUseCase: validateImageUseCase,
            runDiagnosisUseCase: runDiagnosisUseCase,
            resolveTreatmentUseCase: resolveTreatmentUseCase,
            getLocalTreatmentGuidanceUseCase: getLocalTreatmentGuidanceUseCase,
            getCachedAiTreatmentUseCase: getCachedAiTreatmentUseCase,
            getChatHistoryUseCase: getChatHistoryUseCase,
            sendChatMessageUseCase: sendChatMessageUseCase,
            deleteChatMessageUseCase: deleteChatMessageUseCase,
            getDiseaseExplanationUseCase: getDiseaseExplanationUseCase,
            createEscalationUseCase: createEscalationUseCase,
            getScanHistoryUseCase: getScanHistoryUseCase,
            deleteScanUseCase: deleteScanUseCase,
            exportScanHistoryUseCase: exportScanHistoryUseCase,
            submitFeedbackUseCase: submitFeedbackUseCase,
            openAccountOnLaunch: state.openAccountOnLaunch,
          );
        }
        return const SplashScreen();
      },
    );
  }
}
