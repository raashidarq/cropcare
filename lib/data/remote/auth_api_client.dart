// lib/data/remote/auth_api_client.dart
//
// HTTP client for backend authentication and guest upgrade endpoints.

import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;

  AuthApiException(this.message, {this.statusCode});

  @override
  String toString() => 'AuthApiException: $message (status: $statusCode)';
}

class RateLimitException implements Exception {
  final String message;

  RateLimitException(this.message);

  @override
  String toString() => 'RateLimitException: $message';
}

class OtpExpiredException implements Exception {
  final String message;

  OtpExpiredException(this.message);

  @override
  String toString() => 'OtpExpiredException: $message';
}

class AuthResponse {
  final String userId;
  final String? email;
  final String? phoneNumber;
  final String accessToken;
  final String? refreshToken;
  final String tokenType;
  final int expiresIn;

  const AuthResponse({
    required this.userId,
    this.email,
    this.phoneNumber,
    required this.accessToken,
    this.refreshToken,
    this.tokenType = 'bearer',
    this.expiresIn = 3600,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      userId: json['user_id'] as String? ?? json['id'] as String? ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phone_number'] as String? ?? json['phone'] as String?,
      accessToken: json['access_token'] as String? ?? json['token'] as String? ?? '',
      refreshToken: json['refresh_token'] as String?,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int? ?? 3600,
    );
  }
}

class AuthApiClient {
  final String baseUrl;
  final http.Client _client;

  AuthApiClient({
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = baseUrl ?? 'https://cropcare-backend-xy88.onrender.com',
        _client = client ?? http.Client();

  Future<AuthResponse> registerWithEmail({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/register');
    return _sendAuthRequest(uri, {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  Future<AuthResponse> loginWithEmail({
    required String email,
    required String password,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/login');
    return _sendAuthRequest(uri, {
      'email': email.trim().toLowerCase(),
      'password': password,
    });
  }

  Future<AuthResponse> requestPhoneOtp({
    required String phoneNumber,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/request-otp');
    return _sendAuthRequest(uri, {
      'phone_number': phoneNumber.trim(),
    });
  }

  Future<AuthResponse> verifyPhoneOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/verify-otp');
    return _sendAuthRequest(uri, {
      'phone_number': phoneNumber.trim(),
      'otp_code': otpCode.trim(),
    });
  }

  Future<void> requestPasswordReset({
    required String email,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/forgot-password');
    await _sendAuthRequest(uri, {
      'email': email.trim().toLowerCase(),
    });
  }

  Future<void> deleteAccount({required String token}) async {
    final uri = Uri.parse('$baseUrl/auth/account');
    try {
      final response = await _client.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode >= 400 && response.statusCode != 404) {
        throw AuthApiException('Failed to delete account (status ${response.statusCode})');
      }
    } catch (e) {
      if (e is AuthApiException) rethrow;
    }
  }

  Future<AuthResponse> updateEmail({
    required String newEmail,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/change-email');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode({'new_email': newEmail.trim().toLowerCase()}),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(decoded['user'] is Map<String, dynamic> ? decoded['user'] as Map<String, dynamic> : decoded);
      }
      throw AuthApiException('Failed to update email (status ${response.statusCode})', statusCode: response.statusCode);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Unable to reach CropCare auth service: $e');
    }
  }

  Future<void> requestPhoneChangeOtp({
    required String newPhoneNumber,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/change-phone/request-otp');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode({'new_phone_number': newPhoneNumber.trim()}),
      );
      if (response.statusCode >= 400) {
        throw AuthApiException('Failed to send phone verification OTP (status ${response.statusCode})', statusCode: response.statusCode);
      }
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Unable to reach CropCare auth service: $e');
    }
  }

  Future<AuthResponse> verifyPhoneChangeOtp({
    required String newPhoneNumber,
    required String otpCode,
    String? token,
  }) async {
    final uri = Uri.parse('$baseUrl/auth/change-phone/verify-otp');
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
    try {
      final response = await _client.post(
        uri,
        headers: headers,
        body: jsonEncode({
          'new_phone_number': newPhoneNumber.trim(),
          'otp_code': otpCode.trim(),
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(decoded['user'] is Map<String, dynamic> ? decoded['user'] as Map<String, dynamic> : decoded);
      }
      throw AuthApiException('Failed to verify phone OTP (status ${response.statusCode})', statusCode: response.statusCode);
    } catch (e) {
      if (e is AuthApiException) rethrow;
      throw AuthApiException('Unable to reach CropCare auth service: $e');
    }
  }

  Future<void> sendFeedback({
    required String message,
    String? category,
    String? userId,
  }) async {
    final uri = Uri.parse('$baseUrl/feedback');
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'user_id': userId,
          'category': category ?? 'general',
          'message': message.trim(),
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
      if (response.statusCode >= 400) {
        throw AuthApiException('Failed to send feedback (status ${response.statusCode})');
      }
    } catch (e) {
      if (e is AuthApiException) rethrow;
    }
  }

  Future<AuthResponse> _sendAuthRequest(Uri uri, Map<String, dynamic> payload) async {
    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (response.statusCode == 429) {
        String detail = 'Too many requests. Please wait a few minutes before trying again.';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('detail')) {
            detail = decoded['detail'] as String;
          }
        } catch (_) {}
        throw RateLimitException(detail);
      }

      if (response.statusCode == 401) {
        String detail = '';
        try {
          final decoded = jsonDecode(response.body);
          if (decoded is Map && decoded.containsKey('detail')) {
            detail = decoded['detail'] as String;
          } else if (decoded is Map && decoded.containsKey('message')) {
            detail = decoded['message'] as String;
          }
        } catch (_) {}
        if (detail.toLowerCase().contains('expired') || response.body.toLowerCase().contains('expired')) {
          throw OtpExpiredException(detail.isNotEmpty ? detail : 'Verification code has expired.');
        }
      }

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body) as Map<String, dynamic>;
        return AuthResponse.fromJson(decoded);
      }

      String errorMessage = 'Authentication failed (HTTP ${response.statusCode})';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded.containsKey('detail')) {
          errorMessage = decoded['detail'] as String;
        } else if (decoded is Map && decoded.containsKey('message')) {
          errorMessage = decoded['message'] as String;
        }
      } catch (_) {}

      throw AuthApiException(errorMessage, statusCode: response.statusCode);
    } on RateLimitException {
      rethrow;
    } on OtpExpiredException {
      rethrow;
    } on AuthApiException {
      rethrow;
    } catch (e) {
      throw AuthApiException('Unable to reach CropCare auth service: $e');
    }
  }
}
