// lib/presentation/home/home_screen.dart
//
// Home screen displaying hero scan action and an embedded past scan history section.

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/history/history_cubit.dart';
import '../../application/history/history_state.dart';
import '../../data/local/database/app_database.dart';
import '../../data/repositories/scan_repository_impl.dart';
import '../../domain/entities/crop.dart';
import '../../domain/entities/local_user.dart';
import '../../domain/entities/scan.dart';
import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/crop_repository.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/usecases/crop/get_supported_crops_use_case.dart';
import '../../domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import '../../domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import '../../domain/usecases/diagnosis/validate_image_use_case.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import '../../domain/usecases/history/get_scan_history_use_case.dart';
import '../crop/crop_selection_screen.dart';
import '../diagnosis/diagnosis_result_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../onboarding/widgets/change_language_dialog.dart';
import '../scan/scan_result_screen.dart';
import '../settings/settings_screen.dart';

class _FallbackCropRepository implements CropRepository {
  @override
  Future<List<Crop>> getSupportedCrops() async => [
        const Crop(
          id: 'tomato',
          nameEn: 'Tomato',
          nameSi: 'තක්කාලි',
          nameTa: 'தக்காளி',
        ),
        const Crop(
          id: 'chili',
          nameEn: 'Chili',
          nameSi: 'මිරිස්',
          nameTa: 'මිளகாய்',
        ),
      ];
}

class _FallbackScanRepository implements ScanRepository {
  @override
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {}

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => [];
}

class HomeScreen extends StatefulWidget {
  final LocalUser? user;
  final GetSupportedCropsUseCase? getSupportedCropsUseCase;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final GetScanHistoryUseCase? getScanHistoryUseCase;

  const HomeScreen({
    super.key,
    this.user,
    this.getSupportedCropsUseCase,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
    this.getScanHistoryUseCase,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final LocalUser _user;
  late final GetSupportedCropsUseCase _getSupportedCropsUseCase;
  late final GetScanHistoryUseCase _getScanHistoryUseCase;

  @override
  void initState() {
    super.initState();
    _user = widget.user ??
        LocalUser(
          id: 'guest-default',
          isGuest: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
    _getSupportedCropsUseCase = widget.getSupportedCropsUseCase ??
        GetSupportedCropsUseCase(_FallbackCropRepository());
    _getScanHistoryUseCase = widget.getScanHistoryUseCase ??
        GetScanHistoryUseCase(_FallbackScanRepository());
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) => HistoryCubit(
        getScanHistoryUseCase: _getScanHistoryUseCase,
      )..loadHistory(),
      child: _HomeScreenView(
        user: _user,
        getSupportedCropsUseCase: _getSupportedCropsUseCase,
        validateImageUseCase: widget.validateImageUseCase,
        runDiagnosisUseCase: widget.runDiagnosisUseCase,
        resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
        createEscalationUseCase: widget.createEscalationUseCase,
      ),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  final LocalUser user;
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const _HomeScreenView({
    required this.user,
    required this.getSupportedCropsUseCase,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('home_title')),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('home_settings_icon'),
            icon: const Icon(Icons.settings),
            tooltip: context.tr('settings_title'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SettingsScreen(),
                ),
              );
            },
          ),
          IconButton(
            key: const Key('home_change_language_icon'),
            icon: const Icon(Icons.language),
            tooltip: context.tr('change_language'),
            onPressed: () => ChangeLanguageDialog.show(context),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await context.read<HistoryCubit>().loadHistory();
        },
        child: CustomScrollView(
          slivers: [
            // ── 1. Hero Card: Welcome & Scan Now ───────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: _HeroScanCard(
                  user: user,
                  onStartScan: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CropSelectionScreen(
                          getSupportedCropsUseCase: getSupportedCropsUseCase,
                          user: user,
                          validateImageUseCase: validateImageUseCase,
                          runDiagnosisUseCase: runDiagnosisUseCase,
                          resolveTreatmentUseCase: resolveTreatmentUseCase,
                          createEscalationUseCase: createEscalationUseCase,
                        ),
                      ),
                    );
                    // Refresh history upon return
                    if (context.mounted) {
                      context.read<HistoryCubit>().loadHistory();
                    }
                  },
                ),
              ),
            ),

            // ── 2. Embedded Scan History Section Header ────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _HistoryHeaderAndFilters(),
              ),
            ),

            // ── 3. History List Items ──────────────────────────────────────
            _HistoryListSliver(
              resolveTreatmentUseCase: resolveTreatmentUseCase,
              createEscalationUseCase: createEscalationUseCase,
            ),

            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Hero Scan Card
// =============================================================================

