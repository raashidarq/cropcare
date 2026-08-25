// lib/application/sync/sync_state.dart

abstract class SyncState {
  final int pendingCount;
  final bool autoSyncEnabled;

  const SyncState({
    this.pendingCount = 0,
    this.autoSyncEnabled = true,
  });
}

class SyncInitial extends SyncState {
  const SyncInitial({
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
  });
}

class SyncInProgress extends SyncState {
  const SyncInProgress({
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
  });
}

class SyncSuccess extends SyncState {
  final int syncedCount;
  const SyncSuccess({
    required this.syncedCount,
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
  });
}

class SyncError extends SyncState {
  final String message;
  const SyncError({
    required this.message,
    super.pendingCount = 0,
    super.autoSyncEnabled = true,
  });
}
