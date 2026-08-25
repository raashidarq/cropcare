// lib/application/sync/sync_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncRepository syncRepository;
  final AuthRepository authRepository;

  SyncCubit({
    required this.syncRepository,
    required this.authRepository,
  }) : super(const SyncInitial());

  Future<void> refreshPendingCount() async {
    try {
      final count = await syncRepository.getPendingCount();
      emit(SyncInitial(pendingCount: count));
    } catch (_) {}
  }

  Future<void> syncNow({String? token}) async {
    final count = await syncRepository.getPendingCount();

    final effectiveToken = token ?? await authRepository.getStoredToken();

    if (effectiveToken == null || effectiveToken.isEmpty) {
      if (count > 0) {
        emit(SyncError(
          message: 'Please link or sign in to your CropCare account to sync scans to the cloud.',
          pendingCount: count,
        ));
      } else {
        emit(const SyncInitial(pendingCount: 0));
      }
      return;
    }

    emit(SyncInProgress(pendingCount: count));

    try {
      if (count > 0) {
        await syncRepository.syncPendingOperations(authToken: effectiveToken);
      }
      // Attempt downstream reference data sync
      try {
        await syncRepository.syncReferenceData(authToken: effectiveToken);
      } catch (_) {
        // Non-fatal reference data sync error
      }

      final remaining = await syncRepository.getPendingCount();
      final synced = count - remaining;
      emit(SyncSuccess(syncedCount: synced >= 0 ? synced : count, pendingCount: remaining));
    } catch (e) {
      final remaining = await syncRepository.getPendingCount();
      emit(SyncError(
        message: e.toString(),
        pendingCount: remaining,
      ));
    }
  }
}
