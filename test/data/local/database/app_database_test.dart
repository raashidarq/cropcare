import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';

/// Indexes the schema is expected to define. `_createIndexes` must run on
/// BOTH fresh installs and upgrades — see the regression test below.
const _expectedIndexes = {
  'idx_scan_user',
  'idx_scan_status',
  'idx_scan_captured',
  'idx_diagnosis_scan',
  'idx_sync_operation_status',
  'idx_sync_operation_entity',
  'idx_escalation_scan',
};

Future<Set<String>> _indexNames(AppDatabase db) async {
  final rows = await db
      .customSelect("SELECT name FROM sqlite_master WHERE type = 'index'")
      .get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

Future<Set<String>> _columnsOf(AppDatabase db, String table) async {
  final rows = await db.customSelect("PRAGMA table_info('$table')").get();
  return rows.map((r) => r.read<String>('name')).toSet();
}

/// Rewinds a freshly-created (v5) database at [dbFile] so it looks like a
/// genuine v4 install: v5's added columns and all indexes are removed and
/// user_version is set back, so reopening runs a real onUpgrade(4 -> 5).
Future<void> _rewindToV4(File dbFile) async {
  final seed = AppDatabase.forTesting(NativeDatabase(dbFile));
  await seed.customSelect('SELECT 1').get();

  for (final name in await _indexNames(seed)) {
    if (name.startsWith('idx_')) {
      await seed.customStatement('DROP INDEX IF EXISTS $name');
    }
  }
  // Columns added in v5 must be absent, or onUpgrade's ADD COLUMN fails.
  await seed.customStatement(
    'ALTER TABLE sync_operation DROP COLUMN uploaded_image_url',
  );
  await seed.customStatement(
    'ALTER TABLE app_state DROP COLUMN sync_locked_at',
  );
  // Assert the rewind actually took effect on THIS connection. It cannot be
  // checked after reopening, because any query on a new connection triggers
  // the migration we are trying to observe.
  final remaining = (await _indexNames(seed)).intersection(_expectedIndexes);
  if (remaining.isNotEmpty) {
    throw StateError('rewind failed, indexes still present: $remaining');
  }

  await seed.customStatement('PRAGMA user_version = 4');
  await seed.close();
}

void main() {
  group('AppDatabase schema (fresh install)', () {
    late AppDatabase db;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      await db.customSelect('SELECT 1').get(); // force migrations to run
    });

    tearDown(() async {
      await db.close();
    });

    test('schemaVersion is 6', () {
      expect(db.schemaVersion, 6);
    });

    test('creates every expected index', () async {
      final indexes = await _indexNames(db);
      expect(
        indexes.containsAll(_expectedIndexes),
        isTrue,
        reason: 'missing: ${_expectedIndexes.difference(indexes)}',
      );
    });

    test('sync_operation has uploaded_image_url (retry without re-upload)',
        () async {
      expect(
        await _columnsOf(db, 'sync_operation'),
        contains('uploaded_image_url'),
      );
    });

    test('app_state has sync_locked_at (cross-isolate advisory lock)',
        () async {
      expect(await _columnsOf(db, 'app_state'), contains('sync_locked_at'));
    });
  });

  group('AppDatabase upgrade path', () {
    late Directory tempDir;
    late File dbFile;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('cropcare_db_test_');
      dbFile = File('${tempDir.path}/cropcare.db');
    });

    tearDown(() async {
      if (await tempDir.exists()) {
        await tempDir.delete(recursive: true);
      }
    });

    test(
      'REGRESSION: an upgrading install gets the indexes too. _createIndexes '
      'used to be called only from onCreate, so every device that installed '
      'an earlier version and updated never had any indexes — exactly the '
      'long-term users with enough scan history to need them.',
      () async {
        // Leaves the file as a genuine v4 install with no indexes; throws if
        // that rewind did not take effect.
        await _rewindToV4(dbFile);

        // Reopening triggers the real onUpgrade(4 -> 5).
        final upgraded = AppDatabase.forTesting(NativeDatabase(dbFile));
        await upgraded.customSelect('SELECT 1').get();

        final indexes = await _indexNames(upgraded);
        expect(
          indexes.containsAll(_expectedIndexes),
          isTrue,
          reason: 'missing after upgrade: '
              '${_expectedIndexes.difference(indexes)}',
        );
        await upgraded.close();
      },
    );

    test('upgrading from v4 preserves existing rows (no data loss)', () async {
      final seed = AppDatabase.forTesting(NativeDatabase(dbFile));
      await seed.customSelect('SELECT 1').get();
      await seed.customStatement(
        "INSERT INTO local_user (id, is_guest, created_at, updated_at) "
        "VALUES ('user-1', 1, '2026-01-01', '2026-01-01')",
      );
      await seed.close();

      await _rewindToV4(dbFile);

      final upgraded = AppDatabase.forTesting(NativeDatabase(dbFile));
      final rows =
          await upgraded.customSelect('SELECT id FROM local_user').get();
      expect(rows.map((r) => r.read<String>('id')), contains('user-1'));

      // And the v5 additions are present afterwards.
      expect(
        await _columnsOf(upgraded, 'sync_operation'),
        contains('uploaded_image_url'),
      );
      await upgraded.close();
    });
  });
}
