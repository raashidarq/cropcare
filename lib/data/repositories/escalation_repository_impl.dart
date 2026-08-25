// lib/data/repositories/escalation_repository_impl.dart
//
// Concrete implementation of EscalationRepository via Drift.

import 'dart:convert';
import 'package:drift/drift.dart';

import '../../domain/entities/escalation.dart';
import '../../domain/repositories/escalation_repository.dart';
import '../local/database/app_database.dart';

class EscalationRepositoryImpl implements EscalationRepository {
  final AppDatabase db;

  EscalationRepositoryImpl(this.db);

  @override
  Future<Escalation> createEscalation(Escalation escalation) async {
    final companion = EscalationTableCompanion.insert(
      id: escalation.id,
      scanId: escalation.scanId,
      diagnosisId: escalation.diagnosisId,
      notes: Value(escalation.notes),
      sharedVia: Value(escalation.sharedVia),
      sharedAt: Value(escalation.sharedAt),
      createdAt: escalation.createdAt,
    );

    await db.into(db.escalationTable).insertOnConflictUpdate(companion);

    // Enqueue outbox sync operation
    final syncOpId = 'sync_esc_${escalation.id}';
    final payloadJson = jsonEncode({
      'local_escalation_id': escalation.id,
      'local_scan_id': escalation.scanId,
      'notes': escalation.notes,
      'shared_via': escalation.sharedVia,
      'shared_at': escalation.sharedAt,
      'created_at': escalation.createdAt,
    });

    final nowIso = DateTime.now().toIso8601String();
    await db.into(db.syncOperationTable).insertOnConflictUpdate(
          SyncOperationTableCompanion.insert(
            id: syncOpId,
            entityId: escalation.id,
            entityType: 'ESCALATION',
            operationType: const Value('CREATE'),
            payloadJson: payloadJson,
            status: const Value('PENDING'),
            retryCount: const Value(0),
            createdAt: nowIso,
            updatedAt: nowIso,
          ),
        );

    return escalation;
  }

  @override
  Future<List<Escalation>> getEscalationsByScanId(String scanId) async {
    final rows = await (db.select(db.escalationTable)
          ..where((t) => t.scanId.equals(scanId)))
        .get();

    return rows
        .map((r) => Escalation(
              id: r.id,
              scanId: r.scanId,
              diagnosisId: r.diagnosisId,
              notes: r.notes,
              sharedVia: r.sharedVia,
              sharedAt: r.sharedAt,
              createdAt: r.createdAt,
            ))
        .toList();
  }
}
