import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/remote/sync_api_client.dart';
import 'package:cropcare/data/repositories/sync_repository_impl.dart';
import 'package:cropcare/domain/entities/sync_operation.dart';

/// Records calls and can be told to fail a specific step, so the tests can
/// reproduce partial failures (upload succeeds, metadata POST does not).
class _FakeSyncApiClient extends SyncApiClient {
  int signedUrlCalls = 0;
  int uploadCalls = 0;
  int syncScanCalls = 0;

  Object? syncScanError;

  /// Every scanData map syncScan was actually called with, so tests can
  /// assert what really reached the "server" - not just that a call
  /// happened.
  final List<Map<String, dynamic>> syncedScanPayloads = [];

  @override
  Future<SignedUploadUrl> getSignedUploadUrl({
    required String scanId,
    required String authToken,
  }) async {
    signedUrlCalls++;
    // Deliberately a DIFFERENT shape from the real storage path, the same
    // way a real signed upload URL is: an internal storage API route, not
    // the plain bucket-relative path. A fix that accidentally parses this
    // URL instead of using SignedUploadUrl.path would produce the wrong
    // value and this fake would not catch it - the regression test below
    // asserts the actual path value for exactly that reason.
    return SignedUploadUrl(
      uploadUrl: 'https://storage.example.com/object/upload/sign/'
          'scan-images/user-1/$scanId.jpg?token=abc',
      path: 'user-1/$scanId.jpg',
    );
  }

  @override
  Future<void> uploadImageBinary({
    required String signedUrl,
    required List<int> imageBytes,
    String contentType = 'image/jpeg',
  }) async {
    uploadCalls++;
  }

  @override
  Future<void> syncScan({
    required Map<String, dynamic> scanData,
    required String authToken,
  }) async {
    syncScanCalls++;
    syncedScanPayloads.add(scanData);
    if (syncScanError != null) throw syncScanError!;
  }

  @override
  Future<Map<String, dynamic>> fetchReferenceData({
    String? since,
    required String authToken,
  }) async =>
      <String, dynamic>{};
}

