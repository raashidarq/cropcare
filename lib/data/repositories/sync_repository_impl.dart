// lib/data/repositories/sync_repository_impl.dart

import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';

import '../../domain/entities/sync_operation.dart';
import '../../domain/repositories/sync_repository.dart';
import '../local/database/app_database.dart';
import '../remote/sync_api_client.dart';

class SyncRepositoryImpl implements SyncRepository {
  final AppDatabase _db;
  final SyncApiClient _apiClient;

  SyncRepositoryImpl({
    required AppDatabase db,
    SyncApiClient? apiClient,
  })  : _db = db,
        _apiClient = apiClient ?? SyncApiClient();

  @override
  Future<void> enqueueOperation({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> payload,
    String operationType = 'CREATE',
  }) async {
    final now = DateTime.now().toIso8601String();
    final typeStr = _mapEntityTypeToString(entityType);
    final payloadJsonStr = jsonEncode(payload);

    // Check if an existing pending operation exists for this entity
    final existing = await (_db.select(_db.syncOperationTable)
          ..where((t) =>
              t.entityId.equals(entityId) &
              t.entityType.equals(typeStr) &
              t.status.equals('PENDING')))
        .getSingleOrNull();

    if (existing != null) {
      await (_db.update(_db.syncOperationTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(
        SyncOperationTableCompanion(
          payloadJson: Value(payloadJsonStr),
          operationType: Value(operationType),
          updatedAt: Value(now),
        ),
      );
    } else {
      final opId = 'sync_${DateTime.now().millisecondsSinceEpoch}_${entityId.substring(0, entityId.length > 8 ? 8 : entityId.length)}';
      await _db.into(_db.syncOperationTable).insert(
            SyncOperationTableCompanion.insert(
              id: opId,
              entityId: entityId,
              entityType: typeStr,
              operationType: Value(operationType),
              payloadJson: payloadJsonStr,
              status: const Value('PENDING'),
              retryCount: const Value(0),
              createdAt: now,
              updatedAt: now,
            ),
          );
    }
  }

  @override
  Future<List<SyncOperation>> getPendingOperations({int maxRetries = 3}) async {
    final rows = await (_db.select(_db.syncOperationTable)
          ..where((t) =>
              (t.status.equals('PENDING') | t.status.equals('FAILED')) &
              t.retryCount.isSmallerThanValue(maxRetries))
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
          ]))
        .get();

    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<int> getPendingCount() async {
    final countExp = _db.syncOperationTable.id.count();
    final query = _db.selectOnly(_db.syncOperationTable)
      ..addColumns([countExp])
      ..where((_db.syncOperationTable.status.equals('PENDING') |
              _db.syncOperationTable.status.equals('FAILED')) &
          _db.syncOperationTable.retryCount.isSmallerThanValue(3));

    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
  }

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required SyncOperationStatus status,
    String? error,
  }) async {
    final now = DateTime.now().toIso8601String();
    final statusStr = _mapStatusToString(status);

    await (_db.update(_db.syncOperationTable)
          ..where((t) => t.id.equals(operationId)))
        .write(
      SyncOperationTableCompanion(
        status: Value(statusStr),
        lastError: Value(error),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<void> syncPendingOperations({required String authToken}) async {
    final pendingOps = await getPendingOperations();

    for (final op in pendingOps) {
      await updateOperationStatus(
        operationId: op.id,
        status: SyncOperationStatus.inProgress,
      );

      try {
        final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;

        switch (op.entityType) {
          case SyncEntityType.scan:
            final imagePath = payload['image_local_path'] as String?;
            if (imagePath != null && imagePath.isNotEmpty) {
              final file = File(imagePath);
              if (await file.exists()) {
                final signedUrl = await _apiClient.getSignedUploadUrl(
                  scanId: op.entityId,
                  authToken: authToken,
                );
                final bytes = await file.readAsBytes();
                await _apiClient.uploadImageBinary(
                  signedUrl: signedUrl,
                  imageBytes: bytes,
                );
              }
            }
            await _apiClient.syncScan(
              scanData: payload,
              authToken: authToken,
            );
            break;

          case SyncEntityType.diagnosis:
            await _apiClient.syncDiagnosis(
              diagnosisData: payload,
              authToken: authToken,
            );
            break;

          case SyncEntityType.escalation:
            await _apiClient.syncEscalation(
              escalationData: payload,
              authToken: authToken,
            );
            break;
        }

        await updateOperationStatus(
          operationId: op.id,
          status: SyncOperationStatus.completed,
        );
      } catch (e) {
        final row = await (_db.select(_db.syncOperationTable)
              ..where((t) => t.id.equals(op.id)))
            .getSingleOrNull();
        final currentRetries = row?.retryCount ?? 0;

        final now = DateTime.now().toIso8601String();
        await (_db.update(_db.syncOperationTable)
              ..where((t) => t.id.equals(op.id)))
            .write(
          SyncOperationTableCompanion(
            status: const Value('FAILED'),
            retryCount: Value(currentRetries + 1),
            lastError: Value(e.toString()),
            updatedAt: Value(now),
          ),
        );
      }
    }
  }

  SyncOperation _mapToDomain(SyncOperationTableData row) {
    return SyncOperation(
      id: row.id,
      entityId: row.entityId,
      entityType: _mapStringToEntityType(row.entityType),
      operationType: row.operationType,
      payloadJson: row.payloadJson,
      status: _mapStringToStatus(row.status),
      retryCount: row.retryCount,
      lastError: row.lastError,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }

  String _mapEntityTypeToString(SyncEntityType type) {
    switch (type) {
      case SyncEntityType.scan:
        return 'SCAN';
      case SyncEntityType.diagnosis:
        return 'DIAGNOSIS';
      case SyncEntityType.escalation:
        return 'ESCALATION';
    }
  }

  SyncEntityType _mapStringToEntityType(String str) {
    switch (str.toUpperCase()) {
      case 'SCAN':
        return SyncEntityType.scan;
      case 'DIAGNOSIS':
        return SyncEntityType.diagnosis;
      case 'ESCALATION':
      default:
        return SyncEntityType.escalation;
    }
  }

  String _mapStatusToString(SyncOperationStatus status) {
    switch (status) {
      case SyncOperationStatus.pending:
        return 'PENDING';
      case SyncOperationStatus.inProgress:
        return 'IN_PROGRESS';
      case SyncOperationStatus.completed:
        return 'COMPLETED';
      case SyncOperationStatus.failed:
        return 'FAILED';
    }
  }

  SyncOperationStatus _mapStringToStatus(String str) {
    switch (str.toUpperCase()) {
      case 'IN_PROGRESS':
        return SyncOperationStatus.inProgress;
      case 'COMPLETED':
        return SyncOperationStatus.completed;
      case 'FAILED':
        return SyncOperationStatus.failed;
      case 'PENDING':
      default:
        return SyncOperationStatus.pending;
    }
  }
}
