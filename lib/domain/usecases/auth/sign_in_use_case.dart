// lib/domain/usecases/auth/sign_in_use_case.dart

import '../../entities/local_user.dart';
import '../../repositories/auth_repository.dart';

class SignInUseCase {
  final AuthRepository authRepository;

  SignInUseCase(this.authRepository);

  Future<LocalUser> call({
    required String localUserId,
    required String email,
    required String password,
  }) {
    return authRepository.loginAndUpgradeGuest(
      localUserId: localUserId,
      email: email,
      password: password,
    );
  }
}
