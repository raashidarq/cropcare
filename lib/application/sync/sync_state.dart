// lib/application/sync/sync_state.dart

import '../../domain/entities/sync_operation.dart';

abstract class SyncState {
  final int pendingCount;
  final bool autoSyncEnabled;

  /// Operations that will not retry on their own — PERMANENTLY_FAILED or
  /// AUTH_REQUIRED. Carried on every state so the UI can keep showing them
  /// while a fresh sync runs; a farmer whose scans did not reach the cloud
  /// should not have that fact disappear because they tapped Sync again.
  final List<SyncOperation> failedOperations;

  const SyncState({
    this.pendingCount = 0,
    this.autoSyncEnabled = true,
    this.failedOperations = const [],
  });

  /// True when at least one operation is held waiting for the user to sign
  /// in again, rather than merely having failed.
  bool get needsReauth => failedOperations
      .any((o) => o.status == SyncOperationStatus.authRequired);
}

class SyncInitial extends SyncState {
  const SyncInitial({
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
    super.failedOperations = const [],
  });
}

class SyncInProgress extends SyncState {
  const SyncInProgress({
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
    super.failedOperations = const [],
  });
}

class SyncSuccess extends SyncState {
  final int syncedCount;
  const SyncSuccess({
    required this.syncedCount,
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
    super.failedOperations = const [],
  });
}

class SyncError extends SyncState {
  final String message;
  const SyncError({
    required this.message,
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
    super.failedOperations = const [],
  });
}
