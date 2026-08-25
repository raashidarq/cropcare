// lib/domain/usecases/auth/verify_phone_change_otp_use_case.dart
//
// Verifies OTP and updates phone number for an authenticated user.

import '../../entities/local_user.dart';
import '../../repositories/auth_repository.dart';

class VerifyPhoneChangeOtpUseCase {
  final AuthRepository authRepository;

  VerifyPhoneChangeOtpUseCase(this.authRepository);

  Future<LocalUser> call({
    required String currentUserId,
    required String newPhoneNumber,
    required String otpCode,
  }) async {
    return await authRepository.verifyPhoneChangeOtp(
      currentUserId: currentUserId,
      newPhoneNumber: newPhoneNumber,
      otpCode: otpCode,
    );
  }
}
