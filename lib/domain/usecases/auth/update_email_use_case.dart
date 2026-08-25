// lib/domain/usecases/auth/update_email_use_case.dart
//
// Updates the email address for an authenticated user.

import '../../entities/local_user.dart';
import '../../repositories/auth_repository.dart';

class UpdateEmailUseCase {
  final AuthRepository authRepository;

  UpdateEmailUseCase(this.authRepository);

  Future<LocalUser> call({
    required String currentUserId,
    required String newEmail,
  }) async {
    return await authRepository.updateEmail(
      currentUserId: currentUserId,
      newEmail: newEmail,
    );
  }
}
