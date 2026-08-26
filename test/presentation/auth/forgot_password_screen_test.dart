import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/application/auth/auth_cubit.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/auth/request_password_reset_use_case.dart';
import 'package:cropcare/domain/usecases/auth/sign_in_use_case.dart';
import 'package:cropcare/domain/usecases/auth/sign_out_use_case.dart';
import 'package:cropcare/domain/usecases/auth/upgrade_guest_user_use_case.dart';
import 'package:cropcare/presentation/auth/forgot_password_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  String? lastRequestedEmail;
  bool throwRateLimit = false;

  @override
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> loginAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) =>
      throw UnimplementedError();

  @override
  Future<LocalUser> signOut({required String currentUserId}) =>
      throw UnimplementedError();

  @override
  Future<String?> getStoredToken() async => null;

  @override
  Future<void> requestPhoneOtp({required String phoneNumber}) async {}

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> requestPasswordReset({required String email}) async {
    lastRequestedEmail = email;
  }

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) async {
    return LocalUser(
      id: currentUserId,
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  }) async {}

  @override
  Future<LocalUser> updateEmail({required String currentUserId, required String newEmail}) => throw UnimplementedError();

  @override
  Future<void> requestPhoneChangeOtp({required String newPhoneNumber}) async {}

  @override
  Future<LocalUser> verifyPhoneChangeOtp({required String currentUserId, required String newPhoneNumber, required String otpCode}) => throw UnimplementedError();
}

void main() {
  late _FakeAuthRepository fakeRepo;
  late AuthCubit authCubit;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
    authCubit = AuthCubit(
      initialUser: LocalUser(
        id: 'guest-1',
        isGuest: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
      upgradeGuestUserUseCase: UpgradeGuestUserUseCase(fakeRepo),
      signInUseCase: SignInUseCase(fakeRepo),
      signOutUseCase: SignOutUseCase(fakeRepo),
      requestPasswordResetUseCase: RequestPasswordResetUseCase(fakeRepo),
    );
  });

  tearDown(() {
    authCubit.close();
  });

  testWidgets('ForgotPasswordScreen renders inputs and sends request on valid email', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider.value(
          value: authCubit,
          child: const ForgotPasswordScreen(),
        ),
      ),
    );

    expect(find.text('Reset Password'), findsWidgets);
    expect(find.byKey(const Key('forgot_password_email_field')), findsOneWidget);
    expect(find.byKey(const Key('forgot_password_submit_button')), findsOneWidget);

    // Try submitting empty. An empty field now reports that it is required
    // rather than that it is invalid — the two are different problems and
    // the message should say which one it is.
    await tester.tap(find.byKey(const Key('forgot_password_submit_button')));
    await tester.pumpAndSettle();
    expect(find.text('Enter your email address'), findsOneWidget);

    // Enter valid email and submit
    await tester.enterText(
      find.byKey(const Key('forgot_password_email_field')),
      'farmer@example.com',
    );
    await tester.tap(find.byKey(const Key('forgot_password_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeRepo.lastRequestedEmail, equals('farmer@example.com'));
    expect(find.text('Reset Email Sent'), findsOneWidget);
    expect(find.byKey(const Key('forgot_password_back_button')), findsOneWidget);
  });
}
