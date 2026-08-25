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

  Future<void> requestPhoneOtp({
    required String phoneNumber,
  });

  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  });

  Future<void> requestPasswordReset({
    required String email,
  });

  Future<LocalUser> deleteAccount({
    required String currentUserId,
  });

  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  });

  Future<LocalUser> updateEmail({
    required String currentUserId,
    required String newEmail,
  });

  Future<void> requestPhoneChangeOtp({
    required String newPhoneNumber,
  });

  Future<LocalUser> verifyPhoneChangeOtp({
    required String currentUserId,
    required String newPhoneNumber,
    required String otpCode,
  });
}
