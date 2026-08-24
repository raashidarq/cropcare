import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/escalation.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/escalation_repository.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/escalation/create_escalation_use_case.dart';
import 'package:cropcare/presentation/escalation/escalation_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

class _FakeEscalationRepository implements EscalationRepository {
  @override
  Future<Escalation> createEscalation(Escalation escalation) async => escalation;

  @override
  Future<List<Escalation>> getEscalationsByScanId(String scanId) async => [];
}

class _FakeScanRepository implements ScanRepository {
  @override
  Future<Scan> createScan({required String cropId, required String imageLocalPath, required String userId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {}

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => [];
}

void main() {
  testWidgets('EscalationScreen renders low confidence advisory and WhatsApp button', (tester) async {
    final scan = Scan(
      id: 'scan-1',
      userId: 'user-1',
      cropId: 'tomato',
      imageLocalPath: '/fake/leaf.jpg',
      status: ScanStatus.diagnosed,
      capturedAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    const diagnosis = Diagnosis(
      id: 'diag-1',
      scanId: 'scan-1',
      diseaseId: 'tomato_early_blight',
      modelVersionId: 'cropcare-v1.0',
      confidence: 0.65, // < 80%
      resultState: DiagnosisResultState.lowConfidence,
      treatmentSource: TreatmentSource.llm,
      inferredAt: '2026-08-24T12:00:00Z',
    );

    final useCase = CreateEscalationUseCase(
      escalationRepository: _FakeEscalationRepository(),
      scanRepository: _FakeScanRepository(),
    );

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: EscalationScreen(
            scan: scan,
            diagnosis: diagnosis,
            createEscalationUseCase: useCase,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Escalate to Expert'), findsOneWidget);
    expect(find.text('Low confidence AI result (<80%). We suggest consulting an agricultural expert via WhatsApp.'), findsOneWidget);
    expect(find.byKey(const Key('whatsapp_share_button')), findsOneWidget);
  });
}
