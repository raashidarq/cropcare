// lib/domain/usecases/chat/get_chat_history_use_case.dart

import '../../entities/chat_message.dart';
import '../../repositories/chat_repository.dart';

class GetChatHistoryUseCase {
  final ChatRepository chatRepository;

  GetChatHistoryUseCase({required this.chatRepository});

  /// The stored transcript for [diagnosisId], oldest first.
  ///
  /// Reads from the device, so a conversation is there whether or not the
  /// phone has signal — including the questions that never got sent.
  Future<List<ChatMessage>> call(String diagnosisId) {
    return chatRepository.getHistory(diagnosisId);
  }
}
