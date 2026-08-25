import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/feedback/submit_feedback_use_case.dart';

class _FakeFeedbackAuthRepository implements AuthRepository {
  String? sentMessage;
  String? sentCategory;
  String? sentUserId;

  @override
  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  }) async {
    sentMessage = message;
    sentCategory = category;
    sentUserId = userId;
  }

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) =>
      throw UnimplementedError();

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
  test('SubmitFeedbackUseCase calls sendFeedback on authRepository with correct parameters', () async {
    final repo = _FakeFeedbackAuthRepository();
    final useCase = SubmitFeedbackUseCase(repo);

    await useCase(
      message: 'Great app feature!',
      category: 'suggestion',
      userId: 'user-456',
    );

    expect(repo.sentMessage, equals('Great app feature!'));
    expect(repo.sentCategory, equals('suggestion'));
    expect(repo.sentUserId, equals('user-456'));
  });
}
