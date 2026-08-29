// lib/data/repositories/sync_repository_impl.dart

import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'dart:math';
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
  Future<List<SyncOperation>> getPendingOperations({
    int maxRetries = 3,
    int? limit,
  }) async {
    final query = db.select(db.syncOperationTable)
      ..where((t) =>
          (t.status.equals('PENDING') | t.status.equals('FAILED')) &
          t.retryCount.isSmallerThanValue(maxRetries))
      // SCAN before DIAGNOSIS/ESCALATION within the batch. A diagnosis
      // payload references its scan by local id, so uploading it before its
      // scan risks the server holding a reference to a scan it has never
      // seen. createdAt ordering alone does not guarantee this.
      //
      // Sorted by an explicit priority, NOT by entityType alphabetically —
      // 'DIAGNOSIS' < 'ESCALATION' < 'SCAN', so an alphabetical sort puts
      // scans dead last, which is precisely backwards. This must also be
      // done in SQL rather than in Dart, because `limit` decides which rows
      // make it into the batch at all.
      ..orderBy([
        (t) => OrderingTerm.asc(
              const CustomExpression<int>(
                "CASE WHEN entity_type = 'SCAN' THEN 0 ELSE 1 END",
              ),
            ),
        (t) => OrderingTerm.asc(t.createdAt),
      ]);
    if (limit != null) query.limit(limit);

    final rows = await query.get();
    return rows.map(_mapToDomain).toList();
  }

  /// Resets operations stranded in IN_PROGRESS back to PENDING.
  ///
  /// An operation is marked IN_PROGRESS before its network calls. If the
  /// process dies in between — the OS kills the app, or WorkManager hits its
  /// execution-time limit mid-batch — nothing ever moved it out of that
  /// state, and the pending query ignores IN_PROGRESS, so that scan was
  /// silently excluded from sync forever. Run at startup and at the top of
  /// the background worker, i.e. both entry points that could be first after
  /// an interruption.
  @override
  Future<int> recoverStalledOperations() async {
    final now = DateTime.now().toIso8601String();
    return (db.update(db.syncOperationTable)
          ..where((t) => t.status.equals('IN_PROGRESS')))
        .write(
      SyncOperationTableCompanion(
        status: const Value('PENDING'),
        updatedAt: Value(now),
      ),
    );
  }

  @override
  Future<List<SyncOperation>> getFailedOperations() async {
    final rows = await (db.select(db.syncOperationTable)
          ..where((t) =>
              t.status.equals('PERMANENTLY_FAILED') |
              t.status.equals('AUTH_REQUIRED'))
          ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
        .get();
    return rows.map(_mapToDomain).toList();
  }

  @override
  Future<void> retryOperation(String operationId) async {
    final now = DateTime.now().toIso8601String();
    await (db.update(db.syncOperationTable)
          ..where((t) => t.id.equals(operationId)))
        .write(
      SyncOperationTableCompanion(
        status: const Value('PENDING'),
        retryCount: const Value(0),
        lastError: const Value(null),
        updatedAt: Value(now),
      ),
    );
  }

  /// Clears the AUTH_REQUIRED hold after a successful sign-in.
  @override
  Future<void> clearAuthHold() async {
    final now = DateTime.now().toIso8601String();
    await (db.update(db.syncOperationTable)
          ..where((t) => t.status.equals('AUTH_REQUIRED')))
        .write(
      SyncOperationTableCompanion(
        status: const Value('PENDING'),
        retryCount: const Value(0),
        updatedAt: Value(now),
      ),
    );
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

  /// Max operations processed per batch, so a huge backlog cannot run
  /// unbounded inside WorkManager's execution-time budget.
  static const int batchSize = 20;

  /// Safety cap per run, so one invocation cannot loop indefinitely.
  static const int maxOperationsPerRun = 200;

  /// A held lock older than this is treated as abandoned (crashed run).
  static const Duration lockStaleAfter = Duration(minutes: 5);

  @override
  Future<void> syncPendingOperations({required String authToken}) async {
    // Sync can be triggered from the UI, the connectivity listener, the
    // post-auth hook AND a WorkManager background isolate. The isolate has
    // separate memory, so an in-process flag cannot exclude it — the lock
    // lives in the database, which both can see.
    if (!await _acquireSyncLock()) return;

    try {
      // Anything stranded by a previous interrupted run is reclaimed first.
      await recoverStalledOperations();

      // Each operation gets at most ONE attempt per run. A failure leaves the
      // row FAILED with retryCount still under the limit, so without this it
      // would be picked up again by the very next batch and burn its whole
      // retry budget in a tight loop — hammering a server that is already
      // failing, instead of backing off until the next sync trigger.
      final attempted = <String>{};
      var processed = 0;

      while (processed < maxOperationsPerRun) {
        final batch = await getPendingOperations(limit: batchSize);
        final fresh = batch.where((o) => !attempted.contains(o.id)).toList();
        if (fresh.isEmpty) break;

        for (final op in fresh) {
          if (processed >= maxOperationsPerRun) break;
          attempted.add(op.id);

          await updateOperationStatus(
            operationId: op.id,
            status: SyncOperationStatus.inProgress,
          );
          try {
            await _executeOperation(op, authToken);
            await updateOperationStatus(
              operationId: op.id,
              status: SyncOperationStatus.completed,
            );
          } catch (e) {
            await _recordFailure(op, e);
          }
          processed++;
        }
      }
    } finally {
      await _releaseSyncLock();
    }
  }

  Future<void> _executeOperation(SyncOperation op, String authToken) async {
    final payload = jsonDecode(op.payloadJson) as Map<String, dynamic>;

    switch (op.entityType) {
      case SyncEntityType.scan:
        // Reuse an image already uploaded by a previous attempt. The upload
        // happens before the metadata POST, so without this a POST failure
        // would re-send the whole photo on every retry — costly on a metered
        // rural connection, and it orphans a blob remotely each time.
        final row = await (db.select(db.syncOperationTable)
              ..where((t) => t.id.equals(op.id)))
            .getSingleOrNull();
        var remoteImageUrl = row?.uploadedImageUrl;

        if (remoteImageUrl == null) {
          final imagePath = payload['image_local_path'] as String?;
          if (imagePath != null && imagePath.isNotEmpty) {
            final file = File(imagePath);
            if (await file.exists()) {
              final signed = await _apiClient.getSignedUploadUrl(
                scanId: op.entityId,
                authToken: authToken,
              );
              final bytes = await file.readAsBytes();
              await _apiClient.uploadImageBinary(
                signedUrl: signed.uploadUrl,
                imageBytes: bytes,
              );
              // The plain storage path the backend computed, NOT something
              // parsed back out of the signed upload URL - that URL's own
              // path segment is an internal storage API route, not the
              // bucket-relative path restore later needs to read this same
              // object back. See SignedUploadUrl's own docs for why these
              // two are not interchangeable.
              remoteImageUrl = signed.path;
              // Persist BEFORE the metadata POST — that is the whole point.
              await (db.update(db.syncOperationTable)
                    ..where((t) => t.id.equals(op.id)))
                  .write(
                SyncOperationTableCompanion(
                  uploadedImageUrl: Value(remoteImageUrl),
                  updatedAt: Value(DateTime.now().toIso8601String()),
                ),
              );
            }
          }
        }

        // The uploaded image's storage path must reach the metadata POST -
        // without this, the image genuinely does upload to Supabase Storage
        // and the app knows its path locally (scan.image_remote_url above),
        // but Supabase's own scan.image_url column stays NULL forever, and
        // restore (which reads exactly that column) has nothing to pull
        // back. This was a live bug: sync appeared to succeed, but a
        // restored scan came back with no photo.
        if (remoteImageUrl != null) {
          payload['image_url'] = remoteImageUrl;
        }

        await _apiClient.syncScan(scanData: payload, authToken: authToken);

        await (db.update(db.scanTable)..where((t) => t.id.equals(op.entityId)))
            .write(
          ScanTableCompanion(
            imageRemoteUrl: remoteImageUrl != null
                ? Value(remoteImageUrl)
                : const Value.absent(),
            remoteScanId: Value(op.entityId),
            updatedAt: Value(DateTime.now().toIso8601String()),
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
  }

  /// Classifies a failure instead of blindly counting a retry.
  ///
  /// Previously every error — a timeout, a 401, a malformed payload — was
  /// treated identically: increment, and after three attempts drop the
  /// operation from the pending query forever with no user-visible signal.
  Future<void> _recordFailure(SyncOperation op, Object error) async {
    final now = DateTime.now().toIso8601String();
    final status = error is SyncApiException ? error.statusCode : null;

    String newStatus;
    var retryCount = op.retryCount;

    if (status == 401 || status == 403) {
      // Token is dead. Retrying cannot succeed and would burn the budget.
      newStatus = 'AUTH_REQUIRED';
    } else if (status != null && status >= 400 && status < 500) {
      // The server rejected this payload; sending it again unchanged will
      // be rejected again.
      newStatus = 'PERMANENTLY_FAILED';
    } else {
      // Transient (timeout, 5xx, socket error): retry until the budget runs
      // out, then surface it rather than letting it disappear.
      retryCount = op.retryCount + 1;
      newStatus = retryCount >= 3 ? 'PERMANENTLY_FAILED' : 'FAILED';
    }

    await (db.update(db.syncOperationTable)..where((t) => t.id.equals(op.id)))
        .write(
      SyncOperationTableCompanion(
        status: Value(newStatus),
        retryCount: Value(retryCount),
        lastError: Value(error.toString()),
        updatedAt: Value(now),
      ),
    );
  }

  /// Returns false if another run currently holds the lock.
  Future<bool> _acquireSyncLock() async {
    return db.transaction(() async {
      final state = await (db.select(db.appStateTable)
            ..where((t) => t.id.equals(1)))
          .getSingleOrNull();

      final heldAt = state?.syncLockedAt;
      if (heldAt != null) {
        final since = DateTime.tryParse(heldAt);
        // A lock left behind by a crashed run must not block sync forever.
        if (since != null &&
            DateTime.now().difference(since) < lockStaleAfter) {
          return false;
        }
      }

      await (db.update(db.appStateTable)..where((t) => t.id.equals(1))).write(
        AppStateTableCompanion(
          syncLockedAt: Value(DateTime.now().toIso8601String()),
        ),
      );
      return true;
    });
  }

  Future<void> _releaseSyncLock() async {
    await (db.update(db.appStateTable)..where((t) => t.id.equals(1))).write(
      const AppStateTableCompanion(syncLockedAt: Value(null)),
    );
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
      case SyncOperationStatus.permanentlyFailed:
        return 'PERMANENTLY_FAILED';
      case SyncOperationStatus.authRequired:
        return 'AUTH_REQUIRED';
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
      case 'PERMANENTLY_FAILED':
        return SyncOperationStatus.permanentlyFailed;
      case 'AUTH_REQUIRED':
        return SyncOperationStatus.authRequired;
      case 'PENDING':
      default:
        return SyncOperationStatus.pending;
    }
  }
  @override
  Future<int> restoreScansFromCloud({
    required String userId,
    required String authToken,
    void Function(int restored, int total)? onProgress,
  }) async {
    var offset = 0;
    var restored = 0;
    var hasMore = true;

    // Every scan id already here, read once. Checking per row would be a query
    // per scan against a table that can hold thousands.
    final existingRemoteIds = (await (db.select(db.scanTable)
              ..where((t) => t.remoteScanId.isNotNull()))
            .get())
        .map((r) => r.remoteScanId)
        .whereType<String>()
        .toSet();

    final dir = await getApplicationDocumentsDirectory();

    while (hasMore) {
      final page = await _apiClient.fetchScans(
        authToken: authToken,
        limit: 100,
        offset: offset,
      );
      hasMore = page.hasMore;
      offset += page.scans.length;
      if (page.scans.isEmpty) break;

      for (final row in page.scans) {
        final remoteId = row['id'] as String?;
        if (remoteId == null || existingRemoteIds.contains(remoteId)) continue;

        // The photo comes down best-effort. A scan with a result and no image
        // is still worth having; failing the whole restore over one missing
        // file is not.
        var localPath = '';
        final imageUrl = row['image_url'] as String?;
        if (imageUrl != null && imageUrl.isNotEmpty) {
          localPath = await _downloadImage(imageUrl, remoteId, dir.path) ?? '';
        }

        final localScanId = (row['local_scan_id'] as String?) ?? _uuid();
        final capturedAt = (row['captured_at'] as String?) ??
            DateTime.now().toIso8601String();

        await db.into(db.scanTable).insertOnConflictUpdate(
              ScanTableCompanion.insert(
                id: localScanId,
                userId: userId,
                cropId: (row['crop_id'] as String?) ?? 'unknown',
                imageLocalPath: localPath,
                status: (row['status'] as String?) ?? 'DIAGNOSED',
                capturedAt: capturedAt,
                createdAt: capturedAt,
                updatedAt: DateTime.now().toIso8601String(),
                remoteScanId: Value(remoteId),
              ),
            );

        final diseaseId = row['disease_id'] as String?;
        if (diseaseId != null) {
          await db.into(db.diagnosisTable).insertOnConflictUpdate(
                DiagnosisTableCompanion.insert(
                  id: _uuid(),
                  scanId: localScanId,
                  // diagnosis.model_version_id is a real foreign key against
                  // model_version.id - 'restored' was never a seeded row
                  // there (main.dart seeds exactly one: 'cropcare-v1.0'), so
                  // every restored diagnosis threw a foreign key violation
                  // here, uncaught (only the image download above has its
                  // own try/catch), aborting the WHOLE restore batch. This
                  // stayed invisible until disease_id started coming back
                  // non-null on a real device, which needed the crop/disease
                  // Supabase seed fix first.
                  modelVersionId: 'cropcare-v1.0',
                  confidence: (row['confidence'] as num?)?.toDouble() ?? 0.0,
                  resultState: (row['result_state'] as String?) ?? 'CONFIDENT',
                  treatmentSource: 'LOCAL_FALLBACK',
                  inferredAt: (row['diagnosed_at'] as String?) ?? capturedAt,
                  diseaseId: Value(diseaseId),
                  severity: Value(row['severity'] as String?),
                ),
              );
        }

        existingRemoteIds.add(remoteId);
        restored++;
        onProgress?.call(restored, page.total);
      }
    }

    return restored;
  }

  /// Best-effort image download. Returns the local path, or null.
  Future<String?> _downloadImage(String url, String id, String dirPath) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) return null;
      final file = File('$dirPath/restored_$id.jpg');
      await file.writeAsBytes(response.bodyBytes);
      return file.path;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> deleteRemoteScan({
    required String remoteScanId,
    required String authToken,
  }) {
    return _apiClient.deleteRemoteScan(
      remoteScanId: remoteScanId,
      authToken: authToken,
    );
  }

  static String _uuid() {
    final r = Random();
    const chars = '0123456789abcdef';
    String block(int n) =>
        List.generate(n, (_) => chars[r.nextInt(16)]).join();
    return '${block(8)}-${block(4)}-4${block(3)}-'
        '${'89ab'[r.nextInt(4)]}${block(3)}-${block(12)}';
  }
}
