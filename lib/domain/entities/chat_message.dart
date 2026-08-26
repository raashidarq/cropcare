// lib/domain/entities/chat_message.dart
//
// Pure Dart domain entity — no Drift, no Flutter dependencies.

enum ChatRole {
  user('USER'),
  assistant('ASSISTANT');

  final String value;
  const ChatRole(this.value);

  static ChatRole fromString(String raw) {
    return ChatRole.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ChatRole.assistant,
    );
  }
}

/// Delivery state of a message.
///
/// Only ever non-[sent] on a question the farmer asked. The app is
/// offline-first, so a question typed with no signal is kept and marked rather
/// than refused or silently dropped — the farmer can see it is still there and
/// retry when they have a connection.
enum ChatMessageStatus {
  pending('PENDING'),
  sent('SENT'),
  failed('FAILED');

  final String value;
  const ChatMessageStatus(this.value);

  static ChatMessageStatus fromString(String raw) {
    return ChatMessageStatus.values.firstWhere(
      (e) => e.value == raw,
      orElse: () => ChatMessageStatus.sent,
    );
  }
}

/// One turn in a conversation about a single diagnosis.
class ChatMessage {
  final String id;
  final String diagnosisId;
  final ChatRole role;
  final String content;

  /// The language this turn happened in. Held per message because a farmer can
  /// change language mid-conversation.
  final String languageCode;

  final ChatMessageStatus status;

  /// ISO8601 timestamp.
  final String createdAt;

  const ChatMessage({
    required this.id,
    required this.diagnosisId,
    required this.role,
    required this.content,
    required this.languageCode,
    this.status = ChatMessageStatus.sent,
    required this.createdAt,
  });

  bool get isFromUser => role == ChatRole.user;

  ChatMessage copyWith({
    String? id,
    String? diagnosisId,
    ChatRole? role,
    String? content,
    String? languageCode,
    ChatMessageStatus? status,
    String? createdAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      diagnosisId: diagnosisId ?? this.diagnosisId,
      role: role ?? this.role,
      content: content ?? this.content,
      languageCode: languageCode ?? this.languageCode,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
