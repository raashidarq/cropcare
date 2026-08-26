// Voice input in the chat composer.
//
// The mic moved here from a free-text "observations" box on the diagnosis
// screen. Speaking a question has an obvious purpose; speaking into a box you
// were asked to fill in before being told anything did not.
//
// The cases that matter are the ones where the mic must NOT appear or must
// fail legibly: an English-only mic button, or one that silently does nothing,
// is worse for this app's audience than no button at all.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/speech/speech_recognition_service.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/application/chat/chat_cubit.dart';
import 'package:cropcare/domain/entities/chat_message.dart';
import 'package:cropcare/domain/repositories/chat_repository.dart';
import 'package:cropcare/domain/usecases/chat/get_chat_history_use_case.dart';
import 'package:cropcare/domain/usecases/chat/send_chat_message_use_case.dart';
import 'package:cropcare/presentation/chat/chat_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

class _FakeSpeechService implements SpeechRecognitionService {
  final bool available;
  final SpeechUnavailableReason? failWith;

  final ValueNotifier<bool> _listening = ValueNotifier<bool>(false);

  /// Set by the test to drive transcription.
  ValueChanged<String>? emit;

  bool settingsOpened = false;
  int startCount = 0;
  int stopCount = 0;

  _FakeSpeechService({this.available = true, this.failWith});

  @override
  ValueListenable<bool> get isListening => _listening;

  @override
  Future<bool> initialize() async => available;

  @override
  Future<bool> localeAvailable(String languageCode) async => available;

  @override
  Future<void> startListening({
    required String languageCode,
    required ValueChanged<String> onResult,
  }) async {
    startCount++;
    if (failWith != null) throw SpeechUnavailable(failWith!);
    emit = onResult;
    _listening.value = true;
  }

  @override
  Future<void> stopListening() async {
    stopCount++;
    _listening.value = false;
  }

  @override
  Future<void> openAppSettings() async {
    settingsOpened = true;
  }

  @override
  void dispose() {}
}

class _StubChatRepository implements ChatRepository {
  final List<ChatMessage> _messages = [];

  @override
  Future<List<ChatMessage>> getHistory(String diagnosisId) async =>
      List.of(_messages);

  @override
  Future<void> saveMessage(ChatMessage message) async => _messages.add(message);

  @override
  Future<void> deleteMessage(String messageId) async =>
      _messages.removeWhere((m) => m.id == messageId);

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
    final reply = ChatMessage(
      id: 'a1',
      diagnosisId: diagnosisId,
      role: ChatRole.assistant,
      content: 'An answer',
      languageCode: languageCode,
      createdAt: '2026-08-24T12:00:01Z',
    );
    _messages.add(reply);
    return reply;
  }
}

const _diagnosis = Diagnosis(
  id: 'diag-voice',
  scanId: 'scan-voice',
  diseaseId: 'tomato_early_blight',
  modelVersionId: 'cropcare-v1.0',
  confidence: 0.9,
  severity: 'moderate',
  resultState: DiagnosisResultState.confident,
  treatmentSource: TreatmentSource.localFallback,
  inferredAt: '2026-08-24T12:00:00Z',
);

Future<void> _pumpScreen(
  WidgetTester tester,
  SpeechRecognitionService speech, {
  String languageCode = 'en',
}) async {
  final repo = _StubChatRepository();
  await tester.pumpWidget(
    LocalizationProvider(
      languageCode: languageCode,
      child: MaterialApp(
        home: ChatScreen(
          speechService: speech,
          cubit: ChatCubit(
            getChatHistoryUseCase: GetChatHistoryUseCase(chatRepository: repo),
            sendChatMessageUseCase: SendChatMessageUseCase(chatRepository: repo),
            diagnosis: _diagnosis,
            cropId: 'tomato',
            languageCode: languageCode,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Speaking appends to whatever is already typed', (tester) async {
    final speech = _FakeSpeechService();
    await _pumpScreen(tester, speech);

    await tester.enterText(
      find.byKey(const Key('chat_input')),
      'leaves curling',
    );
    await tester.pumpAndSettle();

    final mic = find.byKey(const Key('chat_mic_button'));
    await tester.tap(mic);
    await tester.pumpAndSettle();

    // Partial results arrive while the farmer is still talking.
    speech.emit!('and yellow spots');
    await tester.pumpAndSettle();

    // Appended, not replaced: someone may type a little and then speak the
    // rest, and losing the typed part would be infuriating in a field.
    expect(
      find.text('leaves curling and yellow spots'),
      findsOneWidget,
    );
  });

  testWidgets('The mic toggles to a stop control while listening',
      (tester) async {
    final speech = _FakeSpeechService();
    await _pumpScreen(tester, speech);

    final mic = find.byKey(const Key('chat_mic_button'));
    expect(mic, findsOneWidget);
    expect(find.byIcon(Icons.mic_rounded), findsOneWidget);

    await tester.tap(mic);
    await tester.pumpAndSettle();

    // An explicit stop always exists: silence detection is unreliable in wind
    // and field noise.
    expect(find.byIcon(Icons.stop_rounded), findsOneWidget);

    await tester.tap(mic);
    await tester.pumpAndSettle();
    expect(speech.stopCount, 1);
  });

  testWidgets('No mic is offered when the device cannot hear this language',
      (tester) async {
    final speech = _FakeSpeechService(available: false);
    await _pumpScreen(tester, speech, languageCode: 'si');

    // An English-only mic button would serve exactly the users who least need
    // it, so the control is absent rather than present-and-broken. Typing
    // still works.
    expect(find.byKey(const Key('chat_mic_button')), findsNothing);
    // Typing still works.
    expect(find.byKey(const Key('chat_input')), findsOneWidget);
  });

  testWidgets('A blocked microphone explains itself and offers settings',
      (tester) async {
    final speech = _FakeSpeechService(
      failWith: SpeechUnavailableReason.permissionPermanentlyDenied,
    );
    await _pumpScreen(tester, speech);

    final mic = find.byKey(const Key('chat_mic_button'));
    await tester.tap(mic);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Microphone access is turned off'),
      findsOneWidget,
    );

    await tester.tap(find.text('Open App Settings'));
    await tester.pumpAndSettle();
    expect(speech.settingsOpened, isTrue);
  });

  testWidgets('A plain denial says so without pushing the user to settings',
      (tester) async {
    final speech = _FakeSpeechService(
      failWith: SpeechUnavailableReason.permissionDenied,
    );
    await _pumpScreen(tester, speech);

    final mic = find.byKey(const Key('chat_mic_button'));
    await tester.tap(mic);
    await tester.pumpAndSettle();

    expect(
      find.textContaining('CropCare needs the microphone'),
      findsOneWidget,
    );
    // Still askable, so no settings detour.
    expect(find.text('Open App Settings'), findsNothing);
  });
}
