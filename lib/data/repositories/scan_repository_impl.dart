import 'dart:convert';
import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/entities/crop.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/scan.dart';
import '../../domain/entities/scan_history_item.dart';
import '../../domain/repositories/scan_repository.dart';
import '../local/database/app_database.dart';

class ScanRepositoryImpl implements ScanRepository {
  final AppDatabase db;

  ScanRepositoryImpl(this.db);

  static String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant RFC 4122
    return [
      values.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    ].join('-');
  }

  @override
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  }) async {
    final id = _generateUuid();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final companion = ScanTableCompanion.insert(
      id: id,
      userId: userId,
      cropId: cropId,
      imageLocalPath: imageLocalPath,
      status: ScanStatus.created.value,
      capturedAt: nowIso,
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    await db.into(db.scanTable).insert(companion);

    // Enqueue outbox sync operation
    final syncOpId = 'sync_scan_$id';
    final payloadJson = jsonEncode({
      'local_scan_id': id,
      'crop_id': cropId,
      'image_local_path': imageLocalPath,
      'status': ScanStatus.created.value,
      'captured_at': nowIso,
    });

    await db.into(db.syncOperationTable).insertOnConflictUpdate(
          SyncOperationTableCompanion.insert(
            id: syncOpId,
            entityId: id,
            entityType: 'SCAN',
            operationType: const Value('CREATE'),
            payloadJson: payloadJson,
            status: const Value('PENDING'),
            retryCount: const Value(0),
            createdAt: nowIso,
            updatedAt: nowIso,
          ),
        );

    final row = await (db.select(db.scanTable)..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    return _mapToEntity(row);
  }

  @override
  Future<Scan?> getScanById(String id) async {
    final query = db.select(db.scanTable)..where((tbl) => tbl.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) return null;
    return _mapToEntity(row);
  }

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {
    final nowIso = DateTime.now().toIso8601String();
    await (db.update(db.scanTable)..where((tbl) => tbl.id.equals(scanId))).write(
      ScanTableCompanion(
        status: Value(status.value),
        updatedAt: Value(nowIso),
      ),
    );

    // Update pending scan outbox operation
    final scanRow = await getScanById(scanId);
    if (scanRow != null) {
      final syncOpId = 'sync_scan_$scanId';
      final payloadJson = jsonEncode({
        'local_scan_id': scanRow.id,
        'crop_id': scanRow.cropId,
        'image_local_path': scanRow.imageLocalPath,
        'status': status.value,
        'captured_at': scanRow.capturedAt.toIso8601String(),
      });

      await db.into(db.syncOperationTable).insertOnConflictUpdate(
            SyncOperationTableCompanion.insert(
              id: syncOpId,
              entityId: scanId,
              entityType: 'SCAN',
              operationType: const Value('UPDATE'),
              payloadJson: payloadJson,
              status: const Value('PENDING'),
              retryCount: const Value(0),
              createdAt: nowIso,
              updatedAt: nowIso,
            ),
          );
    }
  }

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async {
    final scanRows = await (db.select(db.scanTable)
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .get();

    final historyItems = <ScanHistoryItem>[];

    for (final scanRow in scanRows) {
      final scanEntity = _mapToEntity(scanRow);

      final diagRow = await (db.select(db.diagnosisTable)
            ..where((t) => t.scanId.equals(scanRow.id)))
          .getSingleOrNull();

      final cropRow = await (db.select(db.cropTable)
            ..where((t) => t.id.equals(scanRow.cropId)))
          .getSingleOrNull();

      Diagnosis? diagnosisEntity;
      if (diagRow != null) {
        diagnosisEntity = _mapDiagnosisToEntity(diagRow);
      }

      Crop? cropEntity;
      if (cropRow != null) {
        cropEntity = Crop(
          id: cropRow.id,
          nameEn: cropRow.nameEn,
          nameSi: cropRow.nameSi,
          nameTa: cropRow.nameTa,
          isSupported: cropRow.isSupported == 1,
          iconAsset: cropRow.iconAsset,
        );
      }

      historyItems.add(ScanHistoryItem(
        scan: scanEntity,
        diagnosis: diagnosisEntity,
        crop: cropEntity,
      ));
    }

    return historyItems;
  }

  Scan _mapToEntity(ScanTableData row) {
    return Scan(
      id: row.id,
      remoteScanId: row.remoteScanId,
      userId: row.userId,
      cropId: row.cropId,
      imageLocalPath: row.imageLocalPath,
      imageRemoteUrl: row.imageRemoteUrl,
      status: ScanStatus.fromString(row.status),
      capturedAt: DateTime.parse(row.capturedAt),
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }

  Diagnosis _mapDiagnosisToEntity(DiagnosisTableData row) {
    List<AlternativePrediction> alternatives = [];
    if (row.alternativesJson != null) {
      try {
        final decoded = jsonDecode(row.alternativesJson!) as List<dynamic>;
        alternatives = decoded
            .map((e) => AlternativePrediction(
                  diseaseId: e['disease_id'] as String,
                  confidence: (e['confidence'] as num).toDouble(),
                ))
            .toList();
      } catch (_) {}
    }

    return Diagnosis(
      id: row.id,
      scanId: row.scanId,
      diseaseId: row.diseaseId,
      modelVersionId: row.modelVersionId,
      confidence: row.confidence,
      resultState: _resultStateFromString(row.resultState),
      severity: row.severity,
      alternatives: alternatives,
      treatmentSource: row.treatmentSource == 'LLM'
          ? TreatmentSource.llm
          : TreatmentSource.localFallback,
      treatmentGuidelineId: row.treatmentGuidelineId,
      inferredAt: row.inferredAt,
    );
  }

  DiagnosisResultState _resultStateFromString(String value) {
    switch (value) {
      case 'CONFIDENT':
        return DiagnosisResultState.confident;
      case 'LOW_CONFIDENCE':
        return DiagnosisResultState.lowConfidence;
      case 'UNSUPPORTED':
        return DiagnosisResultState.unsupported;
      default:
        return DiagnosisResultState.analysisFailed;
    }
  }
}

