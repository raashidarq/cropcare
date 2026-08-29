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

    test(
      'requestPhoneOtp sends POST to /auth/request-otp with key "phone", '
      'not "phone_number"',
      () async {
        // Regression test for a live bug: this used to send "phone_number",
        // a key the backend's OtpRequestBody does not recognise (it wants
        // "phone"). An unrecognised JSON key is just silently ignored by
        // Pydantic, so both email and phone ended up None, which the
        // backend's own "exactly one of email/phone must be supplied" check
        // then rejected with a 400 - phone sign-in never actually worked
        // until this matched the real schema. Distinct from the *change*-
        // phone endpoints, which do use "phone_number"/"otp_code" and were
        // never affected — see the tests below.
        final mockClient = MockClient((request) async {
          expect(request.url.path, equals('/auth/request-otp'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['phone'], equals('+94771234567'));
          expect(
            body.containsKey('phone_number'),
            isFalse,
            reason: 'the backend schema has no such field',
          );

          return http.Response(
            jsonEncode({'message': 'If that identifier is registered, an OTP has been sent.'}),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = AuthApiClient(client: mockClient);
        await expectLater(
          apiClient.requestPhoneOtp(phoneNumber: '+94771234567'),
          completes,
        );
      },
    );

    test(
      'verifyPhoneOtp sends POST to /auth/verify-otp with keys "phone" and '
      '"code", not "phone_number"/"otp_code"',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, equals('/auth/verify-otp'));
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['phone'], equals('+94771234567'));
          expect(body['code'], equals('123456'));
          expect(body.containsKey('phone_number'), isFalse);
          expect(body.containsKey('otp_code'), isFalse);

          return http.Response(
            jsonEncode({
              'user_id': 'user-remote-123',
              'phone_number': '+94771234567',
              'access_token': 'mock-access-token',
              'refresh_token': 'mock-refresh-token',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final apiClient = AuthApiClient(client: mockClient);
        final response = await apiClient.verifyPhoneOtp(
          phoneNumber: '+94771234567',
          otpCode: '123456',
        );
        expect(response.accessToken, equals('mock-access-token'));
      },
    );

    test('requestPasswordReset sends POST to /auth/forgot-password with email', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/auth/forgot-password'));
        final body = jsonDecode(request.body);
        expect(body['email'], equals('farmer@example.com'));

        return http.Response(
          jsonEncode({'message': 'Reset instructions sent.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);
      await expectLater(
        apiClient.requestPasswordReset(email: 'farmer@example.com'),
        completes,
      );
    });

    test('deleteAccount sends DELETE to /auth/account with Bearer token', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('DELETE'));
        expect(request.url.path, equals('/auth/account'));
        expect(request.headers['Authorization'], equals('Bearer test-access-token'));

        return http.Response(
          jsonEncode({'message': 'Account deleted.'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);
      await expectLater(
        apiClient.deleteAccount(token: 'test-access-token'),
        completes,
      );
    });

    test('sendFeedback sends POST to /feedback with message and category', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/feedback'));
        final body = jsonDecode(request.body);
        expect(body['message'], equals('Great crop app!'));
        expect(body['category'], equals('suggestion'));
        expect(body['user_id'], equals('u-123'));

        return http.Response(
          jsonEncode({'status': 'success'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);
      await expectLater(
        apiClient.sendFeedback(
          message: 'Great crop app!',
          category: 'suggestion',
          userId: 'u-123',
        ),
        completes,
      );
    });

    test('updateEmail sends POST to /auth/change-email with new_email', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/auth/change-email'));
        expect(request.headers['Authorization'], equals('Bearer test-token'));
        final body = jsonDecode(request.body);
        expect(body['new_email'], equals('new.farmer@example.com'));

        return http.Response(
          jsonEncode({
            'user': {
              'id': 'usr-1',
              'email': 'new.farmer@example.com',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);
      final res = await apiClient.updateEmail(
        newEmail: 'new.farmer@example.com',
        token: 'test-token',
      );
      expect(res.email, equals('new.farmer@example.com'));
    });

    test('requestPhoneChangeOtp sends POST to /auth/change-phone/request-otp', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/auth/change-phone/request-otp'));
        expect(request.headers['Authorization'], equals('Bearer test-token'));
        final body = jsonDecode(request.body);
        expect(body['new_phone_number'], equals('+94771234567'));

        return http.Response(
          jsonEncode({'message': 'OTP sent'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);
      await expectLater(
        apiClient.requestPhoneChangeOtp(
          newPhoneNumber: '+94771234567',
          token: 'test-token',
        ),
        completes,
      );
    });

    test('verifyPhoneChangeOtp sends POST to /auth/change-phone/verify-otp', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, equals('POST'));
        expect(request.url.path, equals('/auth/change-phone/verify-otp'));
        final body = jsonDecode(request.body);
        expect(body['new_phone_number'], equals('+94771234567'));
        expect(body['otp_code'], equals('123456'));

        return http.Response(
          jsonEncode({
            'user': {
              'id': 'usr-1',
              'phone_number': '+94771234567',
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final apiClient = AuthApiClient(client: mockClient);
      final res = await apiClient.verifyPhoneChangeOtp(
        newPhoneNumber: '+94771234567',
        otpCode: '123456',
        token: 'test-token',
      );
      expect(res.phoneNumber, equals('+94771234567'));
    });
  });
}
