import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cropcare/data/remote/treatment_api_client.dart';

void main() {
  group('TreatmentApiClient', () {
    test('successfully fetches and parses treatment guidance with observations',
        () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, equals('/interpret-diagnosis'));
        expect(request.method, equals('POST'));

        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['crop_id'], equals('tomato'));
        expect(body['disease_id'], equals('tomato_late_blight'));
        expect(body['confidence'], equals(0.92));
        expect(body['severity'], equals('high'));
        expect(body['language_code'], equals('en'));
        expect(body['user_observations'], equals('Leaves turning yellow'));

        final responseJson = {
          'summary': 'Late blight is a destructive fungal disease.',
          'what_to_do': 'Prune affected leaves immediately.',
          'what_to_avoid': 'Avoid overhead watering.',
          'recheck_after_days': 5,
          'interpretation_id': 'interp-123',
        };

        return http.Response(jsonEncode(responseJson), 200, headers: {
          'content-type': 'application/json',
        });
      });

      final client = TreatmentApiClient(client: mockClient);
      final response = await client.fetchTreatmentGuidance(
        cropId: 'tomato',
        diseaseId: 'tomato_late_blight',
        confidence: 0.92,
        severity: 'high',
        languageCode: 'en',
        userObservations: 'Leaves turning yellow',
      );

      expect(response.summary, equals('Late blight is a destructive fungal disease.'));
      expect(response.whatToDo, equals('Prune affected leaves immediately.'));
      expect(response.whatToAvoid, equals('Avoid overhead watering.'));
      expect(response.recheckAfterDays, equals(5));
      expect(response.interpretationId, equals('interp-123'));
    });

    test('throws TreatmentApiException on 500 error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'detail': 'Gemini service temporarily unavailable'}),
          500,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = TreatmentApiClient(client: mockClient);
      expect(
        () => client.fetchTreatmentGuidance(
          cropId: 'tomato',
          diseaseId: 'tomato_late_blight',
          confidence: 0.85,
          severity: 'moderate',
          languageCode: 'en',
        ),
        throwsA(isA<TreatmentApiException>()),
      );
    });
  });
}
