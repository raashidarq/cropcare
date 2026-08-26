// lib/application/history/history_cubit.dart
//
// Manages loading and filtering of past scans for the embedded history section.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/history/delete_scan_use_case.dart';
import '../../domain/usecases/history/get_scan_history_use_case.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final GetScanHistoryUseCase getScanHistoryUseCase;

  /// Optional so the many existing constructions of this cubit in tests and
  /// fallback paths keep working; delete is simply unavailable without it.
  final DeleteScanUseCase? deleteScanUseCase;

  String? _selectedCropId;
  String? _selectedStatusFilter;

  HistoryCubit({
    required this.getScanHistoryUseCase,
    this.deleteScanUseCase,
  }) : super(const HistoryInitial());

  bool get canDelete => deleteScanUseCase != null;

  /// Deletes one scan and reloads. Returns false if it could not be done, so
  /// the caller can put the row back rather than leaving a gap where a scan
  /// the farmer still has is no longer listed.
  Future<bool> deleteScan(String scanId) async {
    final useCase = deleteScanUseCase;
    if (useCase == null) return false;
    try {
      await useCase(scanId);
      await loadHistory();
      return true;
    } catch (_) {
      await loadHistory();
      return false;
    }
  }

  Future<void> loadHistory() async {
    emit(const HistoryLoading());
    try {
      final items = await getScanHistoryUseCase(
        cropId: _selectedCropId,
        statusFilter: _selectedStatusFilter,
      );

      if (items.isEmpty) {
        emit(HistoryEmpty(activeStatusFilter: _selectedStatusFilter));
      } else {
        emit(HistoryLoaded(
          items: items,
          activeCropFilter: _selectedCropId,
          activeStatusFilter: _selectedStatusFilter,
        ));
      }
    } catch (e) {
      emit(HistoryError(e.toString()));
    }
  }

  Future<void> filterByStatus(String? status) async {
    _selectedStatusFilter = status;
    await loadHistory();
  }

  Future<void> filterByCrop(String? cropId) async {
    _selectedCropId = cropId;
    await loadHistory();
  }
}
