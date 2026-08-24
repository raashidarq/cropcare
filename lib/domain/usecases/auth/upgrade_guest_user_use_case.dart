// lib/domain/usecases/auth/upgrade_guest_user_use_case.dart

import '../../entities/local_user.dart';
import '../../repositories/auth_repository.dart';

class UpgradeGuestUserUseCase {
  final AuthRepository authRepository;

  UpgradeGuestUserUseCase(this.authRepository);

  Future<LocalUser> call({
    required String localUserId,
    required String email,
    required String password,
  }) {
    return authRepository.registerAndUpgradeGuest(
      localUserId: localUserId,
      email: email,
      password: password,
    );
  }
}
