import '../entities/local_user.dart';

abstract class LocalUserRepository {
  Future<LocalUser> getOrCreateGuestUser();
}
