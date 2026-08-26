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
import '../../../core/theme/app_spacing.dart';
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
                          return ScanHistoryCard(
                            item: item,
                            onTap: () => widget.onOpenScan(item),
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
