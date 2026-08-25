// lib/domain/usecases/auth/request_phone_change_otp_use_case.dart
//
// Requests an SMS OTP code to change/verify a new phone number.

import '../../repositories/auth_repository.dart';

class RequestPhoneChangeOtpUseCase {
  final AuthRepository authRepository;

  RequestPhoneChangeOtpUseCase(this.authRepository);

  Future<void> call({
    required String newPhoneNumber,
  }) async {
    return await authRepository.requestPhoneChangeOtp(
      newPhoneNumber: newPhoneNumber,
    );
  }
}
