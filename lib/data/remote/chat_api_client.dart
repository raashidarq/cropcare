// lib/data/remote/chat_api_client.dart
//
// HTTP client for POST /chat-about-diagnosis. Mirrors TreatmentApiClient's
// constructor, timeout and error style so the two behave the same way when the
// network is bad, which is most of the time for this app's users.

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../domain/entities/chat_message.dart';

class ChatApiException implements Exception {
  final String message;
  final int? statusCode;

  const ChatApiException(this.message, [this.statusCode]);

  /// True when nothing reached the server, as opposed to the server saying no.
  /// The two need different UI: one is "try again when you have signal", the
  /// other is "something is wrong at our end".
  bool get isNetworkFailure => statusCode == null;

  @override
  String toString() => 'ChatApiException: $message (status: $statusCode)';
}

class ChatApiClient {
  static const String defaultBaseUrl =
      'https://cropcare-backend-xy88.onrender.com';

  final String baseUrl;
  final http.Client _client;

  ChatApiClient({
    this.baseUrl = defaultBaseUrl,
    http.Client? client,
  }) : _client = client ?? http.Client();

  /// Asks one question about a diagnosis and returns the answer text.
  ///
  /// [history] is the local transcript. The backend keeps no session, so the
  /// device's copy is the only one — which is what makes the conversation
  /// survive a dropped connection.
  Future<String> ask({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String? resultState,
    required String languageCode,
    required String question,
    required List<ChatMessage> history,
    String? userObservations,
    String? treatmentSummary,
    String? authToken,
  }) async {
    final uri = Uri.parse('$baseUrl/chat-about-diagnosis');

    final payload = {
      'crop_id': cropId,
      'disease_id': diseaseId,
      'confidence': confidence,
      'severity': ?severity,
      'result_state': ?resultState,
      'language_code': languageCode,
      'question': question.trim(),
      if (userObservations != null && userObservations.trim().isNotEmpty)
        'user_observations': userObservations.trim(),
      if (treatmentSummary != null && treatmentSummary.trim().isNotEmpty)
        'treatment_summary': treatmentSummary.trim(),
      // Only messages that actually made it into the conversation. A question
      // still pending or failed was never answered, so sending it would
      // present the model with a turn that has no reply.
      'history': history
          .where((m) => m.status == ChatMessageStatus.sent)
          .map((m) => {'role': m.role.value, 'content': m.content})
          .toList(),
    };

    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (authToken != null && authToken.trim().isNotEmpty)
        'Authorization': 'Bearer ${authToken.trim()}',
    };

    try {
      final response = await _client
          .post(uri, headers: headers, body: jsonEncode(payload))
          .timeout(const Duration(seconds: 30));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data =
            jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
        final answer = (data['answer'] as String?)?.trim() ?? '';
        if (answer.isEmpty) {
          throw const ChatApiException('Empty answer from server', 200);
        }
        return answer;
      }

      String detail = 'Server responded with status ${response.statusCode}';
      try {
        final errBody = jsonDecode(utf8.decode(response.bodyBytes));
        if (errBody is Map && errBody['detail'] != null) {
          detail = errBody['detail'].toString();
        }
      } catch (_) {}
      throw ChatApiException(detail, response.statusCode);
    } on ChatApiException {
      rethrow;
    } catch (e) {
      // No status code: this is a transport failure, not a server refusal.
      throw ChatApiException('Unable to reach the CropCare server: $e');
    }
  }

  void close() {
    _client.close();
  }
}
