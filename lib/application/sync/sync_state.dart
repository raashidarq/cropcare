// lib/application/sync/sync_state.dart

abstract class SyncState {
  final int pendingCount;
  const SyncState({this.pendingCount = 0});
}

class SyncInitial extends SyncState {
  const SyncInitial({super.pendingCount});
}

class SyncInProgress extends SyncState {
  const SyncInProgress({super.pendingCount});
}

class SyncSuccess extends SyncState {
  final int syncedCount;
  const SyncSuccess({required this.syncedCount, super.pendingCount = 0});
}

class SyncError extends SyncState {
  final String message;
  const SyncError({required this.message, super.pendingCount});
}
