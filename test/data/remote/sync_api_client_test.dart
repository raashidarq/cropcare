import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:cropcare/data/remote/sync_api_client.dart';

void main() {
  group('SyncApiClient', () {
    test('getSignedUploadUrl returns signed url on 200/201 response', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/scans/scan-123/upload-url');
        expect(request.headers['Authorization'], 'Bearer fake_jwt');
        return http.Response(
          jsonEncode({'upload_url': 'https://storage.supabase.co/upload/signed-token'}),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final client = SyncApiClient(httpClient: mockClient);
      final url = await client.getSignedUploadUrl(
        scanId: 'scan-123',
        authToken: 'fake_jwt',
      );

      expect(url, 'https://storage.supabase.co/upload/signed-token');
    });

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
  });
}
