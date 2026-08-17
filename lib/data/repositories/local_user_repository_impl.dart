import 'dart:math';
import 'package:drift/drift.dart';

import '../../domain/entities/local_user.dart';
import '../../domain/repositories/local_user_repository.dart';
import '../local/database/app_database.dart';

class LocalUserRepositoryImpl implements LocalUserRepository {
  final AppDatabase db;

  LocalUserRepositoryImpl(this.db);

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
  Future<LocalUser> getOrCreateGuestUser() async {
    final query = db.select(db.localUserTable)
      ..where((tbl) => tbl.isGuest.equals(1))
      ..limit(1);
    final row = await query.getSingleOrNull();

    if (row != null) {
      return _mapToEntity(row);
    }

    final id = _generateUuid();
    final now = DateTime.now();
    final nowIso = now.toIso8601String();

    final companion = LocalUserTableCompanion.insert(
      id: id,
      isGuest: const Value(1),
      createdAt: nowIso,
      updatedAt: nowIso,
    );

    await db.into(db.localUserTable).insert(companion);

    final insertedRow = await (db.select(db.localUserTable)
          ..where((tbl) => tbl.id.equals(id)))
        .getSingle();

    return _mapToEntity(insertedRow);
  }

  LocalUser _mapToEntity(LocalUserTableData row) {
    return LocalUser(
      id: row.id,
      remoteUserId: row.remoteUserId,
      phoneNumber: row.phoneNumber,
      isGuest: row.isGuest == 1,
      sessionToken: row.sessionToken,
      sessionRefreshToken: row.sessionRefreshToken,
      sessionExpiresAt: row.sessionExpiresAt != null
          ? DateTime.tryParse(row.sessionExpiresAt!)
          : null,
      createdAt: DateTime.parse(row.createdAt),
      updatedAt: DateTime.parse(row.updatedAt),
    );
  }
}
