// lib/domain/usecases/auth/delete_account_use_case.dart
//
// Deletes remote account, purges session tokens, and resets local user to guest mode.

import '../../entities/local_user.dart';
import '../../repositories/auth_repository.dart';

class DeleteAccountUseCase {
  final AuthRepository authRepository;

  DeleteAccountUseCase(this.authRepository);

  Future<LocalUser> call({required String currentUserId}) async {
    return authRepository.deleteAccount(currentUserId: currentUserId);
  }
}
