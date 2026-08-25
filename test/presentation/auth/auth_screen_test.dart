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
import 'package:cropcare/presentation/auth/auth_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

class _FakeAuthRepository implements AuthRepository {
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
  Future<void> requestPhoneOtp({required String phoneNumber}) async {}

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) async {
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
  testWidgets('AuthScreen renders tabs, email and password inputs when phone auth is disabled', (tester) async {
    final fakeRepo = _FakeAuthRepository();
    final guest = LocalUser(
      id: 'guest-123',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final authCubit = AuthCubit(
      initialUser: guest,
      upgradeGuestUserUseCase: UpgradeGuestUserUseCase(fakeRepo),
      signInUseCase: SignInUseCase(fakeRepo),
      signOutUseCase: SignOutUseCase(fakeRepo),
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: BlocProvider.value(
            value: authCubit,
            child: AuthScreen(currentUser: guest, phoneAuthEnabled: false),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Account & Sign In'), findsOneWidget);
    expect(find.text('Sign In'), findsWidgets);
    expect(find.text('Create Account'), findsOneWidget);
    expect(find.byKey(const Key('signin_email_field')), findsOneWidget);
    expect(find.byKey(const Key('signin_password_field')), findsOneWidget);
    expect(find.byKey(const Key('signin_submit_button')), findsOneWidget);

    // Method selector is hidden
    expect(find.byKey(const Key('auth_method_selector')), findsNothing);
  });

  testWidgets('AuthScreen displays method toggle and switches to phone input when phone auth is enabled', (tester) async {
    final fakeRepo = _FakeAuthRepository();
    final guest = LocalUser(
      id: 'guest-123',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final authCubit = AuthCubit(
      initialUser: guest,
      upgradeGuestUserUseCase: UpgradeGuestUserUseCase(fakeRepo),
      signInUseCase: SignInUseCase(fakeRepo),
      signOutUseCase: SignOutUseCase(fakeRepo),
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: BlocProvider.value(
            value: authCubit,
            child: AuthScreen(currentUser: guest, phoneAuthEnabled: true),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Method selector is visible
    expect(find.byKey(const Key('auth_method_selector')), findsOneWidget);
    expect(find.byKey(const Key('auth_method_email')), findsOneWidget);
    expect(find.byKey(const Key('auth_method_phone')), findsOneWidget);

    // Initially email is selected
    expect(find.byKey(const Key('signin_email_field')), findsOneWidget);
    expect(find.byKey(const Key('signin_phone_field')), findsNothing);

    // Switch to Phone
    await tester.tap(find.byKey(const Key('auth_method_phone')));
    await tester.pumpAndSettle();

    // Phone input is now visible
    expect(find.byKey(const Key('signin_phone_field')), findsOneWidget);
    expect(find.byKey(const Key('signin_phone_submit_button')), findsOneWidget);
    expect(find.byKey(const Key('signin_email_field')), findsNothing);
  });

  testWidgets('AuthScreen displays forgot password button on Sign In and consent disclaimer on Create Account', (tester) async {
    final fakeRepo = _FakeAuthRepository();
    final guest = LocalUser(
      id: 'guest-123',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final authCubit = AuthCubit(
      initialUser: guest,
      upgradeGuestUserUseCase: UpgradeGuestUserUseCase(fakeRepo),
      signInUseCase: SignInUseCase(fakeRepo),
      signOutUseCase: SignOutUseCase(fakeRepo),
      requestPasswordResetUseCase: RequestPasswordResetUseCase(fakeRepo),
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: BlocProvider.value(
            value: authCubit,
            child: AuthScreen(currentUser: guest),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Forgot password button is present on Sign In
    expect(find.byKey(const Key('signin_forgot_password_button')), findsOneWidget);

    // Switch to Create Account tab
    await tester.tap(find.text('Create Account'));
    await tester.pumpAndSettle();

    // Consent disclaimer links are visible
    expect(find.byKey(const Key('consent_terms_link')), findsOneWidget);
    expect(find.byKey(const Key('consent_privacy_link')), findsOneWidget);
  });
}
