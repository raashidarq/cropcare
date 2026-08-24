// lib/data/repositories/escalation_repository_impl.dart
//
// Concrete implementation of EscalationRepository via Drift.

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
