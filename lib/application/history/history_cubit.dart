// lib/application/history/history_cubit.dart
//
// Manages loading and filtering of past scans for the embedded history section.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/history/get_scan_history_use_case.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final GetScanHistoryUseCase getScanHistoryUseCase;

  String? _selectedCropId;
  String? _selectedStatusFilter;

  HistoryCubit({required this.getScanHistoryUseCase})
      : super(const HistoryInitial());

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
