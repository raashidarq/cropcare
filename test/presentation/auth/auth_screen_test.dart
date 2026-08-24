import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/auth/auth_cubit.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
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
}

void main() {
  testWidgets('AuthScreen renders tabs, email and password inputs', (tester) async {
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
            child: AuthScreen(currentUser: guest),
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
  });
}
