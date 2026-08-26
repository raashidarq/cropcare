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

  /// Fetches downstream reference data updates (crops, diseases, guidelines).
  Future<Map<String, dynamic>> fetchReferenceData({
    String? since,
    required String authToken,
  }) async {
    final queryParams = since != null ? {'since': since} : null;
    final uri = Uri.parse('$baseUrl/reference-data').replace(
      queryParameters: queryParams,
    );
    final response = await _httpClient.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body) as Map<String, dynamic>;
    } else {
      throw SyncApiException(
        'Failed to fetch reference data: ${response.body}',
        response.statusCode,
      );
    }
  }

  /// Pulls the user's own scans back down, newest first.
  ///
  /// Paged deliberately: a season of daily scanning is thousands of rows, and
  /// this runs on a budget phone over a rural connection. The caller walks the
  /// pages so a dropped connection costs one page, not the whole restore.
  Future<RestorePage> fetchScans({
    required String authToken,
    int limit = 100,
    int offset = 0,
  }) async {
    final uri = Uri.parse('$baseUrl/scans').replace(
      queryParameters: {'limit': '$limit', 'offset': '$offset'},
    );
    final response = await _httpClient.get(
      uri,
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    if (response.statusCode != 200) {
      throw SyncApiException(
        'Failed to fetch scans: ${response.body}',
        response.statusCode,
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    return RestorePage(
      scans: (data['scans'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>(),
      total: data['total'] as int? ?? 0,
      hasMore: data['has_more'] as bool? ?? false,
    );
  }

  /// Removes one scan from the cloud, including its stored image.
  ///
  /// Returns whether the image was removed too. The server reports that
  /// separately because the row can go while the photograph stays, and the
  /// user is entitled to know which happened.
  Future<bool> deleteRemoteScan({
    required String remoteScanId,
    required String authToken,
  }) async {
    final response = await _httpClient.delete(
      Uri.parse('$baseUrl/scans/$remoteScanId'),
      headers: {
        'Accept': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
    );

    // Already gone is a success from the caller's point of view: the goal was
    // for it not to be there.
    if (response.statusCode == 404) return true;

    if (response.statusCode != 200) {
      throw SyncApiException(
        'Failed to delete scan: ${response.body}',
        response.statusCode,
      );
    }

    final data = jsonDecode(utf8.decode(response.bodyBytes))
        as Map<String, dynamic>;
    return data['image_deleted'] as bool? ?? false;
  }
}

/// One page of restored scans.
class RestorePage {
  final List<Map<String, dynamic>> scans;
  final int total;
  final bool hasMore;

  const RestorePage({
    required this.scans,
    required this.total,
    required this.hasMore,
  });
}
