// lib/presentation/home/widgets/history_view.dart
//
// The History tab.
//
// History used to be embedded in the middle of the home screen, which meant
// it could never grow useful affordances (filters competed with the primary
// scan action for the same screen) and pushed everything else out of view. As
// its own destination it gets room for filtering and a proper empty state.

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../application/history/history_cubit.dart';
import '../../../application/history/history_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../domain/entities/diagnosis.dart';
import '../../../domain/entities/scan.dart';
import '../../../domain/entities/scan_history_item.dart';
import '../../onboarding/localization/localization_provider.dart';
import '../../shared/widgets/app_state_views.dart';
import 'scan_history_card.dart';

enum HistoryFilter { all, needsAttention, healthy }

class HistoryView extends StatefulWidget {
  final ValueChanged<ScanHistoryItem> onOpenScan;
  final VoidCallback onStartScan;

  const HistoryView({
    super.key,
    required this.onOpenScan,
    required this.onStartScan,
  });

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  HistoryFilter _filter = HistoryFilter.all;

  bool _matches(ScanHistoryItem item) {
    final d = item.diagnosis;
    switch (_filter) {
      case HistoryFilter.all:
        return true;
      case HistoryFilter.needsAttention:
        if (item.scan.status == ScanStatus.invalidImage) return false;
        if (d == null) return false;
        return d.resultState == DiagnosisResultState.lowConfidence ||
            (!d.isHealthy && d.diseaseId != null);
      case HistoryFilter.healthy:
        return d?.isHealthy ?? false;
    }
  }

  /// Asks first, then deletes. Returns false so the row springs back if the
  /// farmer says no, or if the delete fails.
  ///
  /// A confirmation rather than swipe-then-undo: undo needs the deletion
  /// deferred or reversed, and this one removes a photo from disk. Better to
  /// ask once than to promise an undo that cannot restore the file.
  Future<bool> _confirmDelete(
    BuildContext context,
    ScanHistoryItem item,
  ) async {
    final cubit = context.read<HistoryCubit>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        key: const Key('delete_scan_dialog'),
        title: Text(dialogCtx.tr('delete_scan_title')),
        content: Text(
          item.scan.remoteScanId != null
              // Says plainly that the cloud copy survives. The backend has no
              // delete endpoint for scans, and implying otherwise would be a
              // lie about where a farmer's data lives.
              ? dialogCtx.tr('delete_scan_synced_msg')
              : dialogCtx.tr('delete_scan_msg'),
        ),
        actions: [
          TextButton(
            key: const Key('delete_scan_cancel'),
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: Text(dialogCtx.tr('cancel')),
          ),
          TextButton(
            key: const Key('delete_scan_confirm'),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: Text(dialogCtx.tr('delete')),
          ),
        ],
      ),
    );

    if (confirmed != true) return false;
    if (!context.mounted) return false;

    AppHaptics.capture(context);
    // Resolve the strings before awaiting: the context is not guaranteed to
    // still be mounted afterwards, and the messenger was captured up front
    // for the same reason.
    final doneMsg = context.tr('delete_scan_done');
    final failedMsg = context.tr('delete_scan_failed');

    final ok = await cubit.deleteScan(item.scan.id);
    messenger.showSnackBar(
      SnackBar(
        content: Text(ok ? doneMsg : failedMsg),
        behavior: SnackBarBehavior.floating,
      ),
    );
    // The cubit reloads either way, so the list is already correct; returning
    // false stops Dismissible from also animating a row that may still exist.
    return false;
  }

  String _labelFor(HistoryFilter filter) {
    switch (filter) {
      case HistoryFilter.all:
        return context.tr('filter_all');
      case HistoryFilter.needsAttention:
        return context.tr('stat_needs_attention');
      case HistoryFilter.healthy:
        return context.tr('result_healthy_title');
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HistoryCubit, HistoryState>(
      builder: (context, state) {
        if (state is HistoryLoading || state is HistoryInitial) {
          return const AppLoadingView();
        }
        if (state is HistoryError) {
          return AppErrorView(
            title: context.tr('scan_failed_title'),
            message: context.tr('scan_failed_msg'),
            technicalDetail: state.message,
            actionLabel: context.tr('retry'),
            onAction: () => context.read<HistoryCubit>().loadHistory(),
          );
        }

        final all = state is HistoryLoaded ? state.items : <ScanHistoryItem>[];
        if (all.isEmpty) {
          return AppEmptyView(
            icon: Icons.photo_camera_outlined,
            title: context.tr('empty_history_title'),
            message: context.tr('empty_history_msg'),
            actionLabel: context.tr('home_scan_cta_title'),
            onAction: widget.onStartScan,
          );
        }

        final filtered = all.where(_matches).toList();

        return RefreshIndicator(
          onRefresh: () => context.read<HistoryCubit>().loadHistory(),
          child: Column(
            children: [
              _FilterBar(
                selected: _filter,
                labelFor: _labelFor,
                onChanged: (f) => setState(() => _filter = f),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? AppEmptyView(
                        icon: Icons.filter_alt_off_outlined,
                        title: context.tr('empty_history_title'),
                        message: context.tr('empty_history_msg'),
                      )
                    : ListView.separated(
                        // Virtualised: history can grow to thousands of rows
                        // on a device that is used daily for a season.
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.sm,
                          AppSpacing.md,
                          AppSpacing.xxl,
                        ),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: AppSpacing.smPlus),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final card = ScanHistoryCard(
                            item: item,
                            onTap: () => widget.onOpenScan(item),
                          );
                          final cubit = context.read<HistoryCubit>();
                          if (!cubit.canDelete) return card;

                          return Dismissible(
                            key: ValueKey(item.scan.id),
                            // One direction only. Farmers scroll this list
                            // with one hand outdoors, and a two-way swipe on
                            // a photo list is far too easy to trigger by
                            // accident.
                            direction: DismissDirection.endToStart,
                            background: const _DeleteBackground(),
                            confirmDismiss: (_) =>
                                _confirmDelete(context, item),
                            onDismissed: (_) {},
                            child: card,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _FilterBar extends StatelessWidget {
  final HistoryFilter selected;
  final String Function(HistoryFilter) labelFor;
  final ValueChanged<HistoryFilter> onChanged;

  const _FilterBar({
    required this.selected,
    required this.labelFor,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        children: [
          for (final filter in HistoryFilter.values)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Center(
                child: ChoiceChip(
                  label: Text(labelFor(filter)),
                  selected: selected == filter,
                  onSelected: (_) => onChanged(filter),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// What sits behind the row while it is being swiped.
class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: AppSpacing.lg),
      decoration: const BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppRadius.lg,
      ),
      child: const Icon(
        Icons.delete_outline_rounded,
        color: AppColors.onErrorContainer,
      ),
    );
  }
}
