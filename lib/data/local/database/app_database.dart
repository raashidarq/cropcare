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
  DiseaseExplanationTable,
  DiseaseConfusionTable,
  ChatMessageTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Expose a constructor that accepts a custom [QueryExecutor] so that
  /// unit tests can pass an in-memory database without touching the filesystem.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 8;

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
          if (from < 5) {
            await m.addColumn(
              syncOperationTable,
              syncOperationTable.uploadedImageUrl,
            );
            await m.addColumn(appStateTable, appStateTable.syncLockedAt);
          }
          if (from < 6) {
            // Offline explanation content. Both tables ship empty — the
            // content is authored and delivered separately — so there is
            // nothing to backfill here.
            await m.createTable(diseaseExplanationTable);
            await m.createTable(diseaseConfusionTable);
          }
          if (from < 7) {
            // Follow-up chat about a diagnosis. Nothing to backfill: a device
            // upgrading has no prior conversations.
            await m.createTable(chatMessageTable);
          }
          if (from < 8) {
            // On-device cache of the AI-written treatment response, so
            // re-opening a diagnosis doesn't re-ask the LLM for something
            // already answered. Nothing to backfill: a device upgrading has
            // no prior cached responses to migrate in, it just starts
            // caching from the next fetch onward.
            await m.addColumn(diagnosisTable, diagnosisTable.aiTreatmentJson);
            await m.addColumn(
              diagnosisTable,
              diagnosisTable.aiTreatmentFetchedAt,
            );
          }

          // Indexes were previously only created in onCreate, so ANY device
          // that installed an earlier version and upgraded never had them —
          // i.e. every real long-term user, precisely the ones with enough
          // scan history for the missing indexes to hurt. Re-run on every
          // upgrade; the statements are IF NOT EXISTS, so this is idempotent
          // and safe to repeat.
          await _createIndexes(customStatement);
        },
      );

  // ---------------------------------------------------------------------------
  // Index creation
  // Drift has no first-class Index DSL (as of v2.x), so these are raw DDL.
  // Called from BOTH onCreate and onUpgrade — see the note in onUpgrade.
  // Every statement is IF NOT EXISTS and therefore idempotent.
  // ---------------------------------------------------------------------------
  Future<void> _createIndexes(
    Future<void> Function(String sql, List<dynamic> args) exec,
  ) async {
    const statements = [
      // Scan history: filtered by user, by status, ordered by capture time.
      'CREATE INDEX IF NOT EXISTS idx_scan_user ON scan(user_id)',
      'CREATE INDEX IF NOT EXISTS idx_scan_status ON scan(status)',
      'CREATE INDEX IF NOT EXISTS idx_scan_captured ON scan(captured_at)',
      // Joined per scan when building history.
      'CREATE INDEX IF NOT EXISTS idx_diagnosis_scan ON diagnosis(scan_id)',
      // Explanation lookups are always by disease.
      'CREATE INDEX IF NOT EXISTS idx_disease_explanation_disease '
          'ON disease_explanation(disease_id)',
      'CREATE INDEX IF NOT EXISTS idx_disease_confusion_disease '
          'ON disease_confusion(disease_id)',
      // The outbox is queried by status on every sync run and every pending
      // count refresh, which happens far more often than a scan is created.
      'CREATE INDEX IF NOT EXISTS idx_sync_operation_status '
          'ON sync_operation(status)',
      'CREATE INDEX IF NOT EXISTS idx_sync_operation_entity '
          'ON sync_operation(entity_id, entity_type)',
      // Looked up by scan when rendering history rows and escalations.
      'CREATE INDEX IF NOT EXISTS idx_escalation_scan ON escalation(scan_id)',
      // Every chat read is "the transcript for this diagnosis".
      'CREATE INDEX IF NOT EXISTS idx_chat_message_diagnosis '
          'ON chat_message(diagnosis_id)',
    ];
    for (final sql in statements) {
      await exec(sql, const []);
    }
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
