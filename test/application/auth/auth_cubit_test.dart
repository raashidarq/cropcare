import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/auth/auth_cubit.dart';
import 'package:cropcare/application/auth/auth_state.dart';
import 'package:cropcare/data/remote/auth_api_client.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/auth_repository.dart';
import 'package:cropcare/domain/usecases/auth/sign_in_use_case.dart';
import 'package:cropcare/domain/usecases/auth/sign_out_use_case.dart';
import 'package:cropcare/domain/usecases/auth/upgrade_guest_user_use_case.dart';

class _FakeAuthRepository implements AuthRepository {
  bool throwRateLimit = false;

  @override
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) async {
    if (throwRateLimit) {
      throw RateLimitException('Rate limit exceeded');
    }
    return LocalUser(
      id: localUserId,
      remoteUserId: 'remote-1',
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
      remoteUserId: 'remote-1',
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
  Future<String?> getStoredToken() async => 'token-123';
}

void main() {
  group('AuthCubit', () {
    late _FakeAuthRepository fakeRepo;
    late UpgradeGuestUserUseCase upgradeUseCase;
    late SignInUseCase signInUseCase;
    late SignOutUseCase signOutUseCase;

    final initialGuest = LocalUser(
      id: 'guest-1',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      fakeRepo = _FakeAuthRepository();
      upgradeUseCase = UpgradeGuestUserUseCase(fakeRepo);
      signInUseCase = SignInUseCase(fakeRepo);
      signOutUseCase = SignOutUseCase(fakeRepo);
    });

    test('registerAndUpgrade emits Loading then Success on success', () async {
      final cubit = AuthCubit(
        initialUser: initialGuest,
        upgradeGuestUserUseCase: upgradeUseCase,
        signInUseCase: signInUseCase,
        signOutUseCase: signOutUseCase,
      );

      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.registerAndUpgrade(
        email: 'farmer@example.com',
        password: 'password123',
      );

      await Future.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthSuccess>());
      expect((states[1] as AuthSuccess).user.isGuest, isFalse);
      expect((states[1] as AuthSuccess).user.email, equals('farmer@example.com'));

      await sub.cancel();
    });

    test('registerAndUpgrade emits AuthRateLimited when RateLimitException is thrown', () async {
      fakeRepo.throwRateLimit = true;

      final cubit = AuthCubit(
        initialUser: initialGuest,
        upgradeGuestUserUseCase: upgradeUseCase,
        signInUseCase: signInUseCase,
        signOutUseCase: signOutUseCase,
      );

      final states = <AuthState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.registerAndUpgrade(
        email: 'farmer@example.com',
        password: 'password123',
      );

      await Future.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<AuthLoading>());
      expect(states[1], isA<AuthRateLimited>());

      await sub.cancel();
    });
  });
}
