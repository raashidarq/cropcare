// Voice input on the observations field.
//
// The cases that matter here are the ones where the mic must NOT appear or
// must fail legibly: an English-only mic button, or one that silently does
// nothing, is worse for this app's audience than no button at all.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/speech/speech_recognition_service.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/treatment.dart';
import 'package:cropcare/domain/repositories/diagnosis_repository.dart';
import 'package:cropcare/domain/repositories/treatment_repository.dart';
import 'package:cropcare/domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'package:cropcare/presentation/diagnosis/diagnosis_result_screen.dart';
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

class _StubTreatmentRepository implements TreatmentRepository {
  @override
  Future<TreatmentResponse?> getLocalTreatmentGuidance({
    required String diseaseId,
    required String languageCode,
  }) async =>
      null;

  @override
  Future<TreatmentResponse> getTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  }) async =>
      const TreatmentResponse(
        summary: 's',
        whatToDo: 'd',
        whatToAvoid: 'a',
        recheckAfterDays: 5,
        interpretationId: 'i',
      );
}

class _StubDiagnosisRepository implements DiagnosisRepository {
  @override
  Future<Diagnosis> createDiagnosis(Diagnosis diagnosis) async => diagnosis;

  @override
  Future<Diagnosis?> getDiagnosisByScanId(String scanId) async => null;

  @override
  Future<void> updateTreatmentSource(
    String diagnosisId, {
    required TreatmentSource source,
    String? llmInterpretationId,
    String? guidelineId,
  }) async {}
}

final _scan = Scan(
  id: 'scan-voice',
  userId: 'user-1',
  cropId: 'tomato',
  imageLocalPath: '/fake/path.jpg',
  status: ScanStatus.diagnosed,
  capturedAt: DateTime.parse('2026-08-24T12:00:00Z'),
  createdAt: DateTime.parse('2026-08-24T12:00:00Z'),
  updatedAt: DateTime.parse('2026-08-24T12:00:00Z'),
);

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
  await tester.pumpWidget(
    LocalizationProvider(
      languageCode: languageCode,
      child: MaterialApp(
        home: DiagnosisResultScreen(
          scan: _scan,
          diagnosis: _diagnosis,
          resolveTreatmentUseCase: ResolveTreatmentUseCase(
            treatmentRepository: _StubTreatmentRepository(),
            diagnosisRepository: _StubDiagnosisRepository(),
          ),
          speechService: speech,
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

    final field = find.byType(TextField);
    await tester.ensureVisible(field);
    await tester.enterText(field, 'leaves curling');
    await tester.pumpAndSettle();

    final mic = find.byKey(const Key('observations_mic_button'));
    await tester.ensureVisible(mic);
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

    final mic = find.byKey(const Key('observations_mic_button'));
    await tester.ensureVisible(mic);

    expect(find.text('Speak instead of typing'), findsOneWidget);

    await tester.tap(mic);
    await tester.pumpAndSettle();

    // An explicit stop always exists: silence detection is unreliable in wind
    // and field noise.
    expect(find.text('Stop'), findsOneWidget);

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
    expect(find.byKey(const Key('observations_mic_button')), findsNothing);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('A blocked microphone explains itself and offers settings',
      (tester) async {
    final speech = _FakeSpeechService(
      failWith: SpeechUnavailableReason.permissionPermanentlyDenied,
    );
    await _pumpScreen(tester, speech);

    final mic = find.byKey(const Key('observations_mic_button'));
    await tester.ensureVisible(mic);
    await tester.tap(mic);
    await tester.pumpAndSettle();

    final banner = find.textContaining('Microphone access is turned off');
    await tester.ensureVisible(banner);
    expect(banner, findsOneWidget);

    final settings = find.text('Open App Settings');
    await tester.ensureVisible(settings);
    await tester.tap(settings);
    await tester.pumpAndSettle();
    expect(speech.settingsOpened, isTrue);
  });

  testWidgets('A plain denial says so without pushing the user to settings',
      (tester) async {
    final speech = _FakeSpeechService(
      failWith: SpeechUnavailableReason.permissionDenied,
    );
    await _pumpScreen(tester, speech);

    final mic = find.byKey(const Key('observations_mic_button'));
    await tester.ensureVisible(mic);
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
