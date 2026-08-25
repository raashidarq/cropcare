import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/auth/auth_cubit.dart';
import 'package:cropcare/data/remote/auth_api_client.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/auth/request_phone_otp_use_case.dart';
import 'package:cropcare/domain/usecases/auth/sign_in_use_case.dart';
import 'package:cropcare/domain/usecases/auth/sign_out_use_case.dart';
import 'package:cropcare/domain/usecases/auth/upgrade_guest_user_use_case.dart';
import 'package:cropcare/domain/usecases/auth/verify_phone_otp_use_case.dart';
import 'package:cropcare/presentation/auth/otp_entry_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

class _FakeAuthRepository implements AuthRepository {
  bool throwRateLimit = false;
  bool throwOtpExpired = false;
  bool throwError = false;

  @override
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) async {
    return LocalUser(
      id: localUserId,
      remoteUserId: 'remote-123',
      email: email,
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<LocalUser> loginAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) async {
    return LocalUser(
      id: localUserId,
      remoteUserId: 'remote-123',
      email: email,
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<LocalUser> signOut({required String currentUserId}) async {
    return LocalUser(
      id: currentUserId,
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<String?> getStoredToken() async => null;

  @override
  Future<void> requestPhoneOtp({required String phoneNumber}) async {
    if (throwRateLimit) {
      throw RateLimitException('Too many attempts. Please wait 5 minutes.');
    }
    if (throwError) {
      throw AuthApiException('Network failure');
    }
  }

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) async {
    if (throwOtpExpired) {
      throw OtpExpiredException('Verification code has expired.');
    }
    if (throwRateLimit) {
      throw RateLimitException('Too many verification attempts.');
    }
    if (throwError) {
      throw AuthApiException('Invalid code entered');
    }
    return LocalUser(
      id: localUserId,
      remoteUserId: 'remote-123',
      phoneNumber: phoneNumber,
      isGuest: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> requestPasswordReset({required String email}) async {}

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
  late LocalUser guest;
  late AuthCubit authCubit;

  setUp(() {
    fakeRepo = _FakeAuthRepository();
    guest = LocalUser(
      id: 'guest-123',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    authCubit = AuthCubit(
      initialUser: guest,
      upgradeGuestUserUseCase: UpgradeGuestUserUseCase(fakeRepo),
      signInUseCase: SignInUseCase(fakeRepo),
      signOutUseCase: SignOutUseCase(fakeRepo),
      requestPhoneOtpUseCase: RequestPhoneOtpUseCase(fakeRepo),
      verifyPhoneOtpUseCase: VerifyPhoneOtpUseCase(fakeRepo),
    );
  });

  Widget buildTestWidget() {
    return LocalizationProvider(
      languageCode: 'en',
      child: MaterialApp(
        home: BlocProvider.value(
          value: authCubit,
          child: const OtpEntryScreen(
            identifier: '+94771234567',
            identifierType: OtpIdentifierType.phone,
          ),
        ),
      ),
    );
  }

  testWidgets('OtpEntryScreen renders title, identifier, code input, submit and resend buttons', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Enter Verification Code'), findsOneWidget);
    expect(find.text('+94771234567'), findsOneWidget);
    expect(find.byKey(const Key('otp_code_field')), findsOneWidget);
    expect(find.byKey(const Key('otp_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('otp_resend_button')), findsOneWidget);
  });

  testWidgets('OtpEntryScreen displays rate-limited banner on AuthRateLimited', (tester) async {
    fakeRepo.throwRateLimit = true;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter valid 6-digit code and submit
    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('otp_rate_limited_banner')), findsOneWidget);
    expect(find.text('Too many verification attempts.'), findsOneWidget);
  });

  testWidgets('OtpEntryScreen displays expired banner on AuthOtpExpired', (tester) async {
    fakeRepo.throwOtpExpired = true;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter valid 6-digit code and submit
    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('otp_expired_banner')), findsOneWidget);
    expect(find.text('Verification code has expired.'), findsOneWidget);
  });

  testWidgets('OtpEntryScreen displays error SnackBar on AuthError', (tester) async {
    fakeRepo.throwError = true;

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    // Enter valid 6-digit code and submit
    await tester.enterText(find.byKey(const Key('otp_code_field')), '123456');
    await tester.tap(find.byKey(const Key('otp_submit_button')));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Invalid code entered'), findsOneWidget);
  });
}
