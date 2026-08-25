// lib/data/repositories/local_user_repository_impl.dart

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
    // Check if there is already any user (registered or guest)
    final existingUser = await (db.select(db.localUserTable)..limit(1)).getSingleOrNull();
    if (existingUser != null) {
      return _mapToEntity(existingUser);
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

  @override
  Future<LocalUser?> getCurrentUser() async {
    final row = await (db.select(db.localUserTable)..limit(1)).getSingleOrNull();
    if (row == null) return null;
    return _mapToEntity(row);
  }

  @override
  Future<LocalUser> upgradeGuestUser({
    required String localUserId,
    required String remoteUserId,
    String? email,
    String? phoneNumber,
    required String sessionToken,
    String? sessionRefreshToken,
    DateTime? sessionExpiresAt,
  }) async {
    final nowIso = DateTime.now().toIso8601String();

    final companion = LocalUserTableCompanion(
      remoteUserId: Value(remoteUserId),
      email: Value(email),
      phoneNumber: Value(phoneNumber),
      isGuest: const Value(0),
      sessionToken: Value(sessionToken),
      sessionRefreshToken: Value(sessionRefreshToken),
      sessionExpiresAt: Value(sessionExpiresAt?.toIso8601String()),
      updatedAt: Value(nowIso),
    );

    await (db.update(db.localUserTable)..where((tbl) => tbl.id.equals(localUserId)))
        .write(companion);

    final updatedRow = await (db.select(db.localUserTable)
          ..where((tbl) => tbl.id.equals(localUserId)))
        .getSingle();

    return _mapToEntity(updatedRow);
  }

  @override
  Future<LocalUser> updateUserEmail({
    required String localUserId,
    required String newEmail,
  }) async {
    final nowIso = DateTime.now().toIso8601String();

    final companion = LocalUserTableCompanion(
      email: Value(newEmail),
      updatedAt: Value(nowIso),
    );

    await (db.update(db.localUserTable)..where((tbl) => tbl.id.equals(localUserId)))
        .write(companion);

    final updatedRow = await (db.select(db.localUserTable)
          ..where((tbl) => tbl.id.equals(localUserId)))
        .getSingle();

    return _mapToEntity(updatedRow);
  }

  @override
  Future<LocalUser> updateUserPhoneNumber({
    required String localUserId,
    required String newPhoneNumber,
  }) async {
    final nowIso = DateTime.now().toIso8601String();

    final companion = LocalUserTableCompanion(
      phoneNumber: Value(newPhoneNumber),
      updatedAt: Value(nowIso),
    );

    await (db.update(db.localUserTable)..where((tbl) => tbl.id.equals(localUserId)))
        .write(companion);

    final updatedRow = await (db.select(db.localUserTable)
          ..where((tbl) => tbl.id.equals(localUserId)))
        .getSingle();

    return _mapToEntity(updatedRow);
  }

  @override
  Future<LocalUser> resetToGuestUser(String currentUserId) async {
    final nowIso = DateTime.now().toIso8601String();

    final companion = LocalUserTableCompanion(
      remoteUserId: const Value(null),
      email: const Value(null),
      phoneNumber: const Value(null),
      isGuest: const Value(1),
      sessionToken: const Value(null),
      sessionRefreshToken: const Value(null),
      sessionExpiresAt: const Value(null),
      updatedAt: Value(nowIso),
    );

    await (db.update(db.localUserTable)..where((tbl) => tbl.id.equals(currentUserId)))
        .write(companion);

    final updatedRow = await (db.select(db.localUserTable)
          ..where((tbl) => tbl.id.equals(currentUserId)))
        .getSingle();

    return _mapToEntity(updatedRow);
  }

  LocalUser _mapToEntity(LocalUserTableData row) {
    return LocalUser(
      id: row.id,
      remoteUserId: row.remoteUserId,
      email: row.email,
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
