// lib/application/sync/sync_cubit.dart

import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/scan_repository.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../domain/usecases/history/delete_all_local_scans_use_case.dart';
import '../../services/connectivity_service.dart';
import '../../data/local/preferences/sync_preferences.dart';
import '../../domain/entities/sync_operation.dart';
import 'sync_state.dart';

class SyncCubit extends Cubit<SyncState> {
  final SyncRepository syncRepository;
  final AuthRepository authRepository;
  final ScanRepository? scanRepository;
  final DeleteAllLocalScansUseCase? deleteAllLocalScansUseCase;
  final ConnectivityService? connectivityService;
  final SyncPreferences? syncPreferences;

  StreamSubscription<bool>? _connectivitySubscription;
  /// OFF by default. Syncing uploads photos over what is frequently a
  /// metered rural connection, and a guest has no account to sync to, so it
  /// is opt-in and only meaningful once signed in.
  bool _autoSyncEnabled = false;

  /// Tracks the previous connectivity state so we only trigger sync on the
  /// offline → online transition (not on every `true` emission).
  bool _wasOnline = true;

  SyncCubit({
    required this.syncRepository,
    required this.authRepository,
    this.scanRepository,
    this.deleteAllLocalScansUseCase,
    this.connectivityService,
    bool autoSyncEnabled = false,
    this.syncPreferences,
  })  : _autoSyncEnabled = autoSyncEnabled,
        super(SyncInitial(autoSyncEnabled: autoSyncEnabled)) {
    _subscribeToConnectivity();
  }

  bool get autoSyncEnabled => _autoSyncEnabled;
  bool get wifiOnly => _wifiOnly;

  /// Defaults to true, matching SyncPreferences: opting into background sync
  /// is not the same as agreeing to pay mobile-data rates for it.
  bool _wifiOnly = true;

  /// Loads the persisted preference. Auto-sync stays off unless it was
  /// explicitly enabled AND there is a session to sync with — a stored
  /// "true" from before a sign-out must not silently re-arm it.
  Future<void> loadAutoSyncPreference() async {
    final prefs = syncPreferences;
    if (prefs == null) return;
    final stored = await prefs.getAutoSyncEnabled();
    _wifiOnly = await prefs.getWifiOnly();
    final token = await authRepository.getStoredToken();
    final effective = stored && token != null && token.isNotEmpty;
    _autoSyncEnabled = effective;
    emit(SyncInitial(
      pendingCount: state.pendingCount,
      autoSyncEnabled: effective,
      wifiOnly: _wifiOnly,
      failedOperations: state.failedOperations,
    ));
  }

