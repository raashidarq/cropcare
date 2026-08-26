// lib/domain/repositories/chat_repository.dart
//
// Follow-up conversation about one diagnosis.

import '../entities/chat_message.dart';
import '../entities/diagnosis.dart';

/// Raised when a question cannot be answered. Carries a reason the UI can map
/// to a sentence, rather than a message the UI would be tempted to print raw.
class ChatUnavailableException implements Exception {
  final ChatUnavailableReason reason;

  /// The underlying error, for `AppErrorView.technicalDetail` only. Never the
  /// primary message shown to a farmer.
  final String? technicalDetail;

  const ChatUnavailableException(this.reason, {this.technicalDetail});
}

enum ChatUnavailableReason {
  /// No connection. The question is kept locally and can be retried.
  offline,

  /// The server answered, but with an error.
  serverError,

  /// Too many questions too quickly.
  rateLimited,
}

abstract class ChatRepository {
  /// The stored transcript for [diagnosisId], oldest first.
  Future<List<ChatMessage>> getHistory(String diagnosisId);

  /// Records a message locally without sending anything.
  Future<void> saveMessage(ChatMessage message);

  /// Sends [question] and returns the assistant's reply.
  ///
  /// Both turns are persisted: the question before the request goes out, so it
  /// survives a failure, and the answer on success. Throws
  /// [ChatUnavailableException] rather than a transport exception.
  Future<ChatMessage> ask({
    required String diagnosisId,
    required Diagnosis diagnosis,
    required String cropId,
    required String question,
    required String languageCode,
    String? userObservations,
    String? treatmentSummary,
    String? authToken,
  });

  /// Removes a message that will not be retried.
  Future<void> deleteMessage(String messageId);
}
