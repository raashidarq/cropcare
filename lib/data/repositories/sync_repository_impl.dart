// lib/data/repositories/sync_repository_impl.dart

import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';

import '../../domain/entities/sync_operation.dart';
import '../../domain/repositories/sync_repository.dart';
import '../local/database/app_database.dart';
import '../remote/sync_api_client.dart';

class SyncRepositoryImpl implements SyncRepository {
  final AppDatabase db;
  final SyncApiClient _apiClient;

  SyncRepositoryImpl({
    required this.db,
    SyncApiClient? apiClient,
  }) : _apiClient = apiClient ?? SyncApiClient();

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
    final existing = await (db.select(db.syncOperationTable)
          ..where((t) =>
              t.entityId.equals(entityId) &
              t.entityType.equals(typeStr) &
              t.status.equals('PENDING')))
        .getSingleOrNull();

    if (existing != null) {
      await (db.update(db.syncOperationTable)
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
      await db.into(db.syncOperationTable).insert(
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
    final rows = await (db.select(db.syncOperationTable)
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
    final countExp = db.syncOperationTable.id.count();
    final query = db.selectOnly(db.syncOperationTable)
      ..addColumns([countExp])
      ..where((db.syncOperationTable.status.equals('PENDING') |
              db.syncOperationTable.status.equals('FAILED')) &
          db.syncOperationTable.retryCount.isSmallerThanValue(3));

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

    await (db.update(db.syncOperationTable)
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
            String? remoteImageUrl;
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
                final uri = Uri.tryParse(signedUrl);
                if (uri != null) {
                  remoteImageUrl = '${uri.scheme}://${uri.host}${uri.path}';
                }
              }
            }
            await _apiClient.syncScan(
              scanData: payload,
              authToken: authToken,
            );

            // Enrich local scan record with remote scan id and remote image url
            final scanNow = DateTime.now().toIso8601String();
            await (db.update(db.scanTable)..where((t) => t.id.equals(op.entityId)))
                .write(
              ScanTableCompanion(
                imageRemoteUrl: remoteImageUrl != null ? Value(remoteImageUrl) : const Value.absent(),
                remoteScanId: Value(op.entityId),
                updatedAt: Value(scanNow),
              ),
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
        final row = await (db.select(db.syncOperationTable)
              ..where((t) => t.id.equals(op.id)))
            .getSingleOrNull();
        final currentRetries = row?.retryCount ?? 0;

        final now = DateTime.now().toIso8601String();
        await (db.update(db.syncOperationTable)
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

  @override
  Future<void> syncReferenceData({required String authToken}) async {
    final appState = await (db.select(db.appStateTable)..where((t) => t.id.equals(1))).getSingleOrNull();
    final since = appState?.lastSyncAt;

    final data = await _apiClient.fetchReferenceData(
      since: since,
      authToken: authToken,
    );

    // Upsert crops if present in downstream payload
    if (data.containsKey('crops') && data['crops'] is List) {
      for (final crop in data['crops'] as List) {
        if (crop is Map<String, dynamic>) {
          await db.into(db.cropTable).insertOnConflictUpdate(
                CropTableCompanion.insert(
                  id: crop['id'] as String,
                  nameEn: crop['name_en'] as String? ?? crop['name'] as String? ?? 'Crop',
                  nameSi: Value(crop['name_si'] as String?),
                  nameTa: Value(crop['name_ta'] as String?),
                  isSupported: Value(crop['is_supported'] == false ? 0 : 1),
                  iconAsset: Value(crop['icon_asset'] as String?),
                ),
              );
        }
      }
    }

    // Upsert diseases if present in downstream payload
    if (data.containsKey('diseases') && data['diseases'] is List) {
      for (final disease in data['diseases'] as List) {
        if (disease is Map<String, dynamic>) {
          await db.into(db.diseaseTable).insertOnConflictUpdate(
                DiseaseTableCompanion.insert(
                  id: disease['id'] as String,
                  cropId: disease['crop_id'] as String,
                  nameEn: disease['name_en'] as String? ?? disease['name'] as String? ?? 'Disease',
                  nameSi: Value(disease['name_si'] as String?),
                  nameTa: Value(disease['name_ta'] as String?),
                  severityDefault: Value(disease['severity_default'] as String?),
                ),
              );
        }
      }
    }

    // Upsert treatment guidelines if present in downstream payload
    if (data.containsKey('guidelines') && data['guidelines'] is List) {
      for (final g in data['guidelines'] as List) {
        if (g is Map<String, dynamic>) {
          await db.into(db.treatmentGuidelineTable).insertOnConflictUpdate(
                TreatmentGuidelineTableCompanion.insert(
                  id: g['id'] as String,
                  diseaseId: g['disease_id'] as String,
                  guidelineVersion: g['guideline_version'] as String? ?? 'v1.0',
                  summaryEn: Value(g['summary_en'] as String?),
                  summarySi: Value(g['summary_si'] as String?),
                  summaryTa: Value(g['summary_ta'] as String?),
                  whatToDoEn: Value(g['what_to_do_en'] as String?),
                  whatToDoSi: Value(g['what_to_do_si'] as String?),
                  whatToDoTa: Value(g['what_to_do_ta'] as String?),
                  whatToAvoidEn: Value(g['what_to_avoid_en'] as String?),
                  whatToAvoidSi: Value(g['what_to_avoid_si'] as String?),
                  whatToAvoidTa: Value(g['what_to_avoid_ta'] as String?),
                  recheckAfterDays: Value(g['recheck_after_days'] as int?),
                  publishedAt: Value(g['published_at'] as String?),
                ),
              );
        }
      }
    }

    // Update lastSyncAt timestamp
    final nowIso = DateTime.now().toIso8601String();
    await (db.update(db.appStateTable)..where((t) => t.id.equals(1))).write(
      AppStateTableCompanion(lastSyncAt: Value(nowIso)),
    );
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
