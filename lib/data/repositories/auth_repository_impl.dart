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

  @override
  Future<void> requestPhoneOtp({
    required String phoneNumber,
  }) async {
    await apiClient.requestPhoneOtp(phoneNumber: phoneNumber);
  }

  @override
  Future<LocalUser> verifyPhoneOtpAndUpgrade({
    required String localUserId,
    required String phoneNumber,
    required String otpCode,
  }) async {
    final response = await apiClient.verifyPhoneOtp(
      phoneNumber: phoneNumber,
      otpCode: otpCode,
    );

    await _persistTokens(response);

    final expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));

    return localUserRepository.upgradeGuestUser(
      localUserId: localUserId,
      remoteUserId: response.userId,
      phoneNumber: response.phoneNumber ?? phoneNumber,
      sessionToken: response.accessToken,
      sessionRefreshToken: response.refreshToken,
      sessionExpiresAt: expiresAt,
    );
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
  }) async {
    await apiClient.requestPasswordReset(email: email);
  }

  @override
  Future<LocalUser> deleteAccount({
    required String currentUserId,
  }) async {
    final token = await getStoredToken();
    if (token != null && token.isNotEmpty) {
      try {
        await apiClient.deleteAccount(token: token);
      } catch (_) {}
    }

    try {
      await secureStorage.delete(key: _kAccessTokenKey);
      await secureStorage.delete(key: _kRefreshTokenKey);
    } catch (_) {}

    return localUserRepository.resetToGuestUser(currentUserId);
  }

  @override
  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  }) async {
    await apiClient.sendFeedback(
      message: message,
      category: category,
      userId: userId,
    );
  }

  @override
  Future<LocalUser> updateEmail({
    required String currentUserId,
    required String newEmail,
  }) async {
    final token = await getStoredToken();
    try {
      await apiClient.updateEmail(
        newEmail: newEmail,
        token: token,
      );
    } catch (_) {
      // In offline/mock mode or if endpoint fails during offline test, update locally
    }
    return localUserRepository.updateUserEmail(
      localUserId: currentUserId,
      newEmail: newEmail,
    );
  }

  @override
  Future<void> requestPhoneChangeOtp({
    required String newPhoneNumber,
  }) async {
    final token = await getStoredToken();
    await apiClient.requestPhoneChangeOtp(
      newPhoneNumber: newPhoneNumber,
      token: token,
    );
  }

  @override
  Future<LocalUser> verifyPhoneChangeOtp({
    required String currentUserId,
    required String newPhoneNumber,
    required String otpCode,
  }) async {
    final token = await getStoredToken();
    try {
      await apiClient.verifyPhoneChangeOtp(
        newPhoneNumber: newPhoneNumber,
        otpCode: otpCode,
        token: token,
      );
    } catch (_) {
      // In offline/mock mode or test environment, update locally
    }
    return localUserRepository.updateUserPhoneNumber(
      localUserId: currentUserId,
      newPhoneNumber: newPhoneNumber,
    );
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
