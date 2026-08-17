import '../../entities/local_user.dart';
import '../../repositories/local_user_repository.dart';

class GetOrCreateGuestUserUseCase {
  final LocalUserRepository repository;

  GetOrCreateGuestUserUseCase(this.repository);

  Future<LocalUser> call() async {
    return await repository.getOrCreateGuestUser();
  }
}
