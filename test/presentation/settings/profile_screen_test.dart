import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/application/auth/auth_cubit.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/auth/delete_account_use_case.dart';
import 'package:cropcare/domain/usecases/auth/request_phone_change_otp_use_case.dart';
import 'package:cropcare/domain/usecases/auth/sign_in_use_case.dart';
import 'package:cropcare/domain/usecases/auth/sign_out_use_case.dart';
import 'package:cropcare/domain/usecases/auth/update_email_use_case.dart';
import 'package:cropcare/domain/usecases/auth/upgrade_guest_user_use_case.dart';
import 'package:cropcare/domain/usecases/auth/verify_phone_change_otp_use_case.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/settings/profile_screen.dart';

class _FakeAuthRepository implements AuthRepository {
  bool deleteAccountCalled = false;
  String? updatedEmail;
  String? requestedOtpPhone;
  String? verifiedPhone;

  @override
  Future<LocalUser> deleteAccount({required String currentUserId}) async {
    deleteAccountCalled = true;
    return LocalUser(
      id: currentUserId,
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

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
  Future<LocalUser> signOut({required String currentUserId}) async {
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
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) =>
      throw UnimplementedError();
}

void main() {
  late _FakeAuthRepository fakeAuthRepository;
  late AuthCubit authCubit;

  final guestUser = LocalUser(
    id: 'guest-123',
    isGuest: true,
    createdAt: DateTime.parse('2026-08-25T10:00:00Z'),
    updatedAt: DateTime.parse('2026-08-25T10:00:00Z'),
  );

  final registeredUser = LocalUser(
    id: 'user-123',
    remoteUserId: 'remote-uuid-456',
    email: 'farmer@example.com',
    phoneNumber: '+94771234567',
    isGuest: false,
    createdAt: DateTime.parse('2026-08-25T10:00:00Z'),
    updatedAt: DateTime.parse('2026-08-25T10:00:00Z'),
  );

  setUp(() {
    fakeAuthRepository = _FakeAuthRepository();
    authCubit = AuthCubit(
      initialUser: guestUser,
      upgradeGuestUserUseCase: UpgradeGuestUserUseCase(fakeAuthRepository),
      signInUseCase: SignInUseCase(fakeAuthRepository),
      signOutUseCase: SignOutUseCase(fakeAuthRepository),
      deleteAccountUseCase: DeleteAccountUseCase(fakeAuthRepository),
      updateEmailUseCase: UpdateEmailUseCase(fakeAuthRepository),
      requestPhoneChangeOtpUseCase: RequestPhoneChangeOtpUseCase(fakeAuthRepository),
      verifyPhoneChangeOtpUseCase: VerifyPhoneChangeOtpUseCase(fakeAuthRepository),
    );
  });

  Widget createTestWidget({required LocalUser user}) {
    return MaterialApp(
      home: LocalizationProvider(
        languageCode: 'en',
        child: BlocProvider.value(
          value: authCubit,
          child: ProfileScreen(
            user: user,
            authCubit: authCubit,
          ),
        ),
      ),
    );
  }

  testWidgets('ProfileScreen displays guest details and link button for guest user', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(user: guestUser));
    await tester.pumpAndSettle();

    expect(find.text('User Profile'), findsOneWidget);
    expect(find.text('Guest Mode'), findsWidgets);
    expect(find.byKey(const Key('profile_link_account_button')), findsOneWidget);
    expect(find.byKey(const Key('delete_account_button')), findsOneWidget);
  });

  testWidgets('ProfileScreen displays registered user details and edit buttons', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(user: registeredUser));
    await tester.pumpAndSettle();

    expect(find.text('farmer@example.com'), findsWidgets);
    expect(find.text('+94771234567'), findsWidgets);
    expect(find.text('Registered Account'), findsWidgets);
    expect(find.byKey(const Key('profile_sign_out_button')), findsOneWidget);
    expect(find.byKey(const Key('delete_account_button')), findsOneWidget);
    expect(find.byKey(const Key('edit_email_button')), findsOneWidget);
    expect(find.byKey(const Key('edit_phone_button')), findsOneWidget);
  });

  testWidgets('Tapping Edit Email opens dialog and updates email on submit', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(user: registeredUser));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_email_button')));
    await tester.pumpAndSettle();

    expect(find.text('Change Email'), findsOneWidget);
    expect(find.byKey(const Key('change_email_input')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('change_email_input')), 'new.farmer@example.com');
    await tester.tap(find.byKey(const Key('change_email_submit_button')));
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.updatedEmail, equals('new.farmer@example.com'));
  });

  testWidgets('Tapping Edit Phone opens dialog, requests OTP, and verifies on submit', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(user: registeredUser));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('edit_phone_button')));
    await tester.pumpAndSettle();

    expect(find.text('Change Phone Number'), findsOneWidget);
    expect(find.byKey(const Key('change_phone_input')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('change_phone_input')), '+94779876543');
    await tester.tap(find.byKey(const Key('change_phone_send_code_button')));
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.requestedOtpPhone, equals('+94779876543'));
    expect(find.byKey(const Key('change_phone_otp_input')), findsOneWidget);

    await tester.enterText(find.byKey(const Key('change_phone_otp_input')), '654321');
    await tester.tap(find.byKey(const Key('change_phone_verify_button')));
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.verifiedPhone, equals('+94779876543'));
  });

  testWidgets('Tapping Delete Account shows confirmation dialog and executes deletion on confirm', (tester) async {
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(createTestWidget(user: registeredUser));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('delete_account_button')));
    await tester.pumpAndSettle();

    expect(find.text('Delete Account?'), findsOneWidget);
    expect(find.byKey(const Key('delete_account_confirm_button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('delete_account_confirm_button')));
    await tester.pumpAndSettle();

    expect(fakeAuthRepository.deleteAccountCalled, isTrue);
  });
}
