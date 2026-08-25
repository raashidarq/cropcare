// lib/domain/usecases/feedback/submit_feedback_use_case.dart
//
// Submits farmer feedback, bug reports, or feature suggestions to the backend.

import '../../repositories/auth_repository.dart';

class SubmitFeedbackUseCase {
  final AuthRepository authRepository;

  SubmitFeedbackUseCase(this.authRepository);

  Future<void> call({
    required String message,
    String? category,
    String? userId,
  }) async {
    return authRepository.sendFeedback(
      message: message,
      category: category,
      userId: userId,
    );
  }
}
