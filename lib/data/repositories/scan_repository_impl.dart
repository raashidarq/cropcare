import 'dart:math';

import '../../domain/entities/scan.dart';
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
}
