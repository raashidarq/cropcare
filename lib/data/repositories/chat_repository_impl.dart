// lib/data/repositories/chat_repository_impl.dart
//
// The local transcript is authoritative. The backend keeps no session, so
// every question and answer is written to the device first and the network is
// treated as something that may or may not be there — which, for this app's
// users, is the honest default.
//
// The ordering matters: the farmer's question is persisted BEFORE the request
// goes out. If the connection drops mid-flight, the question is still on
// screen marked as unsent rather than having vanished along with whatever they
// typed standing in a field.

import 'dart:math';

import 'package:drift/drift.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/diagnosis.dart';
import '../../domain/repositories/chat_repository.dart';
import '../local/database/app_database.dart';
import '../remote/chat_api_client.dart';

class ChatRepositoryImpl implements ChatRepository {
  final AppDatabase db;
  final ChatApiClient apiClient;

  ChatRepositoryImpl({required this.db, required this.apiClient});

  @override
  Future<List<ChatMessage>> getHistory(String diagnosisId) async {
    final rows = await (db.select(db.chatMessageTable)
          ..where((t) => t.diagnosisId.equals(diagnosisId))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .get();
    return rows.map(_toEntity).toList();
  }

  @override
  Future<void> saveMessage(ChatMessage message) async {
    await db
        .into(db.chatMessageTable)
        .insertOnConflictUpdate(_toCompanion(message));
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await (db.delete(db.chatMessageTable)
          ..where((t) => t.id.equals(messageId)))
        .go();
  }

  @override
  Future<ChatMessage> ask({
    required String diagnosisId,
    required Diagnosis diagnosis,
    required String cropId,
    required String question,
    required String languageCode,
    String? userObservations,
    String? treatmentSummary,
    String? authToken,
  }) async {
    final history = await getHistory(diagnosisId);

    // Persist the question first, marked pending. If anything below fails, it
    // is still here and still visible.
    final userMessage = ChatMessage(
      id: _generateId(),
      diagnosisId: diagnosisId,
      role: ChatRole.user,
      content: question.trim(),
      languageCode: languageCode,
      status: ChatMessageStatus.pending,
      createdAt: DateTime.now().toIso8601String(),
    );
    await saveMessage(userMessage);

    final diseaseId = diagnosis.diseaseId;
    if (diseaseId == null) {
      await saveMessage(
        userMessage.copyWith(status: ChatMessageStatus.failed),
      );
      throw const ChatUnavailableException(ChatUnavailableReason.serverError);
    }

    try {
      final answer = await apiClient.ask(
        cropId: cropId,
        diseaseId: diseaseId,
        confidence: diagnosis.confidence,
        severity: diagnosis.severity,
        resultState: diagnosis.resultState.name,
        languageCode: languageCode,
        question: question,
        history: history,
        userObservations: userObservations,
        treatmentSummary: treatmentSummary,
        authToken: authToken,
      );

      await saveMessage(userMessage.copyWith(status: ChatMessageStatus.sent));

      final reply = ChatMessage(
        id: _generateId(),
        diagnosisId: diagnosisId,
        role: ChatRole.assistant,
        content: answer,
        languageCode: languageCode,
        status: ChatMessageStatus.sent,
        // Nudged past the question so ordering by createdAt is stable even if
        // both land inside the same millisecond.
        createdAt: DateTime.now()
            .add(const Duration(milliseconds: 1))
            .toIso8601String(),
      );
      await saveMessage(reply);
      return reply;
    } on ChatApiException catch (e) {
      await saveMessage(
        userMessage.copyWith(status: ChatMessageStatus.failed),
      );
      throw ChatUnavailableException(
        _reasonFor(e),
        technicalDetail: e.toString(),
      );
    } catch (e) {
      await saveMessage(
        userMessage.copyWith(status: ChatMessageStatus.failed),
      );
      throw ChatUnavailableException(
        ChatUnavailableReason.serverError,
        technicalDetail: e.toString(),
      );
    }
  }

  static ChatUnavailableReason _reasonFor(ChatApiException e) {
    if (e.isNetworkFailure) return ChatUnavailableReason.offline;
    if (e.statusCode == 429) return ChatUnavailableReason.rateLimited;
    return ChatUnavailableReason.serverError;
  }

  ChatMessage _toEntity(ChatMessageTableData row) {
    return ChatMessage(
      id: row.id,
      diagnosisId: row.diagnosisId,
      role: ChatRole.fromString(row.role),
      content: row.content,
      languageCode: row.languageCode,
      status: ChatMessageStatus.fromString(row.status),
      createdAt: row.createdAt,
    );
  }

  ChatMessageTableCompanion _toCompanion(ChatMessage m) {
    return ChatMessageTableCompanion.insert(
      id: m.id,
      diagnosisId: m.diagnosisId,
      role: m.role.value,
      content: m.content,
      languageCode: m.languageCode,
      status: Value(m.status.value),
      createdAt: m.createdAt,
    );
  }

  static String _generateId() {
    final random = Random();
    const chars = '0123456789abcdef';
    String block(int n) =>
        List.generate(n, (_) => chars[random.nextInt(16)]).join();
    return '${block(8)}-${block(4)}-4${block(3)}-'
        '${'89ab'[random.nextInt(4)]}${block(3)}-${block(12)}';
  }
}
