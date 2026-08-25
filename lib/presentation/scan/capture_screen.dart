import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../application/scan/scan_cubit.dart';
import '../../application/scan/scan_state.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import '../../domain/usecases/diagnosis/validate_image_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../../domain/usecases/scan/capture_scan_use_case.dart';
import '../diagnosis/diagnosis_result_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import 'scan_result_screen.dart';

class CaptureScreen extends StatefulWidget {
  final String cropId;
  final LocalUser user;
  final String? initialTempImagePath;
  final ScanCubit? scanCubit;
  final ImagePicker? imagePicker;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const CaptureScreen({
    super.key,
    this.cropId = 'unknown',
    required this.user,
    this.initialTempImagePath,
    this.scanCubit,
    this.imagePicker,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
  });

  @override
  State<CaptureScreen> createState() => _CaptureScreenState();
}

class _CaptureScreenState extends State<CaptureScreen> {
  late final ImagePicker _picker;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.scanCubit != null) {
      return BlocProvider<ScanCubit>.value(
        value: widget.scanCubit!,
        child: _CaptureView(
          cropId: widget.cropId,
          user: widget.user,
          picker: _picker,
          initialTempImagePath: widget.initialTempImagePath,
          resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
          createEscalationUseCase: widget.createEscalationUseCase,
        ),
      );
    }

    return BlocProvider<ScanCubit>(
      create: (_) => ScanCubit(
        captureScanUseCase: CaptureScanUseCase(
          ScanRepositoryImpl(AppDatabase()),
        ),
        validateImageUseCase: widget.validateImageUseCase,
        runDiagnosisUseCase: widget.runDiagnosisUseCase,
      ),
      child: _CaptureView(
        cropId: widget.cropId,
        user: widget.user,
        picker: _picker,
        initialTempImagePath: widget.initialTempImagePath,
        resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
        createEscalationUseCase: widget.createEscalationUseCase,
      ),
    );
  }
}

class _CaptureView extends StatefulWidget {
  final String cropId;
  final LocalUser user;
  final ImagePicker picker;
  final String? initialTempImagePath;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const _CaptureView({
    required this.cropId,
    required this.user,
    required this.picker,
    this.initialTempImagePath,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
  });

  @override
  State<_CaptureView> createState() => _CaptureViewState();
}

class _CaptureViewState extends State<_CaptureView> {
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

  Future<void> _handleCapture(BuildContext context) async {
    final cubit = context.read<ScanCubit>();
    try {
      final XFile? photo = await widget.picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (photo != null) {
        cubit.photoCaptured(cropId: widget.cropId, tempImagePath: photo.path);
      }
    } catch (_) {
      // In test environments or desktop where native camera UI is unavailable, ignore gracefully
    }
  }

  Future<void> _handleGalleryPick(BuildContext context) async {
    final cubit = context.read<ScanCubit>();
    try {
      final XFile? photo = await widget.picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (photo != null) {
        cubit.photoCaptured(cropId: widget.cropId, tempImagePath: photo.path);
      }
    } catch (_) {
      // In test environments or desktop where native gallery UI is unavailable, ignore gracefully
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('capture_photo')),
        leading: IconButton(
          key: const Key('cancel_scan_button'),
          icon: const Icon(Icons.close),
          tooltip: context.tr('cancel_scan'),
          onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
        ),
      ),
      body: BlocConsumer<ScanCubit, ScanState>(
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
                  resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
                  createEscalationUseCase: widget.createEscalationUseCase,
                ),
              ),
            );
          } else if (state is ScanImageInvalid) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image invalid: ${state.reason}. Please retake.'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is ScanPermissionChecking || state is ScanInitial) {
            return const Center(
              child: CircularProgressIndicator(
                key: Key('capture_loading_indicator'),
              ),
            );
          }

          if (state is ScanPermissionDenied) {
            return Center(
              key: const Key('camera_permission_denied_view'),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 80,
                      color: theme.colorScheme.error,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.tr('camera_permission_title'),
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('camera_permission_desc'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      key: const Key('open_app_settings_button'),
                      icon: const Icon(Icons.settings),
                      label: Text(context.tr('open_app_settings')),
                      onPressed: () {
                        context.read<ScanCubit>().openAppSettings();
                      },
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton(
                      key: const Key('re_request_permission_button'),
                      onPressed: () {
                        context.read<ScanCubit>().requestPermission(
                          widget.cropId,
                        );
                      },
                      child: Text(context.tr('grant_permission')),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      key: const Key('gallery_pick_fallback_button'),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(context.tr('pick_from_gallery')),
                      onPressed: () => _handleGalleryPick(context),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      key: const Key('cancel_scan_permission_button'),
                      icon: const Icon(Icons.home_outlined),
                      label: Text(context.tr('back_to_home')),
                      onPressed: () =>
                          Navigator.of(context).popUntil((route) => route.isFirst),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is ScanCameraReady) {
            return Container(
              key: const Key('camera_ready_view'),
              color: Colors.black,
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.camera,
                          size: 100,
                          color: Colors.white54,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Crop: ${widget.cropId.toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 40,
                    left: 24,
                    right: 24,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        FloatingActionButton(
                          heroTag: 'gallery_pick_fab',
                          key: const Key('gallery_pick_button'),
                          backgroundColor: Colors.white24,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          onPressed: () => _handleGalleryPick(context),
                          child: const Icon(
                            Icons.photo_library_outlined,
                            size: 28,
                          ),
                        ),
                        FloatingActionButton.large(
                          heroTag: 'camera_capture_fab',
                          key: const Key('capture_button'),
                          backgroundColor: theme.colorScheme.primary,
                          onPressed: () => _handleCapture(context),
                          child: const Icon(
                            Icons.camera_alt,
                            size: 36,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 56),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }

          if (state is ScanPhotoCaptured) {
            return Column(
              key: const Key('review_photo_view'),
              children: [
                Expanded(
                  child: Container(
                    color: Colors.black,
                    width: double.infinity,
                    child: Image.file(
                      File(state.tempImagePath),
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const Center(
                        child: Icon(
                          Icons.image,
                          size: 80,
                          color: Colors.white54,
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 16,
                  ),
                  color: theme.colorScheme.surface,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              key: const Key('retake_photo_button'),
                              icon: const Icon(Icons.refresh),
                              label: Text(context.tr('retake')),
                              onPressed: () {
                                context.read<ScanCubit>().retakePhoto();
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton.icon(
                              key: const Key('use_photo_button'),
                              icon: const Icon(Icons.check),
                              label: Text(context.tr('use_photo')),
                              onPressed: () {
                                context.read<ScanCubit>().confirmPhoto(
                                  userId: widget.user.id,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const Key('cancel_scan_review_button'),
                        icon: const Icon(Icons.close, size: 18),
                        label: Text(context.tr('cancel_scan')),
                        onPressed: () => Navigator.of(context)
                            .popUntil((route) => route.isFirst),
                      ),
                    ],
                  ),
                ),
              ],
            );
          }

          if (state is ScanCreating || state is ScanDiagnosing) {
            return const Center(
              child: CircularProgressIndicator(
                key: Key('scan_creating_indicator'),
              ),
            );
          }

          if (state is ScanError) {
            return Center(child: Text('Error: ${state.message}'));
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
