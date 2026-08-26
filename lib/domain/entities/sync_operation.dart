// lib/domain/entities/sync_operation.dart

enum SyncEntityType {
  scan,
  diagnosis,
  escalation,
}

enum SyncOperationStatus {
  pending,
  inProgress,
  completed,

  /// Failed, but worth retrying (network timeout, server 5xx). Counts
  /// against the retry budget.
  failed,

  /// Retrying will not help — the server rejected the payload (4xx other
  /// than 401), or the retry budget is exhausted. Previously these were
  /// silently excluded from the pending query and vanished with no user
  /// signal; they are now surfaced so a farmer can see the scan did not
  /// reach the cloud.
  permanentlyFailed,

  /// The session expired mid-sync. Held rather than retried: retrying with
  /// a dead token just burns the retry budget and silently loses the
  /// backlog. Cleared when the user signs in again.
  authRequired,
}

class SyncOperation {
  final String id;
  final String entityId;
  final SyncEntityType entityType;
  final String operationType;
  final String payloadJson;
  final SyncOperationStatus status;
  final int retryCount;
  final String? lastError;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SyncOperation({
    required this.id,
    required this.entityId,
    required this.entityType,
    this.operationType = 'CREATE',
    required this.payloadJson,
    this.status = SyncOperationStatus.pending,
    this.retryCount = 0,
    this.lastError,
    required this.createdAt,
    required this.updatedAt,
  });

  SyncOperation copyWith({
    String? id,
    String? entityId,
    SyncEntityType? entityType,
    String? operationType,
    String? payloadJson,
    SyncOperationStatus? status,
    int? retryCount,
    String? lastError,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SyncOperation(
      id: id ?? this.id,
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      operationType: operationType ?? this.operationType,
      payloadJson: payloadJson ?? this.payloadJson,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
