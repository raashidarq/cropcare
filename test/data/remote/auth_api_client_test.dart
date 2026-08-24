import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cropcare/data/remote/auth_api_client.dart';

void main() {
  group('AuthApiClient', () {
    test('registerWithEmail returns AuthResponse on 200/201 success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/auth/register'));
        final body = jsonDecode(request.body);
        expect(body['email'], equals('farmer@example.com'));
        expect(body['password'], equals('secret123'));

        return http.Response(
          jsonEncode({
            'user_id': 'user-remote-123',
            'email': 'farmer@example.com',
            'access_token': 'mock-access-token',
            'refresh_token': 'mock-refresh-token',
            'token_type': 'bearer',
            'expires_in': 3600,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);
      final response = await apiClient.registerWithEmail(
        email: 'farmer@example.com',
        password: 'secret123',
      );

      expect(response.userId, equals('user-remote-123'));
      expect(response.email, equals('farmer@example.com'));
      expect(response.accessToken, equals('mock-access-token'));
      expect(response.refreshToken, equals('mock-refresh-token'));
    });

    test('loginWithEmail throws RateLimitException on 429 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Rate limit exceeded: 3 requests per 10 minutes.'}),
          429,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);

      expect(
        () => apiClient.loginWithEmail(
          email: 'farmer@example.com',
          password: 'secret123',
        ),
        throwsA(isA<RateLimitException>().having(
          (e) => e.message,
          'message',
          contains('Rate limit exceeded'),
        )),
      );
    });

    test('loginWithEmail throws AuthApiException on 401 response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Invalid email or password.'}),
          401,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);

      expect(
        () => apiClient.loginWithEmail(
          email: 'farmer@example.com',
          password: 'wrongpassword',
        ),
        throwsA(isA<AuthApiException>().having(
          (e) => e.message,
          'message',
          contains('Invalid email or password'),
        )),
      );
    });
  });
}
