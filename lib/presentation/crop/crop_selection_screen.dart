import 'package:flutter/material.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/usecases/crop/get_supported_crops_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import '../../domain/usecases/diagnosis/validate_image_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../onboarding/localization/localization_provider.dart';
import '../scan/capture_screen.dart';

class CropSelectionScreen extends StatefulWidget {
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final LocalUser user;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const CropSelectionScreen({
    super.key,
    required this.getSupportedCropsUseCase,
    required this.user,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
  });

  @override
  State<CropSelectionScreen> createState() => _CropSelectionScreenState();
}

class _CropSelectionScreenState extends State<CropSelectionScreen> {
  late Future<List<Crop>> _cropsFuture;

  @override
  void initState() {
    super.initState();
    _cropsFuture = widget.getSupportedCropsUseCase();
  }

  @override
  Widget build(BuildContext context) {
    final languageCode = LocalizationProvider.of(context)?.languageCode ?? 'en';
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('select_crop_title')),
        leading: IconButton(
          key: const Key('cancel_crop_selection_button'),
          icon: const Icon(Icons.close),
          tooltip: context.tr('cancel'),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: FutureBuilder<List<Crop>>(
        future: _cropsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final crops = snapshot.data ?? [];
          if (crops.isEmpty) {
            return const Center(child: Text('No crops available'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: crops.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final crop = crops[index];
              final localizedName = crop.getLocalizedName(languageCode);

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  key: Key('crop_tile_${crop.id}'),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  leading: CircleAvatar(
                    backgroundColor: theme.colorScheme.primaryContainer,
                    child: Icon(Icons.grass, color: theme.colorScheme.primary),
                  ),
                  title: Text(
                    localizedName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CaptureScreen(
                          cropId: crop.id,
                          user: widget.user,
                          validateImageUseCase: widget.validateImageUseCase,
                          runDiagnosisUseCase: widget.runDiagnosisUseCase,
                          resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
                          createEscalationUseCase: widget.createEscalationUseCase,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
