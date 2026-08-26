// lib/domain/usecases/chat/delete_chat_message_use_case.dart

import '../../repositories/chat_repository.dart';

class DeleteChatMessageUseCase {
  final ChatRepository chatRepository;

  DeleteChatMessageUseCase({required this.chatRepository});

  /// Removes a message from the stored transcript.
  ///
  /// Used when a failed question is retried: without this the original attempt
  /// stays in the database marked failed, so a question the farmer successfully
  /// re-sent would sit in their transcript forever as though it had never gone
  /// through.
  Future<void> call(String messageId) {
    return chatRepository.deleteMessage(messageId);
  }
}
