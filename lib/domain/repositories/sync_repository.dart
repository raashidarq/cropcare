// lib/domain/repositories/sync_repository.dart

import '../entities/sync_operation.dart';

abstract class SyncRepository {
  Future<void> enqueueOperation({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> payload,
    String operationType = 'CREATE',
  });

  Future<List<SyncOperation>> getPendingOperations({int maxRetries = 3});

  Future<int> getPendingCount();

  Future<void> updateOperationStatus({
    required String operationId,
    required SyncOperationStatus status,
    String? error,
  });

  Future<void> syncPendingOperations({required String authToken});

  Future<void> syncReferenceData({required String authToken});
}
