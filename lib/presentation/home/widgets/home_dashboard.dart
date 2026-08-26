// lib/presentation/home/widgets/home_dashboard.dart
//
// The Home tab: a dashboard, not a dumping ground.
//
// What changed and why:
//
//  * One unmistakable primary action. Diagnosing a plant is the reason this
//    app exists, so it gets a full-width card with a photographic metaphor,
//    not a button competing with a history list for attention.
//  * Status the farmer actually cares about, surfaced as numbers: how many
//    plants checked, how many need attention, how many scans are still
//    waiting to reach the cloud. The last one used to be buried in Settings,
//    which is the wrong place for "your data is not backed up yet".
//  * Only the most recent scans, with a route to the full list. The old home
//    screen embedded the entire scan history with filter chips, which pushed
//    everything else off-screen and gave history nowhere to grow.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/history/history_cubit.dart';
import '../../../application/history/history_state.dart';
import '../../../application/sync/sync_cubit.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../domain/entities/diagnosis.dart';
import '../../../domain/entities/local_user.dart';
import '../../../domain/entities/scan_history_item.dart';
import '../../onboarding/localization/localization_provider.dart';
import '../../shared/widgets/app_components.dart';
import 'scan_history_card.dart';

class HomeDashboard extends StatelessWidget {
  final LocalUser user;

  /// Spotlight target for the walkthrough, owned by the shell.
  final GlobalKey? scanButtonKey;
  final VoidCallback onStartScan;
  final VoidCallback onSeeAllHistory;
  final VoidCallback onLinkAccount;
  final ValueChanged<ScanHistoryItem> onOpenScan;

  const HomeDashboard({
    super.key,
    required this.user,
    this.scanButtonKey,
    required this.onStartScan,
    required this.onSeeAllHistory,
    required this.onLinkAccount,
    required this.onOpenScan,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => context.read<HistoryCubit>().loadHistory(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          _ScanCallToAction(key: scanButtonKey, onTap: onStartScan),
          const SizedBox(height: AppSpacing.md),
          const _StatsRow(),
          const SizedBox(height: AppSpacing.md),
          const _SyncStatusBanner(),
          if (user.isGuest) ...[
            AppBanner.info(
              title: context.tr('guest_banner_title'),
              message: context.tr('guest_banner_msg'),
              actionLabel: context.tr('guest_banner_action'),
              onAction: onLinkAccount,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppSectionHeader(
            title: context.tr('recent_scans'),
            actionLabel: context.tr('see_all'),
            onAction: onSeeAllHistory,
          ),
          const SizedBox(height: AppSpacing.sm),
          _RecentScans(onOpenScan: onOpenScan, onStartScan: onStartScan),
        ],
      ),
    );
  }
}

// =============================================================================
// Primary action
// =============================================================================

class _ScanCallToAction extends StatelessWidget {
  final VoidCallback onTap;

  const _ScanCallToAction({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label: context.tr('home_scan_cta_title'),
      child: Material(
        color: AppColors.primary,
        borderRadius: AppRadius.lg,
        child: InkWell(
          key: const Key('home_start_scan_button'),
          onTap: onTap,
          borderRadius: AppRadius.lg,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    // Solid tint, not a translucent overlay: contrast has to
                    // be predictable in direct sunlight.
                    color: AppColors.secondary,
                    borderRadius: AppRadius.md,
                  ),
                  child: const Icon(
                    Icons.photo_camera_rounded,
                    color: AppColors.onPrimary,
                    size: 32,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('home_scan_cta_title'),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.onPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        context.tr('home_scan_cta_subtitle'),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.primaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: AppColors.onPrimary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Stats
// =============================================================================

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        final items = state is HistoryLoaded ? state.items : <ScanHistoryItem>[];
        final total = items.length;
        final needsAttention = items.where((i) {
          final d = i.diagnosis;
          if (d == null) return false;
          return d.resultState == DiagnosisResultState.lowConfidence ||
              (!d.isHealthy && d.diseaseId != null);
        }).length;

        return Row(
          children: [
            Expanded(
              child: AppStatTile(
                value: '$total',
                label: context.tr('stat_total_scans'),
                icon: Icons.eco_rounded,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.smPlus),
            Expanded(
              child: AppStatTile(
                value: '$needsAttention',
                label: context.tr('stat_needs_attention'),
                icon: Icons.warning_amber_rounded,
                color: needsAttention > 0
                    ? AppColors.warning
                    : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Shows only when something is actually waiting to sync. A permanent
/// "everything is fine" row is noise; an occasional actionable one is not.
class _SyncStatusBanner extends StatelessWidget {
  const _SyncStatusBanner();

  @override
  Widget build(BuildContext context) {
    SyncCubit? cubit;
    try {
      cubit = context.watch<SyncCubit>();
    } catch (_) {
      return const SizedBox.shrink();
    }

    final pending = cubit.state.pendingCount;
    if (pending <= 0) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: AppBanner.info(
        message: context
            .tr('sync_pending_banner')
            .replaceFirst('{count}', '$pending'),
      ),
    );
  }
}

// =============================================================================
// Recent scans
// =============================================================================

class _RecentScans extends StatelessWidget {
  static const int _maxItems = 3;

  final ValueChanged<ScanHistoryItem> onOpenScan;
  final VoidCallback onStartScan;

  const _RecentScans({required this.onOpenScan, required this.onStartScan});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading || state is HistoryInitial) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is HistoryError) {
          return AppBanner.error(message: context.tr('scan_failed_msg'));
        }

        final items = state is HistoryLoaded ? state.items : <ScanHistoryItem>[];
        if (items.isEmpty) {
          return AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                const Icon(
                  Icons.photo_camera_outlined,
                  size: 40,
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: AppSpacing.smPlus),
                Text(
                  context.tr('empty_history_title'),
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  context.tr('empty_history_msg'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          );
        }

        final recent = items.take(_maxItems).toList();
        return Column(
          children: [
            for (final item in recent) ...[
              ScanHistoryCard(item: item, onTap: () => onOpenScan(item)),
              if (item != recent.last) const SizedBox(height: AppSpacing.smPlus),
            ],
          ],
        );
      },
    );
  }
}