class _HeroScanCard extends StatelessWidget {
  final LocalUser user;
  final VoidCallback onStartScan;

  const _HeroScanCard({
    required this.user,
    required this.onStartScan,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary,
                  child: const Icon(Icons.eco, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home_welcome'),
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Guest: ${user.id.length >= 8 ? user.id.substring(0, 8) : user.id}...',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                key: const Key('home_start_scan_button'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                icon: const Icon(Icons.camera_alt, size: 22),
                label: Text(
                  context.tr('start_scan'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: onStartScan,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// History Section Header & Filter Chips
// =============================================================================

class _HistoryHeaderAndFilters extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cubit = context.watch<HistoryCubit>();
    final state = cubit.state;

    int totalCount = 0;
    String? activeFilter;
    if (state is HistoryLoaded) {
      totalCount = state.items.length;
      activeFilter = state.activeStatusFilter;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('scan_history_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            if (totalCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$totalCount ${context.tr('scans_count')}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                label: context.tr('filter_all'),
                isSelected: activeFilter == null,
                onTap: () => cubit.filterByStatus(null),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: context.tr('filter_low_conf'),
                isSelected: activeFilter == 'LOW_CONFIDENCE',
                onTap: () => cubit.filterByStatus('LOW_CONFIDENCE'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: context.tr('filter_shared'),
                isSelected: activeFilter == 'SHARED',
                onTap: () => cubit.filterByStatus('SHARED'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: context.tr('filter_healthy'),
                isSelected: activeFilter == 'HEALTHY',
                onTap: () => cubit.filterByStatus('HEALTHY'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: theme.colorScheme.primaryContainer,
      visualDensity: VisualDensity.compact,
    );
  }
}

// =============================================================================
// History List Sliver
// =============================================================================

class _HistoryListSliver extends StatelessWidget {
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;

  const _HistoryListSliver({
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
  });

  String _formatDate(DateTime dt) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final month = months[dt.month - 1];
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '${dt.day} $month ${dt.year}, $hour:$minute';
  }

  String _formatDiseaseName(String? diseaseId) {
    if (diseaseId == null) return 'Analyzing / No match';
    return diseaseId
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final languageCode =
        LocalizationProvider.of(context)?.languageCode ?? 'en';
    final state = context.watch<HistoryCubit>().state;

    if (state is HistoryLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (state is HistoryEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Card(
            elevation: 0,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(28.0),
              child: Column(
                children: [
                  Icon(Icons.history_toggle_off,
                      size: 48, color: theme.colorScheme.onSurfaceVariant),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('scan_history_empty'),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (state is HistoryLoaded) {
      final items = state.items;

      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        sliver: SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final item = items[index];
              final scan = item.scan;
              final diag = item.diagnosis;
              final cropName = item.crop?.getLocalizedName(languageCode) ??
                  scan.cropId.toUpperCase();
              final diseaseName = _formatDiseaseName(diag?.diseaseId);
              final isHealthy = diag?.isHealthy ?? false;
              final isLowConfidence = diag != null &&
                  !isHealthy &&
                  (diag.confidence < 0.80);

              final file = File(scan.imageLocalPath);
              final hasImage = file.existsSync();

              return Card(
                key: Key('history_card_${scan.id}'),
                elevation: 1.5,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    if (diag != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DiagnosisResultScreen(
                            scan: scan,
                            diagnosis: diag,
                            resolveTreatmentUseCase: resolveTreatmentUseCase,
                            createEscalationUseCase: createEscalationUseCase,
                          ),
                        ),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScanResultScreen(scan: scan),
                        ),
                      );
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        // Image thumbnail
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: hasImage
                              ? Image.file(
                                  file,
                                  width: 68,
                                  height: 68,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 68,
                                  height: 68,
                                  color: theme.colorScheme.surfaceContainerHighest,
                                  child: const Icon(Icons.grass, size: 32),
                                ),
                        ),
                        const SizedBox(width: 14),

                        // Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    cropName,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  _StatusPill(status: scan.status.value),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                diseaseName,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isHealthy
                                      ? Colors.green.shade800
                                      : theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(scan.capturedAt),
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                  if (diag != null)
                                    Text(
                                      '${(diag.confidence * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                        color: isLowConfidence
                                            ? Colors.orange.shade800
                                            : Colors.green.shade800,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
                      ],
                    ),
                  ),
                ),
              );
            },
            childCount: items.length,
          ),
        ),
      );
    }

    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }
}

class _StatusPill extends StatelessWidget {
  final String status;

  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (status) {
      case 'SHARED':
        color = const Color(0xFF25D366);
        break;
      case 'DIAGNOSED':
        color = Colors.blue;
        break;
      case 'ESCALATED':
        color = Colors.orange;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
