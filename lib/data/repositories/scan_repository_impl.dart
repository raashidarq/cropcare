import 'dart:convert';
import 'dart:io';
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
  Future<void> updateScanCrop(String scanId, String cropId) async {
    final nowIso = DateTime.now().toIso8601String();
    await (db.update(db.scanTable)..where((tbl) => tbl.id.equals(scanId))).write(
      ScanTableCompanion(
        cropId: Value(cropId),
        updatedAt: Value(nowIso),
      ),
    );

    // Update pending scan outbox operation if exists
    final scanRow = await getScanById(scanId);
    if (scanRow != null) {
      final syncOpId = 'sync_scan_$scanId';
      final payloadJson = jsonEncode({
        'local_scan_id': scanRow.id,
        'crop_id': cropId,
        'image_local_path': scanRow.imageLocalPath,
        'status': scanRow.status.value,
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
  Future<int> purgeFailedScans() async {
    final failed = await (db.select(db.scanTable)
          ..where((t) => t.status.isIn(_failedScanStatuses)))
        .get();

    // Also catch scans whose inference failed: those carry an
    // ANALYSIS_FAILED diagnosis but may still sit at their original status.
    final failedDiagnoses = await (db.select(db.diagnosisTable)
          ..where((t) => t.resultState.equals('ANALYSIS_FAILED')))
        .get();

    final ids = <String>{
      ...failed.map((r) => r.id),
      ...failedDiagnoses.map((d) => d.scanId),
    };
    if (ids.isEmpty) return 0;

    final paths = <String>[
      ...failed.map((r) => r.imageLocalPath),
      for (final row in await (db.select(db.scanTable)
            ..where((t) => t.id.isIn(ids.toList())))
          .get())
        row.imageLocalPath,
    ];

    await db.transaction(() async {
      final idList = ids.toList();
      await (db.delete(db.escalationTable)
            ..where((t) => t.scanId.isIn(idList)))
          .go();
      await (db.delete(db.diagnosisTable)..where((t) => t.scanId.isIn(idList)))
          .go();
      await (db.delete(db.imageValidationTable)
            ..where((t) => t.scanId.isIn(idList)))
          .go();
      await (db.delete(db.syncOperationTable)
            ..where((t) => t.entityId.isIn(idList)))
          .go();
      await (db.delete(db.scanTable)..where((t) => t.id.isIn(idList))).go();
    });

    for (final path in paths.toSet()) {
      try {
        final file = File(path);
        if (await file.exists()) await file.delete();
      } catch (_) {}
    }

    return ids.length;
  }

  @override
  Future<void> rejectInvalidScan({
    required String scanId,
    required String rejectionReason,
  }) async {
    final nowIso = DateTime.now().toIso8601String();
    final scanRow = await getScanById(scanId);

    await db.transaction(() async {
      // Record WHY the image was rejected — this is exactly what the
      // image_validation table exists for, and previously no row was ever
      // written on the rejection path (the caller returned early before
      // RunDiagnosisUseCase, the only writer, was reached).
      await db.into(db.imageValidationTable).insertOnConflictUpdate(
            ImageValidationTableCompanion.insert(
              id: _generateUuid(),
              scanId: scanId,
              isUsable: 0,
              rejectionReason: Value(rejectionReason),
              checkedAt: nowIso,
            ),
          );

      await (db.update(db.scanTable)..where((t) => t.id.equals(scanId))).write(
        ScanTableCompanion(
          status: Value(ScanStatus.invalidImage.value),
          updatedAt: Value(nowIso),
        ),
      );

      // Cancel the queued upload. createScan() already enqueued a SCAN
      // outbox op; without this a rejected photo (a desk, a blurry frame)
      // would still be uploaded to cloud storage — wasted bandwidth on a
      // metered rural connection and wasted remote storage.
      await (db.delete(db.syncOperationTable)
            ..where((t) =>
                t.entityId.equals(scanId) &
                t.entityType.equals('SCAN') &
                t.status.isIn(const ['PENDING', 'FAILED'])))
          .go();
    });

    // Best-effort local file cleanup — the DB is already consistent if this
    // fails, and an orphaned file is better than a failed rejection.
    final path = scanRow?.imageLocalPath;
    if (path != null) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  /// Scan statuses that represent an attempt that produced no usable result.
  /// History is a record of what the farmer has checked, not a log of every
  /// button press, so these are excluded.
  static const List<String> _failedScanStatuses = [
    'INVALID_IMAGE',
    'ANALYSIS_FAILED',
    'USER_CANCELLED',
  ];

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async {
    final scanRows = await (db.select(db.scanTable)
          ..where((t) => t.status.isNotIn(_failedScanStatuses))
          ..orderBy([(t) => OrderingTerm.desc(t.capturedAt)]))
        .get();

    if (scanRows.isEmpty) return const [];

    // Three queries total, regardless of history size.
    //
    // This previously issued 1 query for the scans and then TWO MORE PER ROW
    // (diagnosis + crop) — 2N+1 round trips. On a device with a few hundred
    // scans that is several hundred sequential SQLite calls just to draw the
    // home screen, on hardware where that is slow enough to see.
    final scanIds = scanRows.map((r) => r.id).toList();
    final cropIds = scanRows.map((r) => r.cropId).toSet().toList();

    final diagRows = await (db.select(db.diagnosisTable)
          ..where((t) => t.scanId.isIn(scanIds)))
        .get();
    final cropRows = await (db.select(db.cropTable)
          ..where((t) => t.id.isIn(cropIds)))
        .get();

    final diagByScanId = <String, DiagnosisTableData>{
      for (final d in diagRows) d.scanId: d,
    };
    final cropById = <String, Crop>{
      for (final c in cropRows)
        c.id: Crop(
          id: c.id,
          nameEn: c.nameEn,
          nameSi: c.nameSi,
          nameTa: c.nameTa,
          isSupported: c.isSupported == 1,
          iconAsset: c.iconAsset,
        ),
    };

    return [
      for (final scanRow in scanRows)
        ScanHistoryItem(
          scan: _mapToEntity(scanRow),
          diagnosis: diagByScanId[scanRow.id] == null
              ? null
              : _mapDiagnosisToEntity(diagByScanId[scanRow.id]!),
          crop: cropById[scanRow.cropId],
        ),
    ];
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

  @override
  Future<void> deleteScan(String scanId) async {
    // Read the path before the row goes, or the file becomes an unreachable
    // orphan — the same mistake deleteAllLocalScans used to make.
    final scanRow = await getScanById(scanId);

    await db.transaction(() async {
      // chat_message hangs off diagnosis, not scan, so its rows have to be
      // found through the diagnoses being removed.
      final diagnosisIds = (await (db.select(db.diagnosisTable)
                ..where((t) => t.scanId.equals(scanId)))
              .get())
          .map((d) => d.id)
          .toList();

      if (diagnosisIds.isNotEmpty) {
        await (db.delete(db.chatMessageTable)
              ..where((t) => t.diagnosisId.isIn(diagnosisIds)))
            .go();
      }

      await (db.delete(db.diagnosisTable)
            ..where((t) => t.scanId.equals(scanId)))
          .go();
      await (db.delete(db.imageValidationTable)
            ..where((t) => t.scanId.equals(scanId)))
          .go();
      await (db.delete(db.escalationTable)
            ..where((t) => t.scanId.equals(scanId)))
          .go();

      // Cancel anything still queued for this scan. Without it, deleting a
      // scan that had not synced yet would still upload the photo afterwards
      // — bandwidth on a metered connection for something the farmer just
      // asked to be rid of. IN_PROGRESS is deliberately left alone: a request
      // already in flight cannot be recalled, and deleting its row would only
      // hide it from the failure UI.
      await (db.delete(db.syncOperationTable)
            ..where((t) =>
                t.entityId.equals(scanId) &
                t.status.isIn(const ['PENDING', 'FAILED'])))
          .go();

      await (db.delete(db.scanTable)..where((t) => t.id.equals(scanId))).go();
    });

    final path = scanRow?.imageLocalPath;
    if (path != null) await _deleteImageFiles([path]);
  }

  @override
  Future<void> deleteAllLocalScans() async {
    // Collect the image paths BEFORE the rows are gone, otherwise the files
    // become unreachable orphans. This is the app's "free up storage"
    // feature, and it previously deleted only database rows — every captured
    // photo stayed on disk forever, so the one control a farmer had for
    // reclaiming space on a nearly-full budget phone reclaimed almost none.
    final paths = await _allScanImagePaths();

    await db.transaction(() async {
      // Children before parents. chat_message references diagnosis, which
      // references scan; foreign keys are not enforced at runtime, so a
      // missed table leaves silent orphans rather than an error.
      await db.delete(db.chatMessageTable).go();
      await db.delete(db.diagnosisTable).go();
      await db.delete(db.imageValidationTable).go();
      await db.delete(db.escalationTable).go();
      await db.delete(db.scanTable).go();
      await db.delete(db.syncOperationTable).go();
    });

    await _deleteImageFiles(paths);
  }

  Future<List<String>> _allScanImagePaths() async {
    final query = db.selectOnly(db.scanTable)
      ..addColumns([db.scanTable.imageLocalPath]);
    final rows = await query.get();
    return rows
        .map((r) => r.read(db.scanTable.imageLocalPath))
        .whereType<String>()
        .toList();
  }

  /// Best-effort file deletion. Each file is handled independently so one
  /// already-missing or locked file cannot abort the rest of the cleanup.
  Future<void> _deleteImageFiles(Iterable<String> paths) async {
    for (final path in paths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {
        // Ignore: the DB rows are already gone, and an undeletable file is
        // not worth failing the user's cleanup action over.
      }
    }
  }
}