  /// True when there is a session, i.e. when auto-sync can do anything.
  Future<bool> canAutoSync() async {
    final token = await authRepository.getStoredToken();
    return token != null && token.isNotEmpty;
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

      // Only auto-sync on the offline → online transition if auto-sync is
      // enabled, and only over a connection the farmer is not paying for by
      // the megabyte. Scans upload full-resolution photographs, and doing
      // that silently in the background on mobile data spends real money.
      if (isOnline && wasOffline && _autoSyncEnabled) {
        _syncIfConnectionAllows();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Enabling requires a signed-in session; a guest has nowhere to sync to,
  /// so silently accepting the toggle would be a lie. Disabling always works.
  Future<void> toggleAutoSync(bool enabled) async {
    if (enabled && !await canAutoSync()) {
      emit(SyncError(
        message: 'auto_sync_requires_account',
        pendingCount: state.pendingCount,
        autoSyncEnabled: false,
        failedOperations: state.failedOperations,
      ));
      return;
    }

    _autoSyncEnabled = enabled;
    await syncPreferences?.setAutoSyncEnabled(enabled);
    emit(SyncInitial(
      pendingCount: state.pendingCount,
      autoSyncEnabled: _autoSyncEnabled,
      wifiOnly: _wifiOnly,
      failedOperations: state.failedOperations,
    ));
  }

  /// Runs an automatic sync only if the current connection is acceptable.
  ///
  /// Silent about being skipped: the farmer did not ask for this sync, so
  /// interrupting them to say it did not happen would be noise. The pending
  /// count in Settings already shows the backlog, and "Sync now" is always
  /// available.
  Future<void> _syncIfConnectionAllows() async {
    if (_wifiOnly) {
      final service = connectivityService;
      // With no way to tell what kind of connection this is, err toward not
      // spending the farmer's money.
      if (service == null) return;
      if (!await service.isOnUnmeteredConnection()) return;
    }
    await syncNow();
  }

  /// Wi-Fi-only applies to background syncing only, so this never needs a
  /// session check the way auto-sync does.
  Future<void> toggleWifiOnly(bool enabled) async {
    _wifiOnly = enabled;
    await syncPreferences?.setWifiOnly(enabled);
    emit(SyncInitial(
      pendingCount: state.pendingCount,
      autoSyncEnabled: _autoSyncEnabled,
      wifiOnly: _wifiOnly,
      failedOperations: state.failedOperations,
    ));
  }

  /// Turns auto-sync off and forgets the preference. Called on sign-out so a
  /// later guest session does not inherit it.
  Future<void> disableAutoSyncOnSignOut() async {
    _autoSyncEnabled = false;
    await syncPreferences?.setAutoSyncEnabled(false);
    emit(SyncInitial(
      pendingCount: state.pendingCount,
      autoSyncEnabled: false,
      failedOperations: state.failedOperations,
    ));
  }

  /// Operations the engine has stopped retrying. Read on every emit so the
  /// UI never has to ask separately and never shows a stale list.
  Future<List<SyncOperation>> _failed() async {
    try {
      return await syncRepository.getFailedOperations();
    } catch (_) {
      return const [];
    }
  }

  Future<void> refreshPendingCount() async {
    try {
      final count = await syncRepository.getPendingCount();
      emit(SyncInitial(
        pendingCount: count,
        autoSyncEnabled: _autoSyncEnabled,
        wifiOnly: _wifiOnly,
        failedOperations: await _failed(),
      ));
    } catch (_) {}
  }

  /// Puts one permanently-failed operation back in the queue, at the user's
  /// explicit request. Deliberately manual: these stopped retrying because
  /// retrying was not working, so re-queueing is a decision, not a default.
  Future<void> retryFailedOperation(String operationId) async {
    try {
      await syncRepository.retryOperation(operationId);
    } catch (_) {
      // Surfacing the raw error here would be noise; the item simply stays
      // in the failed list, which is itself the signal.
    }
    await refreshPendingCount();
  }

  /// Releases operations held by an expired session. Call after a fresh
  /// sign-in, then sync.
  Future<void> resumeAfterReauth({String? token}) async {
    try {
      await syncRepository.clearAuthHold();
    } catch (_) {}
    await syncNow(token: token);
  }

  Future<void> deleteAllLocalScans() async {
    try {
      if (deleteAllLocalScansUseCase != null) {
        await deleteAllLocalScansUseCase!.call();
      } else if (scanRepository != null) {
        await scanRepository!.deleteAllLocalScans();
      }
      emit(SyncInitial(
        pendingCount: 0,
        autoSyncEnabled: _autoSyncEnabled,
        wifiOnly: _wifiOnly,
        failedOperations: await _failed(),
      ));
    } catch (e) {
      emit(SyncError(
        message: e.toString(),
        pendingCount: state.pendingCount,
        autoSyncEnabled: _autoSyncEnabled,
        wifiOnly: _wifiOnly,
      ));
    }
  }

  /// Guards against overlapping in-process sync runs.
  ///
  /// syncNow() is reachable from four independent triggers — the manual
  /// button, the connectivity listener, the post-auth hook and the
  /// "sync before deleting" prompt — none of which knew about each other.
  /// Only the manual button was guarded, and only via its own disabled
  /// state, so e.g. connectivity returning at the moment a sign-in
  /// completed could start two concurrent runs over the same rows.
  ///
  /// This is a flag rather than a check of `state is SyncInProgress` because
  /// there are awaits before that state is emitted; a second caller could
  /// slip through in between. (Cross-isolate exclusion against the
  /// WorkManager worker is handled separately by the DB advisory lock.)
  bool _syncInFlight = false;

  Future<void> syncNow({String? token}) async {
    if (_syncInFlight) return;
    _syncInFlight = true;
    try {
      await _syncNow(token: token);
    } finally {
      _syncInFlight = false;
    }
  }

  Future<void> _syncNow({String? token}) async {
    final count = await syncRepository.getPendingCount();

    final effectiveToken = token ?? await authRepository.getStoredToken();

    if (effectiveToken == null || effectiveToken.isEmpty) {
      if (count > 0) {
        emit(SyncError(
          message: 'Please link or sign in to your CropCare account to sync scans to the cloud.',
          pendingCount: count,
          autoSyncEnabled: _autoSyncEnabled,
          wifiOnly: _wifiOnly,
          failedOperations: await _failed(),
        ));
      } else {
        emit(SyncInitial(
          pendingCount: 0,
          autoSyncEnabled: _autoSyncEnabled,
          wifiOnly: _wifiOnly,
          failedOperations: await _failed(),
        ));
      }
      return;
    }

    emit(SyncInProgress(
      pendingCount: count,
      autoSyncEnabled: _autoSyncEnabled,
      wifiOnly: _wifiOnly,
      failedOperations: state.failedOperations,
    ));

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
      emit(SyncSuccess(
        syncedCount: synced >= 0 ? synced : count,
        pendingCount: remaining,
        autoSyncEnabled: _autoSyncEnabled,
        wifiOnly: _wifiOnly,
        failedOperations: await _failed(),
      ));
    } catch (e) {
      final remaining = await syncRepository.getPendingCount();
      emit(SyncError(
        message: e.toString(),
        pendingCount: remaining,
        autoSyncEnabled: _autoSyncEnabled,
        wifiOnly: _wifiOnly,
        failedOperations: await _failed(),
      ));
    }
  }

  @override
  Future<void> close() async {
    await _connectivitySubscription?.cancel();
    return super.close();
  }
}
