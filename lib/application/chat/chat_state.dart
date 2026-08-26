// lib/application/chat/chat_state.dart
//
// Hand-written states, per TD-002 — no freezed, no equatable.

import '../../domain/entities/chat_message.dart';
import '../../domain/repositories/chat_repository.dart';

abstract class ChatState {
  const ChatState();
}

class ChatInitial extends ChatState {
  const ChatInitial();
}

class ChatLoading extends ChatState {
  const ChatLoading();
}

/// The transcript, plus whatever is happening to it right now.
///
/// One state rather than separate sending/error states because the messages
/// must stay on screen throughout: a farmer whose question failed should still
/// see the question and the rest of the conversation, not an error screen that
/// replaced them.
class ChatLoaded extends ChatState {
  final List<ChatMessage> messages;

  /// True while an answer is being waited for.
  final bool isSending;

  /// Set when the last attempt failed. Cleared on the next attempt.
  final ChatUnavailableReason? failure;

  /// For `AppErrorView.technicalDetail` only — never shown as the main text.
  final String? technicalDetail;

  const ChatLoaded({
    required this.messages,
    this.isSending = false,
    this.failure,
    this.technicalDetail,
  });

  ChatLoaded copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    ChatUnavailableReason? failure,
    String? technicalDetail,
    bool clearFailure = false,
  }) {
    return ChatLoaded(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      failure: clearFailure ? null : (failure ?? this.failure),
      technicalDetail:
          clearFailure ? null : (technicalDetail ?? this.technicalDetail),
    );
  }
}
