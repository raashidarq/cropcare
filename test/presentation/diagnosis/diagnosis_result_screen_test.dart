import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/treatment.dart';
import 'package:cropcare/domain/repositories/diagnosis_repository.dart';
import 'package:cropcare/domain/repositories/treatment_repository.dart';
import 'package:cropcare/domain/usecases/diagnosis/resolve_treatment_use_case.dart';
import 'package:cropcare/presentation/diagnosis/diagnosis_result_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

class _FakeTreatmentRepository implements TreatmentRepository {
  @override
  Future<TreatmentResponse> getTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  }) async {
    return const TreatmentResponse(
      summary: 'Mock summary from Gemini',
      whatToDo: 'Mock what to do',
      whatToAvoid: 'Mock what to avoid',
      recheckAfterDays: 4,
      interpretationId: 'interp-123',
    );
  }
}

class _FakeDiagnosisRepository implements DiagnosisRepository {
  @override
  Future<Diagnosis> createDiagnosis(Diagnosis diagnosis) async => diagnosis;

  @override
  Future<Diagnosis?> getDiagnosisByScanId(String scanId) async => null;

  @override
  Future<void> updateTreatmentSource(
    String diagnosisId, {
    required TreatmentSource source,
    String? guidelineId,
    String? llmInterpretationId,
  }) async {}
}

void main() {
  testWidgets('DiagnosisResultScreen renders healthy card without treatment request',
      (tester) async {
    final scan = Scan(
      id: 'scan-1',
      userId: 'user-1',
      cropId: 'tomato',
      imageLocalPath: '/fake/path.jpg',
      status: ScanStatus.diagnosed,
      capturedAt: DateTime.parse('2026-08-24T12:00:00Z'),
      createdAt: DateTime.parse('2026-08-24T12:00:00Z'),
      updatedAt: DateTime.parse('2026-08-24T12:00:00Z'),
    );

    const diagnosis = Diagnosis(
      id: 'diag-1',
      scanId: 'scan-1',
      diseaseId: 'tomato_healthy',
      modelVersionId: 'cropcare-v1.0',
      confidence: 0.98,
      resultState: DiagnosisResultState.confident,
      treatmentSource: TreatmentSource.localFallback,
      inferredAt: '2026-08-24T12:00:00Z',
    );

    final useCase = ResolveTreatmentUseCase(
      treatmentRepository: _FakeTreatmentRepository(),
      diagnosisRepository: _FakeDiagnosisRepository(),
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: DiagnosisResultScreen(
            scan: scan,
            diagnosis: diagnosis,
            resolveTreatmentUseCase: useCase,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Healthy Plant'), findsOneWidget);
    expect(
      find.text('Your plant appears healthy! Keep up your current crop management practices.'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('diagnosis_scan_again_button')), findsOneWidget);
    expect(find.text('Treatment Guidance'), findsNothing);
  });

  testWidgets('DiagnosisResultScreen renders diseased diagnosis with treatment card',
      (tester) async {
    final scan = Scan(
      id: 'scan-2',
      userId: 'user-1',
      cropId: 'tomato',
      imageLocalPath: '/fake/path.jpg',
      status: ScanStatus.diagnosed,
      capturedAt: DateTime.parse('2026-08-24T12:00:00Z'),
      createdAt: DateTime.parse('2026-08-24T12:00:00Z'),
      updatedAt: DateTime.parse('2026-08-24T12:00:00Z'),
    );

    const diagnosis = Diagnosis(
      id: 'diag-2',
      scanId: 'scan-2',
      diseaseId: 'tomato_early_blight',
      modelVersionId: 'cropcare-v1.0',
      confidence: 0.89,
      severity: 'moderate',
      resultState: DiagnosisResultState.confident,
      treatmentSource: TreatmentSource.localFallback,
      inferredAt: '2026-08-24T12:00:00Z',
    );

    final useCase = ResolveTreatmentUseCase(
      treatmentRepository: _FakeTreatmentRepository(),
      diagnosisRepository: _FakeDiagnosisRepository(),
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: DiagnosisResultScreen(
            scan: scan,
            diagnosis: diagnosis,
            resolveTreatmentUseCase: useCase,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Tomato Early Blight'), findsOneWidget);
    expect(find.text('Treatment Guidance'), findsOneWidget);
    expect(find.text('Mock summary from Gemini'), findsOneWidget);
    expect(find.text('Mock what to do'), findsOneWidget);
    expect(find.text('Mock what to avoid'), findsOneWidget);
    expect(find.text('Recheck in 4 days'), findsOneWidget);
  });

  testWidgets('DiagnosisResultScreen renders low confidence advisory when confidence < 80%',
      (tester) async {
    final scan = Scan(
      id: 'scan-3',
      userId: 'user-1',
      cropId: 'tomato',
      imageLocalPath: '/fake/path.jpg',
      status: ScanStatus.diagnosed,
      capturedAt: DateTime.parse('2026-08-24T12:00:00Z'),
      createdAt: DateTime.parse('2026-08-24T12:00:00Z'),
      updatedAt: DateTime.parse('2026-08-24T12:00:00Z'),
    );

    const diagnosis = Diagnosis(
      id: 'diag-3',
      scanId: 'scan-3',
      diseaseId: 'tomato_early_blight',
      modelVersionId: 'cropcare-v1.0',
      confidence: 0.72,
      severity: 'moderate',
      resultState: DiagnosisResultState.lowConfidence,
      treatmentSource: TreatmentSource.localFallback,
      inferredAt: '2026-08-24T12:00:00Z',
    );

    final useCase = ResolveTreatmentUseCase(
      treatmentRepository: _FakeTreatmentRepository(),
      diagnosisRepository: _FakeDiagnosisRepository(),
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: DiagnosisResultScreen(
            scan: scan,
            diagnosis: diagnosis,
            resolveTreatmentUseCase: useCase,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(
      find.text('Low confidence AI result (<80%). We suggest consulting an agricultural expert via WhatsApp.'),
      findsOneWidget,
    );
    expect(find.text('WhatsApp Share with Expert'), findsWidgets);
  });
}
