// lib/presentation/scan/capture_screen.dart
//
// Camera-first capture.
//
// The screen opens straight into a live viewfinder with the gallery available
// as a secondary control, rather than making the farmer choose "camera or
// gallery?" on a separate screen first. That choice screen was a full stop in
// the middle of the app's primary task; camera-first is the convention every
// comparable scanning app uses (Google Lens, PlantNet, Plantix) because the
// common case — "I am standing in front of a sick plant" — should be zero
// taps away from a shutter button.

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/scan/scan_cubit.dart';
import '../../application/scan/scan_state.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/app_haptics.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/diagnosis/get_disease_explanation_use_case.dart';
import '../../domain/usecases/chat/delete_chat_message_use_case.dart';
import '../../domain/usecases/chat/get_chat_history_use_case.dart';
import '../../domain/usecases/chat/send_chat_message_use_case.dart';
import '../../domain/usecases/diagnosis/get_cached_ai_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/get_local_treatment_guidance_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import '../../domain/usecases/diagnosis/validate_image_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../../domain/usecases/scan/capture_scan_use_case.dart';
import '../../services/camera_service.dart';
import '../diagnosis/diagnosis_result_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../shared/widgets/app_components.dart';
import '../shared/widgets/app_state_views.dart';
import 'scan_result_screen.dart';
import 'widgets/camera_preview_view.dart';

class CaptureScreen extends StatefulWidget {
  final String cropId;
  final LocalUser user;
  final String? initialTempImagePath;
  final ScanCubit? scanCubit;
  final ImagePicker? imagePicker;
  final CameraService? cameraService;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetCachedAiTreatmentUseCase? getCachedAiTreatmentUseCase;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const CaptureScreen({
    super.key,
    this.cropId = 'unknown',
    required this.user,
    this.initialTempImagePath,
    this.scanCubit,
    this.imagePicker,
    this.cameraService,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
    this.getCachedAiTreatmentUseCase,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late final ImagePicker _picker;

  // Fallback wiring for when no ScanCubit is injected (tests, direct push).
  // Static and lazy because the previous inline `AppDatabase()` opened a new,
  // never-closed SQLite connection every time this screen was built — a leak
  // that grows with each scan and can contend with the app's real connection.
  static AppDatabase? _fallbackDb;
  static CaptureScanUseCase? _fallbackUseCase;

  static CaptureScanUseCase _fallbackCaptureUseCase() {
    final db = _fallbackDb ??= AppDatabase();
    return _fallbackUseCase ??= CaptureScanUseCase(ScanRepositoryImpl(db));
  }

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    final view = _CaptureView(
      cropId: widget.cropId,
      user: widget.user,
      picker: _picker,
      cameraService: widget.cameraService ?? const DefaultCameraService(),
      initialTempImagePath: widget.initialTempImagePath,
      validateImageUseCase: widget.validateImageUseCase,
      runDiagnosisUseCase: widget.runDiagnosisUseCase,
      resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
      getLocalTreatmentGuidanceUseCase: widget.getLocalTreatmentGuidanceUseCase,
      getCachedAiTreatmentUseCase: widget.getCachedAiTreatmentUseCase,
      getChatHistoryUseCase: widget.getChatHistoryUseCase,
      sendChatMessageUseCase: widget.sendChatMessageUseCase,
      deleteChatMessageUseCase: widget.deleteChatMessageUseCase,
      getDiseaseExplanationUseCase: widget.getDiseaseExplanationUseCase,
      createEscalationUseCase: widget.createEscalationUseCase,
    );

    if (widget.scanCubit != null) {
      return BlocProvider<ScanCubit>.value(value: widget.scanCubit!, child: view);
    }

    return BlocProvider<ScanCubit>(
      create: (_) => ScanCubit(
        captureScanUseCase: _fallbackCaptureUseCase(),
        validateImageUseCase: widget.validateImageUseCase,
        runDiagnosisUseCase: widget.runDiagnosisUseCase,
      ),
      child: view,
    );
  }
}

/// Maps a stored `image_validation.rejection_reason` token to the localization
/// key explaining, in plain language, what to do differently.
String _rejectionMessageKey(String reason) {
  switch (reason) {
    case 'NO_PLANT_DETECTED':
      return 'image_rejected_no_plant';
    case 'BLURRY':
      return 'image_rejected_blurry';
    case 'TOO_DARK':
      return 'image_rejected_too_dark';
    case 'TOO_BRIGHT':
      return 'image_rejected_too_bright';
    case 'LOW_RESOLUTION':
      return 'image_rejected_low_resolution';
    case 'UNSUPPORTED_FORMAT':
    case 'FILE_NOT_FOUND':
      return 'image_rejected_unsupported_format';
    default:
      return 'image_rejected_generic';
  }
}

class _CaptureView extends StatefulWidget {
  final String cropId;
  final LocalUser user;
  final ImagePicker picker;
  final CameraService cameraService;
  final String? initialTempImagePath;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final GetLocalTreatmentGuidanceUseCase? getLocalTreatmentGuidanceUseCase;
  final GetCachedAiTreatmentUseCase? getCachedAiTreatmentUseCase;
  final GetChatHistoryUseCase? getChatHistoryUseCase;
  final SendChatMessageUseCase? sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;
  final GetDiseaseExplanationUseCase? getDiseaseExplanationUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const _CaptureView({
    required this.cropId,
    required this.user,
    required this.picker,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    required this.cameraService,
    this.initialTempImagePath,
    this.resolveTreatmentUseCase,
    this.getLocalTreatmentGuidanceUseCase,
    this.getCachedAiTreatmentUseCase,
    this.getChatHistoryUseCase,
    this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
    this.getDiseaseExplanationUseCase,
    this.createEscalationUseCase,
  });

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
  /// Supplied by the viewfinder once the preview is live; null while it is
  /// initialising or unavailable, which is what disables the shutter.
  Future<XFile?> Function()? _capture;
  bool _capturing = false;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ScanCubit>();
    if (widget.initialTempImagePath != null) {
      cubit.photoCaptured(
        cropId: widget.cropId,
        tempImagePath: widget.initialTempImagePath!,
      );
    } else if (cubit.state is ScanInitial) {
      cubit.initializePermission(widget.cropId);
    }
  }

