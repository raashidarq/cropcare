// lib/domain/usecases/chat/send_chat_message_use_case.dart

import '../../entities/chat_message.dart';
import '../../entities/diagnosis.dart';
import '../../repositories/chat_repository.dart';

class SendChatMessageUseCase {
  final ChatRepository chatRepository;

  SendChatMessageUseCase({required this.chatRepository});

  Future<ChatMessage> call({
    required String diagnosisId,
    required Diagnosis diagnosis,
    required String cropId,
    required String question,
    required String languageCode,
    String? userObservations,
    String? treatmentSummary,
    String? authToken,
  }) {
    return chatRepository.ask(
      diagnosisId: diagnosisId,
      diagnosis: diagnosis,
      cropId: cropId,
      question: question,
      languageCode: languageCode,
      userObservations: userObservations,
      treatmentSummary: treatmentSummary,
      authToken: authToken,
    );
  }
}
