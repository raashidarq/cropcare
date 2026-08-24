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
  Future<LocalUser> resetToGuestUser(String currentUserId);
}
