// lib/application/sync/sync_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../services/connectivity_service.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncRepository syncRepository;
  final AuthRepository authRepository;
  final ConnectivityService? connectivityService;

  StreamSubscription<bool>? _connectivitySubscription;

  /// Tracks the previous connectivity state so we only trigger sync on the
  /// offline → online transition (not on every `true` emission).
  bool _wasOnline = true;

  SyncCubit({
    required this.syncRepository,
    required this.authRepository,
    this.connectivityService,
  }) : super(const SyncInitial()) {
    _subscribeToConnectivity();
  }

  // ---------------------------------------------------------------------------
  // Connectivity listener
  // ---------------------------------------------------------------------------

  void _subscribeToConnectivity() {
    final service = connectivityService;
    if (service == null) return;

    _connectivitySubscription = service.connectivityStream().listen((isOnline) {
      final wasOffline = !_wasOnline;
      _wasOnline = isOnline;

      // Only auto-sync on the offline → online transition.
      if (isOnline && wasOffline) {
        syncNow();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

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

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}
