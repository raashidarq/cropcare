// lib/data/local/database/app_database.dart
//
// Drift database class for CropCare.
// Run `flutter pub run build_runner build` after any schema change
// to regenerate app_database.g.dart.

import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  AppStateTable,
  LocalUserTable,
  CropTable,
  DiseaseTable,
  TreatmentGuidelineTable,
  ModelVersionTable,
  ScanTable,
  ImageValidationTable,
  DiagnosisTable,
  EscalationTable,
  SyncOperationTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Expose a constructor that accepts a custom [QueryExecutor] so that
  /// unit tests can pass an in-memory database without touching the filesystem.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes(customStatement);
        },
        onUpgrade: (Migrator m, int from, int to) async {
          if (from < 2) {
            await m.addColumn(localUserTable, localUserTable.email);
          }
          if (from < 3) {
            await m.createTable(escalationTable);
          }
          if (from < 4) {
            await m.createTable(syncOperationTable);
          }
        },
      );

  // ---------------------------------------------------------------------------
  // Index creation
  // Drift does not have a first-class Index DSL yet (as of v2.x); we create
  // the three required indexes as raw DDL statements executed once on onCreate.
  // ---------------------------------------------------------------------------
  Future<void> _createIndexes(
    Future<void> Function(String sql, List<dynamic> args) exec,
  ) async {
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_scan_user ON scan(user_id)',
      const [],
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_scan_status ON scan(status)',
      const [],
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_scan_captured ON scan(captured_at)',
      const [],
    );
    await exec(
      'CREATE INDEX IF NOT EXISTS idx_diagnosis_scan ON diagnosis(scan_id)',
      const [],
    );
  }
}

/// Opens (or creates) the SQLite file in the app's documents directory.
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'cropcare.db'));
    return NativeDatabase.createInBackground(file);
  });
}
