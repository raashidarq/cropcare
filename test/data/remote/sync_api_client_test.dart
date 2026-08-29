import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cropcare/data/remote/sync_api_client.dart';

void main() {
  group('SyncApiClient', () {
    test(
      'getSignedUploadUrl returns both the signed upload url and the '
      'storage path on 200/201 response',
      () async {
        final mockClient = MockClient((request) async {
          expect(request.url.path, '/scans/scan-123/upload-url');
          expect(request.headers['Authorization'], 'Bearer fake_jwt');
          return http.Response(
            jsonEncode({
              'upload_url': 'https://storage.supabase.co/upload/signed-token',
              'path': 'user-1/scan-123.jpg',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = SyncApiClient(httpClient: mockClient);
        final signed = await client.getSignedUploadUrl(
          scanId: 'scan-123',
          authToken: 'fake_jwt',
        );

        expect(signed.uploadUrl, 'https://storage.supabase.co/upload/signed-token');
        // The path is what later reaches scan.image_url for restore to read
        // - it must be the plain storage path, distinct from the signed
        // upload URL above, not derived from it.
        expect(signed.path, 'user-1/scan-123.jpg');
      },
    );

    test(
      'getSignedUploadUrl throws when the response is missing the path',
      () async {
        final mockClient = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'upload_url': 'https://storage.supabase.co/upload/signed-token',
            }),
            200,
            headers: {'content-type': 'application/json'},
          );
        });

        final client = SyncApiClient(httpClient: mockClient);
        expect(
          () => client.getSignedUploadUrl(scanId: 'scan-123', authToken: 'fake_jwt'),
          throwsA(isA<SyncApiException>()),
        );
      },
    );

    test('uploadImageBinary performs PUT with image/jpeg', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'PUT');
        expect(request.headers['Content-Type'], 'image/jpeg');
        expect(request.bodyBytes, Uint8List.fromList([1, 2, 3]));
        return http.Response('', 200);
      });

      final client = SyncApiClient(httpClient: mockClient);
      await client.uploadImageBinary(
        signedUrl: 'https://storage.supabase.co/upload/signed-token',
        imageBytes: Uint8List.fromList([1, 2, 3]),
      );
    });

    test('syncScan calls POST /scans with json and Bearer token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/scans');
        expect(request.headers['Authorization'], 'Bearer fake_jwt');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['local_scan_id'], 'scan-1');
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = SyncApiClient(httpClient: mockClient);
      await client.syncScan(
        scanData: {'local_scan_id': 'scan-1'},
        authToken: 'fake_jwt',
      );
    });

    test('syncDiagnosis calls POST /diagnoses with json and Bearer token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/diagnoses');
        expect(request.headers['Authorization'], 'Bearer fake_jwt');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['local_diagnosis_id'], 'diag-1');
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = SyncApiClient(httpClient: mockClient);
      await client.syncDiagnosis(
        diagnosisData: {'local_diagnosis_id': 'diag-1'},
        authToken: 'fake_jwt',
      );
    });

    test('syncEscalation calls POST /escalations with json and Bearer token', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/escalations');
        expect(request.headers['Authorization'], 'Bearer fake_jwt');
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['local_escalation_id'], 'esc-1');
        return http.Response(jsonEncode({'status': 'ok'}), 200);
      });

      final client = SyncApiClient(httpClient: mockClient);
      await client.syncEscalation(
        escalationData: {'local_escalation_id': 'esc-1'},
        authToken: 'fake_jwt',
      );
    });

    test('fetchReferenceData calls GET /reference-data with Authorization header and since param', () async {
      final mockClient = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/reference-data');
        expect(request.url.queryParameters['since'], '2026-01-01T00:00:00Z');
        expect(request.headers['Authorization'], 'Bearer fake_jwt');
        return http.Response(
          jsonEncode({
            'crops': [{'id': 'tomato', 'name_en': 'Tomato'}],
            'diseases': [{'id': 'tomato_early_blight', 'crop_id': 'tomato', 'name_en': 'Early Blight'}],
            'guidelines': [{'id': 'tg-1', 'disease_id': 'tomato_early_blight', 'guideline_version': 'v1.0'}]
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = SyncApiClient(httpClient: mockClient);
      final result = await client.fetchReferenceData(
        since: '2026-01-01T00:00:00Z',
        authToken: 'fake_jwt',
      );

      expect(result['crops'], isList);
      expect((result['crops'] as List).length, 1);
      expect((result['diseases'] as List).length, 1);
      expect((result['guidelines'] as List).length, 1);
    });
  });
}
