// lib/data/remote/treatment_api_client.dart
//
// HTTP client communicating with the FastAPI Gemini endpoint.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../domain/entities/treatment.dart';

class TreatmentApiException implements Exception {
  final String message;
  final int? statusCode;

  const TreatmentApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'TreatmentApiException: $message (status: $statusCode)';
}

class TreatmentApiClient {
  static const String defaultBaseUrl =
      'https://cropcare-backend-xy88.onrender.com';

  final String baseUrl;
  final http.Client _client;

  TreatmentApiClient({
    this.baseUrl = defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Calls POST /interpret-diagnosis with the diagnosis metadata and user observations.
  Future<TreatmentResponse> fetchTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
  }) async {
    final uri = Uri.parse('$baseUrl/interpret-diagnosis');
    final payload = {
      'crop_id': cropId,
      'disease_id': diseaseId,
      'confidence': confidence,
      'severity': severity ?? 'moderate',
      'language_code': languageCode,
      if (userObservations != null && userObservations.trim().isNotEmpty)
        'user_observations': userObservations.trim(),
    };

    try {
      final response = await _client
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 25));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        return TreatmentResponse.fromJson(data);
      } else {
        String detail = 'Server responded with status ${response.statusCode}';
        try {
          final errBody = jsonDecode(utf8.decode(response.bodyBytes));
          if (errBody is Map && errBody['detail'] != null) {
            detail = errBody['detail'].toString();
          }
        } catch (_) {}
        throw TreatmentApiException(detail, response.statusCode);
      }
    } on TreatmentApiException {
      rethrow;
    } catch (e) {
      throw TreatmentApiException(
        'Unable to reach CropCare AI server. Please check your internet connection.',
      );
    }
  }

  void close() {
    _client.close();
  }
}