void main() {
  late AppDatabase db;
  late _FakeSyncApiClient api;
  late SyncRepositoryImpl repo;
  late Directory tempDir;
  late File imageFile;

  const scanId = 'scan-1';
  const opId = 'sync_scan_scan-1';

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = _FakeSyncApiClient();
    repo = SyncRepositoryImpl(db: db, apiClient: api);

    tempDir = await Directory.systemTemp.createTemp('cropcare_sync_test_');
    imageFile = File('${tempDir.path}/leaf.jpg');
    await imageFile.writeAsBytes(List.filled(2048, 7));

    // app_state singleton is required for the advisory lock.
    await db.into(db.appStateTable).insertOnConflictUpdate(
          AppStateTableCompanion.insert(id: const Value(1)),
        );
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  Future<void> insertScanOp({String status = 'PENDING'}) async {
    final now = DateTime.now().toIso8601String();
    await db.into(db.syncOperationTable).insertOnConflictUpdate(
          SyncOperationTableCompanion.insert(
            id: opId,
            entityId: scanId,
            entityType: 'SCAN',
            payloadJson: jsonEncode({
              'local_scan_id': scanId,
              'image_local_path': imageFile.path,
            }),
            status: Value(status),
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<SyncOperationTableData> opRow() => (db.select(db.syncOperationTable)
        ..where((t) => t.id.equals(opId)))
      .getSingle();

  group('stalled-operation recovery', () {
    test(
      'REGRESSION: an operation stranded in IN_PROGRESS is returned to '
      'PENDING. Previously nothing reset it, and the pending query ignores '
      'IN_PROGRESS, so a scan interrupted mid-sync was excluded from every '
      'future sync forever, silently.',
      () async {
        await insertScanOp(status: 'IN_PROGRESS');
        expect(await repo.getPendingCount(), 0, reason: 'precondition');

        final recovered = await repo.recoverStalledOperations();

        expect(recovered, 1);
        expect((await opRow()).status, 'PENDING');
        expect(await repo.getPendingCount(), 1);
      },
    );
  });

  group('retry without re-upload', () {
    test(
      'a metadata POST failure after a successful upload does not re-upload '
      'the image on the next attempt',
      () async {
        await insertScanOp();

        // First run: upload succeeds, metadata POST fails (500 = transient).
        api.syncScanError = SyncApiException('server exploded', 500);
        await repo.syncPendingOperations(authToken: 'token');

        expect(api.uploadCalls, 1);
        final afterFirst = await opRow();
        expect(afterFirst.status, 'FAILED');
        expect(
          afterFirst.uploadedImageUrl,
          isNotNull,
          reason: 'uploaded URL must be persisted before the POST is tried',
        );

        // Second run succeeds; the image must NOT be uploaded again.
        api.syncScanError = null;
        await repo.syncPendingOperations(authToken: 'token');

        expect(api.uploadCalls, 1, reason: 'image re-uploaded on retry');
        expect(api.syncScanCalls, 2);
        expect((await opRow()).status, 'COMPLETED');
      },
    );
  });

  group('the uploaded image reaches the metadata sync, not just storage', () {
    // Live bug: the image genuinely uploaded to Supabase Storage, and the
    // app knew its remote path locally (scan.image_remote_url) - but
    // scan.image_url on the metadata POST was never set, so Supabase's own
    // scan row had a NULL image_url forever. Sync looked successful; a
    // restore on another device came back with no photo, because restore
    // reads exactly that column.
    test(
      'a fresh upload sends the storage path (not the signed upload URL) '
      'as image_url',
      () async {
        await insertScanOp();
        await repo.syncPendingOperations(authToken: 'token');

        expect(api.syncedScanPayloads, hasLength(1));
        expect(
          api.syncedScanPayloads.single['image_url'],
          'user-1/$scanId.jpg',
          reason: 'must be the plain storage path the backend computed, '
              'not the signed upload URL (which carries a different, '
              'internal API path plus a signing token) and not missing',
        );
      },
    );

    test(
      'a retry that reuses a previously uploaded image still includes its '
      'path on the metadata payload',
      () async {
        await insertScanOp();
        api.syncScanError = SyncApiException('server exploded', 500);
        await repo.syncPendingOperations(authToken: 'token');

        api.syncScanError = null;
        await repo.syncPendingOperations(authToken: 'token');

        expect(api.syncedScanPayloads, hasLength(2));
        for (final payload in api.syncedScanPayloads) {
          expect(payload['image_url'], 'user-1/$scanId.jpg');
        }
      },
    );
  });

  group('failure classification', () {
    test('a 4xx is PERMANENTLY_FAILED immediately, not retried 3 times',
        () async {
      await insertScanOp();
      api.syncScanError = SyncApiException('bad payload', 422);

      await repo.syncPendingOperations(authToken: 'token');

      final row = await opRow();
      expect(row.status, 'PERMANENTLY_FAILED');
      expect(row.retryCount, 0, reason: 'should not consume retry budget');
      expect(await repo.getPendingCount(), 0);
    });

    test('a 401 is held as AUTH_REQUIRED rather than burning retries',
        () async {
      await insertScanOp();
      api.syncScanError = SyncApiException('token expired', 401);

      await repo.syncPendingOperations(authToken: 'stale-token');

      final row = await opRow();
      expect(row.status, 'AUTH_REQUIRED');
      expect(row.retryCount, 0);

      // Signing in again releases the hold.
      await repo.clearAuthHold();
      expect((await opRow()).status, 'PENDING');
    });

    test(
      'a transient failure retries, then becomes PERMANENTLY_FAILED and stays '
      'visible instead of silently disappearing',
      () async {
        await insertScanOp();
        api.syncScanError = SyncApiException('timeout', 503);

        for (var i = 0; i < 3; i++) {
          await repo.syncPendingOperations(authToken: 'token');
        }

        final row = await opRow();
        expect(row.retryCount, 3);
        expect(row.status, 'PERMANENTLY_FAILED');
        expect(await repo.getPendingCount(), 0);

        final failed = await repo.getFailedOperations();
        expect(failed.map((o) => o.id), contains(opId));
        expect(failed.single.status, SyncOperationStatus.permanentlyFailed);
      },
    );

    test('a permanently failed operation can be retried by the user',
        () async {
      await insertScanOp();
      api.syncScanError = SyncApiException('bad payload', 400);
      await repo.syncPendingOperations(authToken: 'token');
      expect((await opRow()).status, 'PERMANENTLY_FAILED');

      await repo.retryOperation(opId);

      final row = await opRow();
      expect(row.status, 'PENDING');
      expect(row.retryCount, 0);
      expect(row.lastError, isNull);
    });
  });

  group('advisory lock', () {
    test('a run is skipped while another holds the lock', () async {
      await insertScanOp();

      // Simulate a concurrent run (e.g. the WorkManager isolate) holding it.
      await (db.update(db.appStateTable)..where((t) => t.id.equals(1))).write(
        AppStateTableCompanion(
          syncLockedAt: Value(DateTime.now().toIso8601String()),
        ),
      );

      await repo.syncPendingOperations(authToken: 'token');

      expect(api.syncScanCalls, 0, reason: 'should not double-process');
      expect((await opRow()).status, 'PENDING');
    });

    test('a stale lock from a crashed run does not block sync forever',
        () async {
      await insertScanOp();
      final stale = DateTime.now()
          .subtract(SyncRepositoryImpl.lockStaleAfter * 2)
          .toIso8601String();
      await (db.update(db.appStateTable)..where((t) => t.id.equals(1)))
          .write(AppStateTableCompanion(syncLockedAt: Value(stale)));

      await repo.syncPendingOperations(authToken: 'token');

      expect(api.syncScanCalls, 1);
      expect((await opRow()).status, 'COMPLETED');
    });

    test('the lock is released after a run completes', () async {
      await insertScanOp();
      await repo.syncPendingOperations(authToken: 'token');

      final state = await (db.select(db.appStateTable)
            ..where((t) => t.id.equals(1)))
          .getSingle();
      expect(state.syncLockedAt, isNull);
    });
  });

  group('ordering', () {
    test('SCAN operations are processed before DIAGNOSIS ones', () async {
      final now = DateTime.now();
      // Diagnosis enqueued FIRST, so createdAt order alone would send it
      // before its scan exists remotely.
      await db.into(db.syncOperationTable).insertOnConflictUpdate(
            SyncOperationTableCompanion.insert(
              id: 'sync_diag_1',
              entityId: 'diag-1',
              entityType: 'DIAGNOSIS',
              payloadJson: jsonEncode({'local_scan_id': scanId}),
              createdAt: now
                  .subtract(const Duration(minutes: 5))
                  .toIso8601String(),
              updatedAt: now.toIso8601String(),
            ),
          );
      await insertScanOp();

      final ops = await repo.getPendingOperations();

      expect(ops.first.entityType, SyncEntityType.scan);
    });
  });
}
