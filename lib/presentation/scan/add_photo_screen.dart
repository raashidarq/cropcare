// lib/presentation/scan/add_photo_screen.dart
//
// New Scan entry screen providing Camera and Gallery photo selection,
// along with a purely informational display of all AI-supported crops.

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/crop.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/crop/get_supported_crops_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import '../../domain/usecases/diagnosis/validate_image_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../onboarding/localization/localization_provider.dart';
import 'capture_screen.dart';

class AddPhotoScreen extends StatefulWidget {
  final LocalUser user;
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final ImagePicker? imagePicker;

  const AddPhotoScreen({
    super.key,
    required this.user,
    required this.getSupportedCropsUseCase,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
    this.imagePicker,
  });

  @override
  State<AddPhotoScreen> createState() => _AddPhotoScreenState();
}

class _AddPhotoScreenState extends State<AddPhotoScreen> {
  late final ImagePicker _picker;
  late final Future<List<Crop>> _cropsFuture;

  @override
  void initState() {
    super.initState();
    _picker = widget.imagePicker ?? ImagePicker();
    _cropsFuture = widget.getSupportedCropsUseCase();
  }

  Future<void> _handleGalleryPick(BuildContext context) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );

      if (photo == null) return;
      if (!context.mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CaptureScreen(
            user: widget.user,
            initialTempImagePath: photo.path,
            validateImageUseCase: widget.validateImageUseCase,
            runDiagnosisUseCase: widget.runDiagnosisUseCase,
            resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
            createEscalationUseCase: widget.createEscalationUseCase,
            imagePicker: _picker,
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showPermissionDeniedDialog(context);
    }
  }

  void _showPermissionDeniedDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        key: const Key('gallery_permission_dialog'),
        title: Text(context.tr('gallery_permission_denied_title')),
        content: Text(context.tr('gallery_permission_denied_desc')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(context.tr('cancel')),
          ),
          ElevatedButton(
            key: const Key('open_app_settings_dialog_button'),
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: Text(context.tr('open_settings')),
          ),
        ],
      ),
    );
  }

  void _navigateToCamera(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaptureScreen(
          user: widget.user,
          validateImageUseCase: widget.validateImageUseCase,
          runDiagnosisUseCase: widget.runDiagnosisUseCase,
          resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
          createEscalationUseCase: widget.createEscalationUseCase,
          imagePicker: _picker,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('add_photo_title')),
        leading: IconButton(
          key: const Key('cancel_add_photo_button'),
          icon: const Icon(Icons.close),
          tooltip: context.tr('cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Subtitle ──────────────────────────────────────────
              Text(
                context.tr('add_photo_subtitle'),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),

              // ── Action 1: Take Photo ─────────────────────────────────────
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
                child: InkWell(
                  key: const Key('add_photo_camera_button'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _navigateToCamera(context),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.primary,
                          child: const Icon(
                            Icons.camera_alt_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('take_photo_btn'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('take_photo_desc'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Action 2: Choose from Gallery ────────────────────────────
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                  ),
                ),
                color: theme.colorScheme.surface,
                child: InkWell(
                  key: const Key('add_photo_gallery_button'),
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _handleGalleryPick(context),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: theme.colorScheme.secondaryContainer,
                          child: Icon(
                            Icons.photo_library_rounded,
                            color: theme.colorScheme.onSecondaryContainer,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr('choose_gallery_btn'),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                context.tr('choose_gallery_desc'),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 18,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // ── Informational Supported Crops Section ────────────────────
              Row(
                children: [
                  Icon(
                    Icons.eco_rounded,
                    size: 20,
                    color: Colors.green.shade700,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    context.tr('supported_crops_label'),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.tr('supported_crops_desc'),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),

              FutureBuilder<List<Crop>>(
                future: _cropsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    );
                  }

                  final crops = snapshot.data ?? [];
                  if (crops.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return Container(
                    key: const Key('supported_crops_info_grid'),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: crops.map((crop) {
                        final localizedName = crop.getLocalizedName(languageCode);
                        return Chip(
                          key: Key('supported_crop_chip_${crop.id}'),
                          avatar: const Icon(
                            Icons.check_circle_outline,
                            size: 14,
                            color: Colors.green,
                          ),
                          label: Text(
                            localizedName,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          backgroundColor: theme.colorScheme.surface,
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                          ),
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