  Future<void> _handleShutter() async {
    final capture = _capture;
    if (capture == null || _capturing) return;

    final cubit = context.read<ScanCubit>();
    // Resolved before the await so the BuildContext is not used afterwards.
    final failureMessage = context.tr('capture_failed_msg');

    setState(() => _capturing = true);
    try {
      final photo = await capture();
      if (photo != null && mounted) {
        // Confirms the shot by feel — the screen is often unreadable in the
        // sun at the moment the photo is taken.
        AppHaptics.capture(context);
        cubit.photoCaptured(cropId: widget.cropId, tempImagePath: photo.path);
      }
    } catch (_) {
      // Recoverable (CameraException, hardware busy, ...): tell the user and
      // let them retry, rather than the previous blanket `catch (_) {}` which
      // left the screen looking frozen.
      _showError(failureMessage);
    } finally {
      if (mounted) setState(() => _capturing = false);
    }
  }

  Future<void> _handleGalleryPick() async {
    final cubit = context.read<ScanCubit>();
    final failureMessage = context.tr('gallery_unavailable_msg');

    try {
      final photo = await widget.picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (photo != null && mounted) {
        cubit.photoCaptured(cropId: widget.cropId, tempImagePath: photo.path);
      }
    } catch (_) {
      // Previously swallowed silently, so on a device without a gallery app
      // the button simply did nothing and the farmer had no idea why.
      _showError(failureMessage);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _exit() => Navigator.of(context).popUntil((route) => route.isFirst);

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ScanCubit, ScanState>(
      listener: (context, state) {
        if (state is ScanCreated) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ScanResultScreen(scan: state.scan),
            ),
          );
        } else if (state is ScanDiagnosed) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => DiagnosisResultScreen(
                scan: state.scan,
                diagnosis: state.diagnosis,
                // Rebuilds a fresh viewfinder. This screen replaced itself to
                // show the result, so it is gone by now - the callback takes
                // the result screen's own context to navigate with.
                onScanAgain: (ctx) => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => CaptureScreen(
                      user: widget.user,
                      validateImageUseCase: widget.validateImageUseCase,
                      runDiagnosisUseCase: widget.runDiagnosisUseCase,
                      resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
                      getLocalTreatmentGuidanceUseCase:
                          widget.getLocalTreatmentGuidanceUseCase,
                      getCachedAiTreatmentUseCase:
                          widget.getCachedAiTreatmentUseCase,
                      getChatHistoryUseCase: widget.getChatHistoryUseCase,
                      sendChatMessageUseCase: widget.sendChatMessageUseCase,
                      deleteChatMessageUseCase: widget.deleteChatMessageUseCase,
                      getDiseaseExplanationUseCase:
                          widget.getDiseaseExplanationUseCase,
                      createEscalationUseCase: widget.createEscalationUseCase,
                    ),
                  ),
                ),
                resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
                getLocalTreatmentGuidanceUseCase: widget.getLocalTreatmentGuidanceUseCase,
                getCachedAiTreatmentUseCase: widget.getCachedAiTreatmentUseCase,
                getChatHistoryUseCase: widget.getChatHistoryUseCase,
                sendChatMessageUseCase: widget.sendChatMessageUseCase,
                deleteChatMessageUseCase: widget.deleteChatMessageUseCase,
        getDiseaseExplanationUseCase: widget.getDiseaseExplanationUseCase,
                createEscalationUseCase: widget.createEscalationUseCase,
              ),
            ),
          );
        }
        // ScanImageInvalid renders as a full state below rather than a
        // SnackBar: the farmer needs to understand what was wrong with the
        // photo and retake it, which is more than a transient toast carries.
      },
      builder: (context, state) {
        // Camera states are full-bleed dark; everything else is a normal
        // light surface. Keeping them visually distinct makes it obvious
        // when the camera is live.
        final isViewfinder = state is ScanCameraReady;
        final isReview = state is ScanPhotoCaptured;

        return Scaffold(
          backgroundColor:
              isViewfinder || isReview ? Colors.black : AppColors.background,
          extendBodyBehindAppBar: isViewfinder || isReview,
          appBar: AppBar(
            backgroundColor:
                isViewfinder || isReview ? Colors.transparent : null,
            foregroundColor:
                isViewfinder || isReview ? Colors.white : null,
            elevation: 0,
            title: isViewfinder || isReview
                ? null
                : Text(context.tr('capture_photo')),
            leading: IconButton(
              key: const Key('cancel_scan_button'),
              icon: const Icon(Icons.close),
              tooltip: context.tr('cancel_scan'),
              onPressed: _exit,
            ),
          ),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ScanState state) {
    if (state is ScanPermissionChecking || state is ScanInitial) {
      return AppLoadingView(
        key: const Key('capture_loading_indicator'),
        message: context.tr('opening_camera'),
      );
    }

    if (state is ScanPermissionDenied) {
      return _PermissionDeniedView(
        cropId: widget.cropId,
        onGalleryPick: _handleGalleryPick,
        onExit: _exit,
      );
    }

    if (state is ScanCameraReady) {
      return _ViewfinderView(
        cameraService: widget.cameraService,
        capturing: _capturing,
        canCapture: _capture != null,
        onCaptureReady: (fn) {
          if (!mounted) return;
          setState(() => _capture = fn);
        },
        onShutter: _handleShutter,
        onGalleryPick: _handleGalleryPick,
      );
    }

    if (state is ScanPhotoCaptured) {
      return _ReviewView(
        imagePath: state.tempImagePath,
        onRetake: () => context.read<ScanCubit>().retakePhoto(),
        onUse: () =>
            context.read<ScanCubit>().confirmPhoto(userId: widget.user.id),
        onCancel: _exit,
      );
    }

    if (state is ScanCreating || state is ScanDiagnosing) {
      return _AnalyzingView(
        key: const Key('scan_creating_indicator'),
        message: context.tr(
          state is ScanDiagnosing ? 'analyzing' : 'saving_scan',
        ),
      );
    }

    if (state is ScanImageInvalid) {
      AppHaptics.failure(context);
      return AppErrorView(
        key: const Key('scan_image_invalid_view'),
        icon: Icons.photo_camera_outlined,
        title: context.tr('image_rejected_title'),
        message: context.tr(_rejectionMessageKey(state.reason)),
        actionLabel: context.tr('retake_photo'),
        onAction: () =>
            context.read<ScanCubit>().initializePermission(widget.cropId),
      );
    }

    if (state is ScanError) {
      // Never render the raw exception as the message — it is untranslated
      // and meaningless to a farmer. It stays available under "Show details".
      return AppErrorView(
        title: context.tr('scan_failed_title'),
        message: context.tr('scan_failed_msg'),
        technicalDetail: state.message,
        actionLabel: context.tr('retake_photo'),
        onAction: () =>
            context.read<ScanCubit>().initializePermission(widget.cropId),
      );
    }

    return const SizedBox.shrink();
  }
}

