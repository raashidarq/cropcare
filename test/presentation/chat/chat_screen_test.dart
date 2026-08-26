import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/application/chat/chat_cubit.dart';
import 'package:cropcare/domain/entities/chat_message.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/repositories/chat_repository.dart';
import 'package:cropcare/domain/usecases/chat/delete_chat_message_use_case.dart';
import 'package:cropcare/domain/usecases/chat/get_chat_history_use_case.dart';
import 'package:cropcare/domain/usecases/chat/send_chat_message_use_case.dart';
import 'package:cropcare/presentation/chat/chat_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

/// In-memory transcript with a switchable failure mode.
class _FakeChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = [];
  ChatUnavailableReason? failWith;
  int askCount = 0;
  String? lastQuestion;

  @override
  Future<List<ChatMessage>> getHistory(String diagnosisId) async =>
      List.of(_messages);

  @override
  Future<void> saveMessage(ChatMessage message) async {
    _messages.removeWhere((m) => m.id == message.id);
    _messages.add(message);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    _messages.removeWhere((m) => m.id == messageId);
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
    askCount++;
    lastQuestion = question;

    final user = ChatMessage(
      id: 'u$askCount',
      diagnosisId: diagnosisId,
      role: ChatRole.user,
      content: question,
      languageCode: languageCode,
      status: failWith == null
          ? ChatMessageStatus.sent
          : ChatMessageStatus.failed,
      createdAt: '2026-08-24T12:00:0$askCount',
    );
    await saveMessage(user);

    if (failWith != null) {
      throw ChatUnavailableException(failWith!);
    }

    final reply = ChatMessage(
      id: 'a$askCount',
      diagnosisId: diagnosisId,
      role: ChatRole.assistant,
      content: 'Answer $askCount',
      languageCode: languageCode,
      status: ChatMessageStatus.sent,
      createdAt: '2026-08-24T12:00:0${askCount}z',
    );
    await saveMessage(reply);
    return reply;
  }
}

const _diagnosis = Diagnosis(
  id: 'diag-1',
  scanId: 'scan-1',
  diseaseId: 'tomato_late_blight',
  modelVersionId: 'v1',
  confidence: 0.88,
  severity: 'high',
  resultState: DiagnosisResultState.confident,
  treatmentSource: TreatmentSource.localFallback,
  inferredAt: '2026-08-24T12:00:00Z',
);

Future<_FakeChatRepository> _pump(WidgetTester tester) async {
  final repo = _FakeChatRepository();
  final cubit = ChatCubit(
    getChatHistoryUseCase: GetChatHistoryUseCase(chatRepository: repo),
    sendChatMessageUseCase: SendChatMessageUseCase(chatRepository: repo),
    deleteChatMessageUseCase: DeleteChatMessageUseCase(chatRepository: repo),
    diagnosis: _diagnosis,
    cropId: 'tomato',
    languageCode: 'en',
  );

  await tester.pumpWidget(
    LocalizationProvider(
      languageCode: 'en',
      child: MaterialApp(home: ChatScreen(cubit: cubit)),
    ),
  );
  await tester.pumpAndSettle();
  return repo;
}

void main() {
  testWidgets('An empty conversation offers questions rather than a blank box',
      (tester) async {
    await _pump(tester);

    // A blank chat box is a bad prompt for anyone, and worse for someone who
    // does not write fluently.
    expect(find.text('You could ask'), findsOneWidget);
    expect(find.text('Is the fruit still safe to eat?'), findsOneWidget);
  });

  testWidgets('The AI caveat is present, not dropped on the way into chat',
      (tester) async {
    await _pump(tester);

    // Chat is the easiest place to launder a shaky closed-set guess into
    // confident prose, so the disclaimer is pinned above the transcript.
    expect(find.textContaining('written by AI'), findsOneWidget);
  });

  testWidgets('Asking a question shows it and then the answer', (tester) async {
    await _pump(tester);

    await tester.enterText(
      find.byKey(const Key('chat_input')),
      'Will it spread?',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    expect(find.text('Will it spread?'), findsOneWidget);
    expect(find.text('Answer 1'), findsOneWidget);
  });

  testWidgets('Tapping a suggestion sends it without typing', (tester) async {
    final repo = await _pump(tester);

    await tester.tap(find.text('How fast will this spread?'));
    await tester.pumpAndSettle();

    expect(repo.askCount, 1);
    expect(repo.lastQuestion, 'How fast will this spread?');
  });

  testWidgets('An offline question stays on screen and can be retried',
      (tester) async {
    final repo = await _pump(tester);
    repo.failWith = ChatUnavailableReason.offline;

    await tester.enterText(
      find.byKey(const Key('chat_input')),
      'Can I eat it?',
    );
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    // The question is not lost, and it says why.
    expect(find.text('Can I eat it?'), findsOneWidget);
    expect(find.text('Not sent'), findsOneWidget);
    expect(find.textContaining('could not be sent'), findsOneWidget);

    // Retrying does not require retyping it.
    repo.failWith = null;
    await tester.tap(find.byKey(const Key('chat_retry_button')));
    await tester.pumpAndSettle();

    expect(find.text('Answer 2'), findsOneWidget);
    expect(find.text('Not sent'), findsNothing);
  });

  testWidgets('Rate limiting says so, rather than blaming the connection',
      (tester) async {
    final repo = await _pump(tester);
    repo.failWith = ChatUnavailableReason.rateLimited;

    await tester.enterText(find.byKey(const Key('chat_input')), 'Hello?');
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Too many questions'), findsOneWidget);
  });

  testWidgets('An empty message is not sent', (tester) async {
    final repo = await _pump(tester);

    await tester.enterText(find.byKey(const Key('chat_input')), '   ');
    await tester.tap(find.byKey(const Key('chat_send_button')));
    await tester.pumpAndSettle();

    expect(repo.askCount, 0);
  });

  testWidgets('An existing transcript is restored on open', (tester) async {
    final repo = _FakeChatRepository();
    await repo.saveMessage(const ChatMessage(
      id: 'old-1',
      diagnosisId: 'diag-1',
      role: ChatRole.user,
      content: 'Asked last week',
      languageCode: 'en',
      createdAt: '2026-08-20T09:00:00Z',
    ));
    await repo.saveMessage(const ChatMessage(
      id: 'old-2',
      diagnosisId: 'diag-1',
      role: ChatRole.assistant,
      content: 'Answered last week',
      languageCode: 'en',
      createdAt: '2026-08-20T09:00:01Z',
    ));

    final cubit = ChatCubit(
      getChatHistoryUseCase: GetChatHistoryUseCase(chatRepository: repo),
      sendChatMessageUseCase: SendChatMessageUseCase(chatRepository: repo),
      diagnosis: _diagnosis,
      cropId: 'tomato',
      languageCode: 'en',
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(home: ChatScreen(cubit: cubit)),
      ),
    );
    await tester.pumpAndSettle();

    // Offline-first: the conversation belongs to the device.
    expect(find.text('Asked last week'), findsOneWidget);
    expect(find.text('Answered last week'), findsOneWidget);
    // And the openers are gone, since there is a conversation now.
    expect(find.text('You could ask'), findsNothing);
  });
}
