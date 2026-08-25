// lib/domain/usecases/auth/request_phone_otp_use_case.dart

import '../../repositories/auth_repository.dart';

class RequestPhoneOtpUseCase {
  final AuthRepository authRepository;

  RequestPhoneOtpUseCase(this.authRepository);

  Future<void> call({
    required String phoneNumber,
  }) {
    return authRepository.requestPhoneOtp(
      phoneNumber: phoneNumber,
    );
  }
}
