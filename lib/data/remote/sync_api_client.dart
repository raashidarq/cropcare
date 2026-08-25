// lib/data/remote/sync_api_client.dart
//
// Remote API client for offline sync engine and Supabase Storage image uploads.

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class SyncApiException implements Exception {
  final String message;
  final int? statusCode;

  SyncApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'SyncApiException: $message (code: $statusCode)';
}

class SyncApiClient {
  final String baseUrl;
  final http.Client _httpClient;

  static const String defaultBaseUrl =
      'https://cropcare-backend-xy88.onrender.com';

  SyncApiClient({
    String? baseUrl,
    http.Client? httpClient,
  })  : baseUrl = baseUrl ?? defaultBaseUrl,
        _httpClient = httpClient ?? http.Client();

  /// Requests a signed upload URL for direct storage upload.
  Future<String> getSignedUploadUrl({
    required String scanId,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/scans/$scanId/upload-url');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final url = data['upload_url'] ?? data['url'] ?? data['signed_url'];
      if (url != null && url is String) {
        return url;
      }
      throw SyncApiException('Invalid upload URL response from server');
    } else {
      throw SyncApiException(
        'Failed to get upload URL: ${response.body}',
        response.statusCode,
      );
    }
  }

  /// Uploads raw image bytes directly to Supabase Storage via signed PUT request.
  Future<void> uploadImageBinary({
    required String signedUrl,
    required Uint8List imageBytes,
  }) async {
    final uri = Uri.parse(signedUrl);
    final response = await _httpClient.put(
      uri,
      headers: {
        'Content-Type': 'image/jpeg',
      },
      body: imageBytes,
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncApiException(
        'Failed to upload image binary to Storage',
        response.statusCode,
      );
    }
  }

  /// Idempotently upserts a scan entity to the backend.
  Future<void> syncScan({
    required Map<String, dynamic> scanData,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/scans');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(scanData),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncApiException(
        'Failed to sync scan: ${response.body}',
        response.statusCode,
      );
    }
  }

  /// Idempotently upserts a diagnosis entity to the backend.
  Future<void> syncDiagnosis({
    required Map<String, dynamic> diagnosisData,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/diagnoses');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(diagnosisData),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncApiException(
        'Failed to sync diagnosis: ${response.body}',
        response.statusCode,
      );
    }
  }

  /// Idempotently upserts an escalation entity to the backend.
  Future<void> syncEscalation({
    required Map<String, dynamic> escalationData,
    required String authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/escalations');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode(escalationData),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncApiException(
        'Failed to sync escalation: ${response.body}',
        response.statusCode,
      );
    }
  }
}
