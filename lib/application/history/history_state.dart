// lib/application/history/history_state.dart
//
// States for HistoryCubit.

import '../../domain/entities/scan_history_item.dart';

abstract class HistoryState {
  const HistoryState();
}

class HistoryInitial extends HistoryState {
  const HistoryInitial();
}

class HistoryLoading extends HistoryState {
  const HistoryLoading();
}

class HistoryLoaded extends HistoryState {
  final List<ScanHistoryItem> items;
  final String? activeCropFilter;
  final String? activeStatusFilter;

  const HistoryLoaded({
    required this.items,
    this.activeCropFilter,
    this.activeStatusFilter,
  });
}

class HistoryEmpty extends HistoryState {
  final String? activeStatusFilter;
  const HistoryEmpty({this.activeStatusFilter});
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);
}
