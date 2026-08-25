// lib/domain/usecases/auth/request_password_reset_use_case.dart

import '../../repositories/auth_repository.dart';

class RequestPasswordResetUseCase {
  final AuthRepository repository;

  RequestPasswordResetUseCase(this.repository);

  Future<void> call({required String email}) async {
    return repository.requestPasswordReset(email: email);
  }
}
