import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/auth/delete_account_use_case.dart';

class _FakeAuthRepository implements AuthRepository {
  String? deletedUserId;

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) async {
    deletedUserId = currentUserId;
    return LocalUser(
      id: currentUserId,
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getStoredToken() => throw UnimplementedError();

  @override
  Future<LocalUser> loginAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) =>
      throw UnimplementedError();

  @override
  Future<void> requestPhoneOtp({required String phoneNumber}) =>
      throw UnimplementedError();

  @override
  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> signOut({required String currentUserId}) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> updateEmail({required String currentUserId, required String newEmail}) => throw UnimplementedError();

  @override
  Future<void> requestPhoneChangeOtp({required String newPhoneNumber}) => throw UnimplementedError();

  @override
  Future<LocalUser> verifyPhoneChangeOtp({required String currentUserId, required String newPhoneNumber, required String otpCode}) => throw UnimplementedError();
}

void main() {
  test('DeleteAccountUseCase calls deleteAccount on authRepository and returns guest', () async {
    final repo = _FakeAuthRepository();
    final useCase = DeleteAccountUseCase(repo);

    final result = await useCase(currentUserId: 'user-123');

    expect(repo.deletedUserId, equals('user-123'));
    expect(result.isGuest, isTrue);
  });
}
