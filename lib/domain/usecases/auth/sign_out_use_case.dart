// lib/domain/usecases/auth/sign_out_use_case.dart

import '../../entities/local_user.dart';
import '../../repositories/auth_repository.dart';

class SignOutUseCase {
  final AuthRepository authRepository;

  SignOutUseCase(this.authRepository);

  Future<LocalUser> call({required String currentUserId}) {
    return authRepository.signOut(currentUserId: currentUserId);
  }
}
