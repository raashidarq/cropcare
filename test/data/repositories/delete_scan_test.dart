// Deleting one scan has to take everything attached to it.
//
// Foreign keys are not enforced at runtime in this database, so a missed
// table does not error — it leaves an orphan that nothing ever cleans up and
// nothing ever reports. `deleteAllLocalScans` had exactly that bug for
// chat_message after schema v7 added it.

import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/repositories/scan_repository_impl.dart';

void main() {
  late AppDatabase db;
  late ScanRepositoryImpl repo;
  late Directory tempDir;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    repo = ScanRepositoryImpl(db);
    tempDir = await Directory.systemTemp.createTemp('cropcare_del_');
  });

  tearDown(() async {
    await db.close();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// Builds a scan with a diagnosis, a chat message, a validation row, an
  /// escalation, a queued sync op, and a real file on disk.
  Future<File> seedFullScan(String scanId) async {
    final image = File('${tempDir.path}/$scanId.jpg');
    await image.writeAsBytes([1, 2, 3]);

    await db.customStatement(
      "INSERT INTO scan (id, user_id, crop_id, image_local_path, status, "
      "captured_at, created_at, updated_at) VALUES "
      "('$scanId', 'user-1', 'tomato', '${image.path.replaceAll(r'\', r'\\')}', "
      "'DIAGNOSED', '2026-08-24T12:00:00Z', '2026-08-24T12:00:00Z', "
      "'2026-08-24T12:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO diagnosis (id, scan_id, disease_id, model_version_id, "
      "confidence, result_state, treatment_source, inferred_at) VALUES "
      "('diag-$scanId', '$scanId', 'tomato_early_blight', 'v1', 0.9, "
      "'CONFIDENT', 'LOCAL_FALLBACK', '2026-08-24T12:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO chat_message (id, diagnosis_id, role, content, "
      "language_code, status, created_at) VALUES "
      "('msg-$scanId', 'diag-$scanId', 'USER', 'Will it spread?', 'en', "
      "'SENT', '2026-08-24T12:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO image_validation (id, scan_id, is_usable, checked_at) "
      "VALUES ('val-$scanId', '$scanId', 1, '2026-08-24T12:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO sync_operation (id, entity_id, entity_type, operation_type, "
      "payload_json, status, retry_count, created_at, updated_at) VALUES "
      "('op-$scanId', '$scanId', 'SCAN', 'CREATE', '{}', 'PENDING', 0, "
      "'2026-08-24T12:00:00Z', '2026-08-24T12:00:00Z')",
    );
    return image;
  }

  Future<int> count(String table, [String? where]) async {
    final rows = await db
        .customSelect('SELECT COUNT(*) AS c FROM $table'
            '${where != null ? ' WHERE $where' : ''}')
        .get();
    return rows.first.read<int>('c');
  }

  test('deleting a scan removes every row that belonged to it', () async {
    await seedFullScan('scan-1');
    await repo.deleteScan('scan-1');

    expect(await count('scan'), 0, reason: 'scan row');
    expect(await count('diagnosis'), 0, reason: 'diagnosis row');
    expect(await count('chat_message'), 0,
        reason: 'chat hangs off diagnosis, not scan — easy to miss');
    expect(await count('image_validation'), 0, reason: 'validation row');
    expect(await count('sync_operation'), 0, reason: 'queued upload');
  });

  test('the photo is removed from disk, not just the database', () async {
    final image = await seedFullScan('scan-2');
    expect(await image.exists(), isTrue);

    await repo.deleteScan('scan-2');

    // A row-only delete leaves the file forever, which matters on a nearly
    // full budget phone — the same bug deleteAllLocalScans used to have.
    expect(await image.exists(), isFalse);
  });

  test('a queued upload is cancelled so a deleted photo is not sent later',
      () async {
    await seedFullScan('scan-3');
    expect(await count('sync_operation'), 1);

    await repo.deleteScan('scan-3');

    expect(await count('sync_operation'), 0,
        reason: 'uploading a photo the farmer just deleted wastes their data');
  });

  test('an in-flight upload is left alone', () async {
    await seedFullScan('scan-4');
    await db.customStatement(
      "UPDATE sync_operation SET status = 'IN_PROGRESS' WHERE entity_id = 'scan-4'",
    );

    await repo.deleteScan('scan-4');

    // A request already on the wire cannot be recalled, and deleting its row
    // would only hide it from the sync failure UI.
    expect(await count('sync_operation'), 1);
  });

  test('other scans are untouched', () async {
    await seedFullScan('scan-a');
    await seedFullScan('scan-b');

    await repo.deleteScan('scan-a');

    expect(await count('scan'), 1);
    expect(await count('scan', "id = 'scan-b'"), 1);
    expect(await count('diagnosis', "scan_id = 'scan-b'"), 1);
    expect(await count('chat_message', "diagnosis_id = 'diag-scan-b'"), 1);
  });

  test('deleting a scan that does not exist is harmless', () async {
    await seedFullScan('scan-5');
    await repo.deleteScan('no-such-scan');
    expect(await count('scan'), 1);
  });

  test('deleteAllLocalScans clears chat transcripts too', () async {
    await seedFullScan('scan-6');
    await repo.deleteAllLocalScans();

    // Regression: chat_message arrived in schema v7 and this method was not
    // updated, so every "free up storage" left transcripts behind pointing at
    // diagnoses that no longer existed.
    expect(await count('chat_message'), 0);
    expect(await count('scan'), 0);
    expect(await count('diagnosis'), 0);
  });
}
