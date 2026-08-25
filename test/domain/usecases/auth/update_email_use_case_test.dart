import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/auth/request_phone_change_otp_use_case.dart';
import 'package:cropcare/domain/usecases/auth/update_email_use_case.dart';
import 'package:cropcare/domain/usecases/auth/verify_phone_change_otp_use_case.dart';

class _FakeAuthRepository implements AuthRepository {
  String? updatedEmail;
  String? requestedOtpPhone;
  String? verifiedPhone;

  @override
  Future<LocalUser> updateEmail({
    required String currentUserId,
    required String newEmail,
  }) async {
    updatedEmail = newEmail;
    return LocalUser(
      id: currentUserId,
      email: newEmail,
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> requestPhoneChangeOtp({required String newPhoneNumber}) async {
    requestedOtpPhone = newPhoneNumber;
  }

  @override
  Future<LocalUser> verifyPhoneChangeOtp({
    required String currentUserId,
    required String newPhoneNumber,
    required String otpCode,
  }) async {
    verifiedPhone = newPhoneNumber;
    return LocalUser(
      id: currentUserId,
      phoneNumber: newPhoneNumber,
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) => throw UnimplementedError();

  @override
  Future<String?> getStoredToken() => throw UnimplementedError();

  @override
  Future<LocalUser> loginAndUpgradeGuest({required String localUserId, required String email, required String password}) => throw UnimplementedError();

  @override
  Future<LocalUser> registerAndUpgradeGuest({required String localUserId, required String email, required String password}) => throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) => throw UnimplementedError();

  @override
  Future<void> requestPhoneOtp({required String phoneNumber}) => throw UnimplementedError();

  @override
  Future<void> sendFeedback({required String message, String? category, String? userId}) => throw UnimplementedError();

  @override
  Future<LocalUser> signOut({required String currentUserId}) => throw UnimplementedError();

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({required String localUserId, required String phoneNumber, required String otpCode}) => throw UnimplementedError();
}

void main() {
  late _FakeAuthRepository repository;

  setUp(() {
    repository = _FakeAuthRepository();
  });

  test('UpdateEmailUseCase calls updateEmail on repository', () async {
    final useCase = UpdateEmailUseCase(repository);
    final user = await useCase(currentUserId: 'u-1', newEmail: 'farmer@crop.lk');

    expect(repository.updatedEmail, equals('farmer@crop.lk'));
    expect(user.email, equals('farmer@crop.lk'));
  });

  test('RequestPhoneChangeOtpUseCase calls requestPhoneChangeOtp on repository', () async {
    final useCase = RequestPhoneChangeOtpUseCase(repository);
    await useCase(newPhoneNumber: '+94771234567');

    expect(repository.requestedOtpPhone, equals('+94771234567'));
  });

  test('VerifyPhoneChangeOtpUseCase calls verifyPhoneChangeOtp on repository', () async {
    final useCase = VerifyPhoneChangeOtpUseCase(repository);
    final user = await useCase(
      currentUserId: 'u-1',
      newPhoneNumber: '+94771234567',
      otpCode: '123456',
    );

    expect(repository.verifiedPhone, equals('+94771234567'));
    expect(user.phoneNumber, equals('+94771234567'));
  });
}