// =============================================================================
// Viewfinder
// =============================================================================

class _ViewfinderView extends StatelessWidget {
  final CameraService cameraService;
  final bool capturing;
  final bool canCapture;
  final ValueChanged<Future<XFile?> Function()?> onCaptureReady;
  final VoidCallback onShutter;
  final VoidCallback onGalleryPick;

  const _ViewfinderView({
    required this.cameraService,
    required this.capturing,
    required this.canCapture,
    required this.onCaptureReady,
    required this.onShutter,
    required this.onGalleryPick,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: const Key('camera_ready_view'),
      fit: StackFit.expand,
      children: [
        CameraPreviewView(
          cameraService: cameraService,
          hint: context.tr('camera_frame_hint'),
          unavailableMessage: context.tr('camera_unavailable_msg'),
          galleryActionLabel: context.tr('pick_from_gallery'),
          onUseGallery: onGalleryPick,
          onCaptureReady: onCaptureReady,
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _ShutterBar(
            capturing: capturing,
            canCapture: canCapture,
            onShutter: onShutter,
            onGalleryPick: onGalleryPick,
          ),
        ),
      ],
    );
  }
}

/// Bottom control bar: gallery on the left, shutter centred, symmetric spacer
/// on the right so the shutter sits truly centre — the natural thumb position.
class _ShutterBar extends StatelessWidget {
  final bool capturing;
  final bool canCapture;
  final VoidCallback onShutter;
  final VoidCallback onGalleryPick;

