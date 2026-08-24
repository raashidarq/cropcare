// lib/data/repositories/auth_repository_impl.dart

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../domain/entities/local_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/local_user_repository.dart';
import '../remote/auth_api_client.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthApiClient apiClient;
  final LocalUserRepository localUserRepository;
  final FlutterSecureStorage secureStorage;

  static const String _kAccessTokenKey = 'cropcare_access_token';
  static const String _kRefreshTokenKey = 'cropcare_refresh_token';

  AuthRepositoryImpl({
    required this.apiClient,
    required this.localUserRepository,
    FlutterSecureStorage? secureStorage,
  }) : secureStorage = secureStorage ?? const FlutterSecureStorage();

  @override
  Future<LocalUser> registerAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.registerWithEmail(
      email: email,
      password: password,
    );

    await _persistTokens(response);

    final expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));

    return localUserRepository.upgradeGuestUser(
      localUserId: localUserId,
      remoteUserId: response.userId,
      email: response.email ?? email,
      phoneNumber: response.phoneNumber,
      sessionToken: response.accessToken,
      sessionRefreshToken: response.refreshToken,
      sessionExpiresAt: expiresAt,
    );
  }

  @override
  Future<LocalUser> loginAndUpgradeGuest({
    required String localUserId,
    required String email,
    required String password,
  }) async {
    final response = await apiClient.loginWithEmail(
      email: email,
      password: password,
    );

    await _persistTokens(response);

    final expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));

    return localUserRepository.upgradeGuestUser(
      localUserId: localUserId,
      remoteUserId: response.userId,
      email: response.email ?? email,
      phoneNumber: response.phoneNumber,
      sessionToken: response.accessToken,
      sessionRefreshToken: response.refreshToken,
      sessionExpiresAt: expiresAt,
    );
  }

  @override
  Future<LocalUser> signOut({required String currentUserId}) async {
    try {
      await secureStorage.delete(key: _kAccessTokenKey);
      await secureStorage.delete(key: _kRefreshTokenKey);
    } catch (_) {}

    return localUserRepository.resetToGuestUser(currentUserId);
  }

  @override
  Future<String?> getStoredToken() async {
    try {
      return await secureStorage.read(key: _kAccessTokenKey);
    } catch (_) {
      return null;
    }
  }

  Future<void> _persistTokens(AuthResponse response) async {
    try {
      await secureStorage.write(key: _kAccessTokenKey, value: response.accessToken);
      if (response.refreshToken != null) {
        await secureStorage.write(key: _kRefreshTokenKey, value: response.refreshToken!);
      }
    } catch (_) {}
  }
}
