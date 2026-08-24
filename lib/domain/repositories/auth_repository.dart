// lib/domain/repositories/auth_repository.dart

import '../entities/local_user.dart';

abstract class AuthRepository {
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  });

  Future<LocalUser> loginAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  });

  Future<LocalUser> signOut({required String currentUserId});

  Future<String?> getStoredToken();
}
