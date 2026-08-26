// The property that matters most here: a question asked with no signal is
// KEPT. The app is offline-first, and a farmer who types a question standing
// in a field with no bars must not have it evaporate.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/remote/chat_api_client.dart';
import 'package:cropcare/data/repositories/chat_repository_impl.dart';
import 'package:cropcare/domain/entities/chat_message.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/repositories/chat_repository.dart';

/// Serves canned HTTP responses, and records what was sent.
class _StubHttpClient extends http.BaseClient {
  final int statusCode;
  final String body;
  final bool throwNetworkError;

  String? lastBody;

  _StubHttpClient({
    this.statusCode = 200,
    this.body = '{"answer":"Wash and cook it.","message_id":"m1"}',
    this.throwNetworkError = false,
  });

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (throwNetworkError) {
      throw http.ClientException('no route to host');
    }
    lastBody = (request as http.Request).body;
    return http.StreamedResponse(
      Stream.value(body.codeUnits),
      statusCode,
      request: request,
    );
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

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
  });

  tearDown(() async => db.close());

  ChatRepositoryImpl repoWith(_StubHttpClient client) => ChatRepositoryImpl(
        db: db,
        apiClient: ChatApiClient(
          baseUrl: 'https://example.test',
          client: client,
        ),
      );

  test('a successful exchange stores both turns, oldest first', () async {
    final repo = repoWith(_StubHttpClient());

    final reply = await repo.ask(
      diagnosisId: 'diag-1',
      diagnosis: _diagnosis,
      cropId: 'tomato',
      question: 'Can I eat the fruit?',
      languageCode: 'en',
    );

    expect(reply.content, 'Wash and cook it.');
    expect(reply.role, ChatRole.assistant);

    final history = await repo.getHistory('diag-1');
    expect(history, hasLength(2));
    expect(history.first.role, ChatRole.user);
    expect(history.first.content, 'Can I eat the fruit?');
    expect(history.first.status, ChatMessageStatus.sent);
    expect(history.last.role, ChatRole.assistant);
  });

  test('an offline question is kept and marked failed, not discarded',
      () async {
    final repo = repoWith(_StubHttpClient(throwNetworkError: true));

    await expectLater(
      repo.ask(
        diagnosisId: 'diag-1',
        diagnosis: _diagnosis,
        cropId: 'tomato',
        question: 'Will it spread?',
        languageCode: 'en',
      ),
      throwsA(
        isA<ChatUnavailableException>().having(
          (e) => e.reason,
          'reason',
          ChatUnavailableReason.offline,
        ),
      ),
    );

    // The whole point: it is still here, and visibly unsent.
    final history = await repo.getHistory('diag-1');
    expect(history, hasLength(1));
    expect(history.single.content, 'Will it spread?');
    expect(history.single.status, ChatMessageStatus.failed);
  });

  test('a 429 is reported as rate limiting, not as being offline', () async {
    final repo = repoWith(
      _StubHttpClient(statusCode: 429, body: '{"detail":"slow down"}'),
    );

    await expectLater(
      repo.ask(
        diagnosisId: 'diag-1',
        diagnosis: _diagnosis,
        cropId: 'tomato',
        question: 'Again?',
        languageCode: 'en',
      ),
      throwsA(
        isA<ChatUnavailableException>().having(
          (e) => e.reason,
          'reason',
          ChatUnavailableReason.rateLimited,
        ),
      ),
    );
  });

  test('a 500 is reported as a server error', () async {
    final repo = repoWith(
      _StubHttpClient(statusCode: 500, body: '{"detail":"boom"}'),
    );

    await expectLater(
      repo.ask(
        diagnosisId: 'diag-1',
        diagnosis: _diagnosis,
        cropId: 'tomato',
        question: 'Hello?',
        languageCode: 'en',
      ),
      throwsA(
        isA<ChatUnavailableException>().having(
          (e) => e.reason,
          'reason',
          ChatUnavailableReason.serverError,
        ),
      ),
    );
  });

  test('history is sent with the next question, but unsent turns are excluded',
      () async {
    // First exchange succeeds.
    final ok = _StubHttpClient();
    await repoWith(ok).ask(
      diagnosisId: 'diag-1',
      diagnosis: _diagnosis,
      cropId: 'tomato',
      question: 'First question',
      languageCode: 'en',
    );

    // Second fails, leaving a failed user turn in the transcript.
    try {
      await repoWith(_StubHttpClient(throwNetworkError: true)).ask(
        diagnosisId: 'diag-1',
        diagnosis: _diagnosis,
        cropId: 'tomato',
        question: 'Question that never sent',
        languageCode: 'en',
      );
    } catch (_) {}

    // Third succeeds and should carry only the answered turns.
    final third = _StubHttpClient();
    await repoWith(third).ask(
      diagnosisId: 'diag-1',
      diagnosis: _diagnosis,
      cropId: 'tomato',
      question: 'Third question',
      languageCode: 'en',
    );

    expect(third.lastBody, contains('First question'));
    // A question with no answer would present the model with a dangling turn.
    expect(third.lastBody, isNot(contains('Question that never sent')));
  });

  test('the language code travels with the request', () async {
    final client = _StubHttpClient();
    await repoWith(client).ask(
      diagnosisId: 'diag-1',
      diagnosis: _diagnosis,
      cropId: 'tomato',
      question: 'Prashnaya',
      languageCode: 'si',
    );
    expect(client.lastBody, contains('"language_code":"si"'));
  });

  test('confidence and result state travel too, so answers can hedge', () async {
    final client = _StubHttpClient();
    await repoWith(client).ask(
      diagnosisId: 'diag-1',
      diagnosis: const Diagnosis(
        id: 'diag-1',
        scanId: 'scan-1',
        diseaseId: 'tomato_late_blight',
        modelVersionId: 'v1',
        confidence: 0.35,
        severity: 'high',
        resultState: DiagnosisResultState.lowConfidence,
        treatmentSource: TreatmentSource.localFallback,
        inferredAt: '2026-08-24T12:00:00Z',
      ),
      cropId: 'tomato',
      question: 'What is it?',
      languageCode: 'en',
    );
    expect(client.lastBody, contains('"result_state":"lowConfidence"'));
    expect(client.lastBody, contains('0.35'));
  });

  test('a transcript survives being read back on a new repository instance',
      () async {
    await repoWith(_StubHttpClient()).ask(
      diagnosisId: 'diag-1',
      diagnosis: _diagnosis,
      cropId: 'tomato',
      question: 'Persisted?',
      languageCode: 'en',
    );

    // A different repository over the same database, as after a restart.
    final reopened = repoWith(_StubHttpClient());
    final history = await reopened.getHistory('diag-1');
    expect(history, hasLength(2));
    expect(history.first.content, 'Persisted?');
  });

  test('history is scoped to one diagnosis', () async {
    await repoWith(_StubHttpClient()).ask(
      diagnosisId: 'diag-1',
      diagnosis: _diagnosis,
      cropId: 'tomato',
      question: 'About diag 1',
      languageCode: 'en',
    );

    expect(await repoWith(_StubHttpClient()).getHistory('diag-2'), isEmpty);
  });
}