  const _ShutterBar({
    required this.capturing,
    required this.canCapture,
    required this.onShutter,
    required this.onGalleryPick,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _GlassButton(
              key: const Key('gallery_pick_button'),
              icon: Icons.photo_library_outlined,
              tooltip: context.tr('pick_from_gallery'),
              onPressed: onGalleryPick,
            ),
            _ShutterButton(
              capturing: capturing,
              enabled: canCapture && !capturing,
              onPressed: onShutter,
            ),
            // Keeps the shutter optically centred without adding a control
            // the farmer does not need.
            const SizedBox(width: 52),
          ],
        ),
      ),
    );
  }
}

class _ShutterButton extends StatelessWidget {
  final bool capturing;
  final bool enabled;
  final VoidCallback onPressed;

  const _ShutterButton({
    required this.capturing,
    required this.enabled,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: context.tr('capture_photo'),
      child: GestureDetector(
        key: const Key('capture_button'),
        onTap: enabled ? onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            // Classic camera shutter: white ring, filled core. Instantly
            // recognisable, and large enough to hit without looking.
            border: Border.all(
              color: enabled ? Colors.white : Colors.white38,
              width: 4,
            ),
          ),
          child: Center(
            child: capturing
                ? const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.white,
                    ),
                  )
                : Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: enabled ? Colors.white : Colors.white38,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _GlassButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        child: Material(
          color: Colors.white.withValues(alpha: 0.18),
          shape: const CircleBorder(),
          child: InkWell(
            onTap: onPressed,
            customBorder: const CircleBorder(),
            child: const SizedBox(
              width: 52,
              height: 52,
              child: Icon(Icons.photo_library_outlined, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Review
// =============================================================================

class _ReviewView extends StatelessWidget {
  final String imagePath;
  final VoidCallback onRetake;
  final VoidCallback onUse;
  final VoidCallback onCancel;

  const _ReviewView({
    required this.imagePath,
    required this.onRetake,
    required this.onUse,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      key: const Key('review_photo_view'),
      children: [
        Expanded(
          child: SizedBox(
            width: double.infinity,
            child: Image.file(
              File(imagePath),
              fit: BoxFit.contain,
              // Review only needs screen resolution, not the camera's full
              // sensor resolution.
              cacheWidth: (MediaQuery.sizeOf(context).width *
                      MediaQuery.devicePixelRatioOf(context))
                  .round(),
              errorBuilder: (_, _, _) => const Center(
                child: Icon(Icons.broken_image_outlined,
                    size: 72, color: Colors.white54),
              ),
            ),
          ),
        ),
        // Actions sit on a solid sheet rather than floating over the photo,
        // so they never land on an unpredictable background.
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.vertical(top: AppRadius.lgRadius),
          ),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  context.tr('review_photo_prompt'),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.smPlus),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: const Key('retake_photo_button'),
                        icon: const Icon(Icons.refresh_rounded),
                        label: Text(context.tr('retake')),
                        onPressed: onRetake,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.smPlus),
                    Expanded(
                      // Primary action gets the filled treatment and sits on
                      // the right, where the thumb naturally lands.
                      flex: 2,
                      child: ElevatedButton.icon(
                        key: const Key('use_photo_button'),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(context.tr('use_photo')),
                        onPressed: onUse,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  key: const Key('cancel_scan_review_button'),
                  onPressed: onCancel,
                  child: Text(context.tr('cancel_scan')),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Analyzing
// =============================================================================

class _AnalyzingView extends StatelessWidget {
  final String message;

  const _AnalyzingView({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              context.tr('analyzing_hint'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Permission denied
// =============================================================================

class _PermissionDeniedView extends StatelessWidget {
  final String cropId;
  final VoidCallback onGalleryPick;
  final VoidCallback onExit;

  const _PermissionDeniedView({
    required this.cropId,
    required this.onGalleryPick,
    required this.onExit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      key: const Key('camera_permission_denied_view'),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const SizedBox(height: AppSpacing.lg),
          Container(
            width: 88,
            height: 88,
            decoration: const BoxDecoration(
              color: AppColors.warningContainer,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_camera_outlined,
              size: 44,
              color: AppColors.warning,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.tr('camera_permission_title'),
            style: theme.textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            context.tr('camera_permission_desc'),
            style: theme.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              key: const Key('re_request_permission_button'),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(context.tr('grant_permission')),
              onPressed: () =>
                  context.read<ScanCubit>().requestPermission(cropId),
            ),
          ),
          const SizedBox(height: AppSpacing.smPlus),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              key: const Key('open_app_settings_button'),
              icon: const Icon(Icons.settings_outlined),
              label: Text(context.tr('open_app_settings')),
              onPressed: () => context.read<ScanCubit>().openAppSettings(),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Gallery remains a first-class path: a farmer who declined camera
          // access can still get a diagnosis from an existing photo.
          AppActionTile(
            key: const Key('gallery_pick_fallback_button'),
            icon: Icons.photo_library_outlined,
            title: context.tr('pick_from_gallery'),
            subtitle: context.tr('choose_gallery_desc'),
            onTap: onGalleryPick,
          ),
          const SizedBox(height: AppSpacing.smPlus),
          TextButton.icon(
            key: const Key('cancel_scan_permission_button'),
            icon: const Icon(Icons.home_outlined),
            label: Text(context.tr('back_to_home')),
            onPressed: onExit,
          ),
        ],
      ),
    );
  }
}
