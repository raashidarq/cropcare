import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/auth/auth_cubit.dart';
import 'package:cropcare/application/sync/sync_cubit.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/entities/sync_operation.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/repositories/sync_repository.dart';
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
      sessionToken: 'fake-session-token',
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

/// Records whether clearAuthHold() was actually called, and answers every
/// other query with an empty/no-op result - enough for SyncCubit's syncNow
/// to run to completion without a real database or network.
class _FakeSyncRepository implements SyncRepository {
  bool clearAuthHoldCalled = false;

  @override
  Future<void> clearAuthHold() async {
    clearAuthHoldCalled = true;
  }

  @override
  Future<void> enqueueOperation({
    required String entityId,
    required SyncEntityType entityType,
    required Map<String, dynamic> payload,
    String operationType = 'CREATE',
  }) async {}

  @override
  Future<List<SyncOperation>> getPendingOperations({
    int maxRetries = 3,
    int? limit,
  }) async => [];

  @override
  Future<int> getPendingCount() async => 0;

  @override
  Future<int> recoverStalledOperations() async => 0;

  @override
  Future<List<SyncOperation>> getFailedOperations() async => [];

  @override
  Future<void> retryOperation(String operationId) async {}

  @override
  Future<void> updateOperationStatus({
    required String operationId,
    required SyncOperationStatus status,
    String? error,
  }) async {}

  @override
  Future<void> syncPendingOperations({required String authToken}) async {}

  @override
  Future<void> syncReferenceData({required String authToken}) async {}

  @override
  Future<int> restoreScansFromCloud({
    required String userId,
    required String authToken,
    void Function(int restored, int total)? onProgress,
  }) async => 0;

  @override
  Future<bool> deleteRemoteScan({
    required String remoteScanId,
    required String authToken,
  }) async => true;
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

    // Switch to Create Account. This is now a footer link rather than a tab,
    // so it can sit below the fold in the test viewport — scroll to it first.
    final switchLink = find.byKey(const Key('auth_switch_intent_button'));
    await tester.ensureVisible(switchLink);
    await tester.pumpAndSettle();
    await tester.tap(switchLink);
    await tester.pumpAndSettle();

    // Consent disclaimer links are visible
    expect(find.byKey(const Key('consent_terms_link')), findsOneWidget);
    expect(find.byKey(const Key('consent_privacy_link')), findsOneWidget);
  });

  testWidgets(
    'A successful sign-in releases sync operations stuck waiting for a '
    'session, not just a plain sync',
    (tester) async {
      // Regression test for a live bug: a normal sign-in called SyncCubit's
      // plain syncNow(), which never releases operations the sync layer
      // marked authRequired during a PRIOR session (a guest attempt, or an
      // expired token) - retrying those with a dead token was deliberately
      // never automatic, since it would just burn the retry budget. The
      // effect: the "session expired" banner outlived every sign-in that
      // was supposed to resolve it, because nothing every actually told the
      // sync layer the session problem was over. resumeAfterReauth() is
      // the one call that both clears that hold AND syncs - this asserts
      // the hold-clearing half actually happens on a real sign-in, not
      // just that a sync was attempted.
      final fakeAuthRepo = _FakeAuthRepository();
      final fakeSyncRepo = _FakeSyncRepository();
      final guest = LocalUser(
        id: 'guest-123',
        isGuest: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final authCubit = AuthCubit(
        initialUser: guest,
        upgradeGuestUserUseCase: UpgradeGuestUserUseCase(fakeAuthRepo),
        signInUseCase: SignInUseCase(fakeAuthRepo),
        signOutUseCase: SignOutUseCase(fakeAuthRepo),
      );
      final syncCubit = SyncCubit(
        syncRepository: fakeSyncRepo,
        authRepository: fakeAuthRepo,
      );

      await tester.pumpWidget(
        LocalizationProvider(
          languageCode: 'en',
          child: MaterialApp(
            home: MultiBlocProvider(
              providers: [
                BlocProvider.value(value: authCubit),
                BlocProvider.value(value: syncCubit),
              ],
              child: AuthScreen(currentUser: guest),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const Key('signin_email_field')),
        'farmer@example.com',
      );
      await tester.enterText(
        find.byKey(const Key('signin_password_field')),
        'correcthorse',
      );
      final submitButton = find.byKey(const Key('signin_submit_button'));
      await tester.ensureVisible(submitButton);
      await tester.pumpAndSettle();
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(fakeSyncRepo.clearAuthHoldCalled, isTrue);

      await authCubit.close();
      await syncCubit.close();
    },
  );
}
