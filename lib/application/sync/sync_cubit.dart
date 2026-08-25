// lib/application/sync/sync_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncRepository _syncRepository;
  final AuthRepository _authRepository;

  SyncCubit({
    required SyncRepository syncRepository,
    required AuthRepository authRepository,
  })  : _syncRepository = syncRepository,
        _authRepository = authRepository,
        super(const SyncInitial());

  Future<void> refreshPendingCount() async {
    try {
      final count = await _syncRepository.getPendingCount();
      emit(SyncInitial(pendingCount: count));
    } catch (_) {}
  }

  Future<void> syncNow() async {
    final count = await _syncRepository.getPendingCount();
    if (count == 0) {
      emit(const SyncSuccess(syncedCount: 0, pendingCount: 0));
      return;
    }

    final token = await _authRepository.getStoredToken();

    if (token == null || token.isEmpty) {
      emit(SyncError(
        message: 'Please link or sign in to your CropCare account to sync scans to the cloud.',
        pendingCount: count,
      ));
      return;
    }

    emit(SyncInProgress(pendingCount: count));

    try {
      await _syncRepository.syncPendingOperations(authToken: token);
      final remaining = await _syncRepository.getPendingCount();
      final synced = count - remaining;
      emit(SyncSuccess(syncedCount: synced > 0 ? synced : count, pendingCount: remaining));
    } catch (e) {
      final remaining = await _syncRepository.getPendingCount();
      emit(SyncError(
        message: e.toString(),
        pendingCount: remaining,
      ));
    }
  }
}
