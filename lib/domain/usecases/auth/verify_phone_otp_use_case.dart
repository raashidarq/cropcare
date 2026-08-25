// lib/domain/usecases/auth/verify_phone_otp_use_case.dart

import '../../entities/local_user.dart';
import '../../repositories/auth_repository.dart';

class VerifyPhoneOtpUseCase {
  final AuthRepository authRepository;

  VerifyPhoneOtpUseCase(this.authRepository);

  Future<LocalUser> call({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) {
    return authRepository.verifyPhoneOtpAndUpgrade(
      localUserId: localUserId,
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );
  }
}
