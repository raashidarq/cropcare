// lib/domain/repositories/sync_repository.dart

import '../entities/sync_operation.dart';

abstract class SyncRepository {
  Future<void> enqueueOperation({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> payload,
    String operationType = 'CREATE',
  });

  Future<List<SyncOperation>> getPendingOperations({
    int maxRetries = 3,
    int? limit,
  });

  Future<int> getPendingCount();

  /// Returns any operations stranded in IN_PROGRESS by an interrupted run
  /// to PENDING. Returns how many were recovered. Run at every entry point
  /// that could be first after a crash (app start, background worker).
  Future<int> recoverStalledOperations();

  /// Operations that will not be retried automatically — PERMANENTLY_FAILED
  /// or AUTH_REQUIRED — so the UI can tell the user instead of silently
  /// losing their scans.
  Future<List<SyncOperation>> getFailedOperations();

  /// Puts a single failed operation back in the queue at the user's request.
  Future<void> retryOperation(String operationId);

  /// Releases operations held by an expired session, after a fresh sign-in.
  Future<void> clearAuthHold();

  Future<void> updateOperationStatus({
    required String operationId,
    required SyncOperationStatus status,
    String? error,
  });

  Future<void> syncPendingOperations({required String authToken});

  Future<void> syncReferenceData({required String authToken});

  /// Pulls the user's scans back down from the cloud.
  ///
  /// Returns how many were newly added. Scans already on this device are left
  /// alone: the local copy may have a photo, chat history and edits the cloud
  /// row does not, so overwriting it to "restore" would destroy more than it
  /// recovered.
  ///
  /// Progress is reported per page so a long restore on a rural connection can
  /// show something moving.
  Future<int> restoreScansFromCloud({
    required String userId,
    required String authToken,
    void Function(int restored, int total)? onProgress,
  });

  /// Removes one scan from the cloud. Returns false if the row was deleted but
  /// its stored image was not, so the caller can say so rather than claiming
  /// more than happened.
  Future<bool> deleteRemoteScan({
    required String remoteScanId,
    required String authToken,
  });
}
