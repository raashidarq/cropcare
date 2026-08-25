// lib/domain/repositories/local_user_repository.dart

import '../entities/local_user.dart';

abstract class LocalUserRepository {
  Future<LocalUser> getOrCreateGuestUser();
  Future<LocalUser?> getCurrentUser();
  Future<LocalUser> upgradeGuestUser({
    required String localUserId,
    required String remoteUserId,
    String? email,
    String? phoneNumber,
    required String sessionToken,
    String? sessionRefreshToken,
    DateTime? sessionExpiresAt,
  });
  Future<LocalUser> updateUserEmail({
    required String localUserId,
    required String newEmail,
  });
  Future<LocalUser> updateUserPhoneNumber({
    required String localUserId,
    required String newPhoneNumber,
  });
  Future<LocalUser> resetToGuestUser(String currentUserId);
}
