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
    } on AuthApiException {
      rethrow;
    } catch (e) {
      throw AuthApiException('Unable to reach CropCare auth service: $e');
    }
  }
}
