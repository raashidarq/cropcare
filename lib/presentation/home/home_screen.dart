import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../application/auth/auth_cubit.dart';
import '../../application/history/history_cubit.dart';
import '../../application/history/history_state.dart';
import '../../application/sync/sync_cubit.dart';
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
import '../../domain/usecases/feedback/submit_feedback_use_case.dart';
import '../../domain/usecases/history/export_scan_history_use_case.dart';
import '../../domain/usecases/history/get_scan_history_use_case.dart';
import '../auth/auth_screen.dart';
import '../diagnosis/diagnosis_result_screen.dart';
import '../onboarding/localization/localization_provider.dart';
import '../scan/add_photo_screen.dart';
import '../scan/scan_result_screen.dart';
import '../settings/profile_screen.dart';
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
  Future<void> updateScanCrop(String scanId, String cropId) async {}

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => [];

  @override
  Future<void> deleteAllLocalScans() async {}
}

class HomeScreen extends StatefulWidget {
  final LocalUser? user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final GetSupportedCropsUseCase? getSupportedCropsUseCase;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final GetScanHistoryUseCase? getScanHistoryUseCase;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  const HomeScreen({
    super.key,
    this.user,
    this.authCubit,
    this.syncCubit,
    this.getSupportedCropsUseCase,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
    this.getScanHistoryUseCase,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late LocalUser _user;
  late final GetSupportedCropsUseCase _getSupportedCropsUseCase;
  late final GetScanHistoryUseCase _getScanHistoryUseCase;

  @override
  void initState() {
    super.initState();
    _user = widget.user ??
        widget.authCubit?.currentUser ??
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

  void _onUserUpdated(LocalUser updatedUser) {
    setState(() {
      _user = updatedUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<HistoryCubit>(
      create: (_) => HistoryCubit(
        getScanHistoryUseCase: _getScanHistoryUseCase,
      )..loadHistory(),
      child: _HomeScreenView(
        user: _user,
        authCubit: widget.authCubit,
        syncCubit: widget.syncCubit,
        onUserUpdated: _onUserUpdated,
        getSupportedCropsUseCase: _getSupportedCropsUseCase,
        validateImageUseCase: widget.validateImageUseCase,
        runDiagnosisUseCase: widget.runDiagnosisUseCase,
        resolveTreatmentUseCase: widget.resolveTreatmentUseCase,
        createEscalationUseCase: widget.createEscalationUseCase,
        exportScanHistoryUseCase: widget.exportScanHistoryUseCase,
        submitFeedbackUseCase: widget.submitFeedbackUseCase,
      ),
    );
  }
}

class _HomeScreenView extends StatelessWidget {
  final LocalUser user;
  final AuthCubit? authCubit;
  final SyncCubit? syncCubit;
  final ValueChanged<LocalUser> onUserUpdated;
  final GetSupportedCropsUseCase getSupportedCropsUseCase;
  final ValidateImageUseCase? validateImageUseCase;
  final RunDiagnosisUseCase? runDiagnosisUseCase;
  final ResolveTreatmentUseCase? resolveTreatmentUseCase;
  final CreateEscalationUseCase? createEscalationUseCase;
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;
  final SubmitFeedbackUseCase? submitFeedbackUseCase;

  const _HomeScreenView({
    required this.user,
    this.authCubit,
    this.syncCubit,
    required this.onUserUpdated,
    required this.getSupportedCropsUseCase,
    this.validateImageUseCase,
    this.runDiagnosisUseCase,
    this.resolveTreatmentUseCase,
    this.createEscalationUseCase,
    this.exportScanHistoryUseCase,
    this.submitFeedbackUseCase,
  });

  Future<void> _handleAccountAction(BuildContext context) async {
    if (authCubit == null) return;
    final currentUser = authCubit!.currentUser;
    if (currentUser.isGuest) {
      final updated = await Navigator.push<LocalUser>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit!,
            child: AuthScreen(currentUser: currentUser),
          ),
        ),
      );
      if (updated != null) {
        onUserUpdated(updated);
      }
    } else {
      final updated = await Navigator.push<LocalUser>(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: authCubit!,
            child: ProfileScreen(
              user: currentUser,
              authCubit: authCubit,
            ),
          ),
        ),
      );
      if (updated != null) {
        onUserUpdated(updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = user.isGuest;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('home_title')),
        elevation: 0,
        actions: [
          IconButton(
            key: const Key('home_account_icon'),
            icon: Icon(
              isGuest ? Icons.account_circle_outlined : Icons.account_circle,
              color: isGuest ? null : Colors.green.shade700,
            ),
            tooltip: isGuest ? context.tr('link_account_btn') : context.tr('profile_title'),
            onPressed: () => _handleAccountAction(context),
          ),
          IconButton(
            key: const Key('home_settings_icon'),
            icon: const Icon(Icons.settings),
            tooltip: context.tr('settings_title'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SettingsScreen(
                    user: user,
                    authCubit: authCubit,
                    syncCubit: syncCubit,
                    exportScanHistoryUseCase: exportScanHistoryUseCase,
                    submitFeedbackUseCase: submitFeedbackUseCase,
                  ),
                ),
              );
            },
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
                  onStartScan: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddPhotoScreen(
                          user: user,
                          getSupportedCropsUseCase: getSupportedCropsUseCase,
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
                child: _HistoryHeaderAndFilters(
                  exportScanHistoryUseCase: exportScanHistoryUseCase,
                ),
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
  final VoidCallback onStartScan;

  const _HeroScanCard({
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
                  child: const Icon(
                    Icons.eco,
                    color: Colors.white,
                    size: 28,
                  ),
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
                        context.tr('home_subtitle'),
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
  final ExportScanHistoryUseCase? exportScanHistoryUseCase;

  const _HistoryHeaderAndFilters({
    this.exportScanHistoryUseCase,
  });

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
    } else if (state is HistoryEmpty) {
      totalCount = 0;
      activeFilter = state.activeStatusFilter;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Row 1: "Scan History" title + "Export" [download icon] ───────
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.tr('scan_history_title'),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              key: const Key('home_export_history_icon'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                foregroundColor: theme.colorScheme.primary,
              ),
              icon: const Icon(Icons.file_download_outlined, size: 18),
              label: Text(
                context.tr('export_btn'),
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () async {
                if (exportScanHistoryUseCase != null) {
                  final count = await exportScanHistoryUseCase!.execute();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          count > 0
                              ? context.tr('export_data_success')
                              : context.tr('export_data_empty'),
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 10),

        // ── Row 2: Filter Dropdown + Number of Scans ('15 scans') ────────
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    key: const Key('home_history_filter_dropdown'),
                    isExpanded: true,
                    value: activeFilter ?? 'ALL',
                    icon: const Icon(Icons.arrow_drop_down),
                    items: [
                      DropdownMenuItem(
                        value: 'ALL',
                        child: Text(context.tr('filter_all'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'HEALTHY',
                        child: Text(context.tr('filter_healthy'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'LOW_CONFIDENCE',
                        child: Text(context.tr('filter_low_conf'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'SHARED',
                        child: Text(context.tr('filter_shared'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'DATE_TODAY',
                        child: Text(context.tr('filter_date_today'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'DATE_WEEK',
                        child: Text(context.tr('filter_date_week'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'DATE_MONTH',
                        child: Text(context.tr('filter_date_month'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'CROP_TOMATO',
                        child: Text(context.tr('filter_crop_tomato'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'CROP_CHILI',
                        child: Text(context.tr('filter_crop_chili'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'CROP_PADDY',
                        child: Text(context.tr('filter_crop_paddy'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'CROP_CORN',
                        child: Text(context.tr('filter_crop_corn'), style: const TextStyle(fontSize: 13)),
                      ),
                      DropdownMenuItem(
                        value: 'CROP_POTATO',
                        child: Text(context.tr('filter_crop_potato'), style: const TextStyle(fontSize: 13)),
                      ),
                    ],
                    onChanged: (val) {
                      cubit.filterByStatus(val == 'ALL' ? null : val);
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$totalCount ${context.tr('scans_count')}',
                key: const Key('home_history_scan_count_badge'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ],
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
