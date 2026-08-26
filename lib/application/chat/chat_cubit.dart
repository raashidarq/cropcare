// lib/application/chat/chat_cubit.dart
//
// Follow-up questions about one diagnosis.
//
// Scoped to a single Diagnosis for its whole lifetime — the diagnosis is a
// constructor argument, not a method parameter, so there is no way to ask
// about a different scan through this cubit.

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/chat/delete_chat_message_use_case.dart';
import '../../domain/usecases/chat/get_chat_history_use_case.dart';
import '../../domain/usecases/chat/send_chat_message_use_case.dart';
import 'chat_state.dart';

class ChatCubit extends Cubit<ChatState> {
  final GetChatHistoryUseCase getChatHistoryUseCase;
  final SendChatMessageUseCase sendChatMessageUseCase;
  final DeleteChatMessageUseCase? deleteChatMessageUseCase;

  final Diagnosis diagnosis;
  final String cropId;
  final String languageCode;

  /// What the farmer typed into the observations field, and the guidance they
  /// are already looking at. Passed through so answers are grounded in the
  /// same context and do not contradict what is on the previous screen.
  final String? userObservations;
  final String? treatmentSummary;

  /// Resolved lazily so a token that expires mid-conversation is not baked in.
  final Future<String?> Function()? getAuthToken;

  ChatCubit({
    required this.getChatHistoryUseCase,
    required this.sendChatMessageUseCase,
    this.deleteChatMessageUseCase,
    required this.diagnosis,
    required this.cropId,
    required this.languageCode,
    this.userObservations,
    this.treatmentSummary,
    this.getAuthToken,
  }) : super(const ChatInitial());

  Future<void> loadHistory() async {
    emit(const ChatLoading());
    try {
      final messages = await getChatHistoryUseCase(diagnosis.id);
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      // An unreadable transcript is not worth blocking the screen over: an
      // empty conversation the farmer can still use beats an error page.
      emit(const ChatLoaded(messages: []));
    }
  }

  Future<void> send(String question) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final current = state;
    if (current is! ChatLoaded || current.isSending) return;

    // Show the question immediately, marked pending. It is what the farmer
    // just typed; making them watch a spinner where their own words should be
    // is needlessly disorienting.
    final optimistic = ChatMessage(
      id: 'pending-${DateTime.now().microsecondsSinceEpoch}',
      diagnosisId: diagnosis.id,
      role: ChatRole.user,
      content: trimmed,
      languageCode: languageCode,
      status: ChatMessageStatus.pending,
      createdAt: DateTime.now().toIso8601String(),
    );

    emit(ChatLoaded(
      messages: [...current.messages, optimistic],
      isSending: true,
    ));

    try {
      final token = await getAuthToken?.call();
      await sendChatMessageUseCase(
        diagnosisId: diagnosis.id,
        diagnosis: diagnosis,
        cropId: cropId,
        question: trimmed,
        languageCode: languageCode,
        userObservations: userObservations,
        treatmentSummary: treatmentSummary,
        authToken: token,
      );

      // Re-read rather than appending: the repository owns the ids and the
      // stored status, and its copy is the one that survives a restart.
      final messages = await getChatHistoryUseCase(diagnosis.id);
      emit(ChatLoaded(messages: messages));
    } on ChatUnavailableException catch (e) {
      final messages = await _historyOr([...current.messages, optimistic]);
      emit(ChatLoaded(
        messages: messages,
        failure: e.reason,
        technicalDetail: e.technicalDetail,
      ));
    } catch (e) {
      final messages = await _historyOr([...current.messages, optimistic]);
      emit(ChatLoaded(
        messages: messages,
        failure: ChatUnavailableReason.serverError,
        technicalDetail: e.toString(),
      ));
    }
  }

  /// Re-reads the stored transcript, falling back to what is already on screen
  /// if even that read fails. The farmer's question must not disappear.
  Future<List<ChatMessage>> _historyOr(List<ChatMessage> fallback) async {
    try {
      return await getChatHistoryUseCase(diagnosis.id);
    } catch (_) {
      return fallback;
    }
  }

  /// Retries a question that failed, without making the farmer retype it.
  ///
  /// The original attempt is deleted first. Leaving it would put a permanent
  /// "not sent" ghost above the answer to the very same question.
  Future<void> retry(ChatMessage failed) async {
    final current = state;
    if (current is! ChatLoaded || current.isSending) return;

    try {
      await deleteChatMessageUseCase?.call(failed.id);
    } catch (_) {
      // Worst case the ghost stays; the retry itself still matters more.
    }

    emit(current.copyWith(
      messages: current.messages.where((m) => m.id != failed.id).toList(),
      clearFailure: true,
    ));
    await send(failed.content);
  }
}
