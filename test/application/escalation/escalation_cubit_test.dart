import 'package:flutter_test/flutter_test.dart';
import 'package:share_plus/share_plus.dart';

import 'package:cropcare/application/escalation/escalation_cubit.dart';
import 'package:cropcare/application/escalation/escalation_state.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/escalation.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/escalation_repository.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/escalation/create_escalation_use_case.dart';

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
  Future<void> updateScanCrop(String scanId, String cropId) async {}

  @override
  Future<void> rejectInvalidScan({
    required String scanId,
    required String rejectionReason,
  }) async {}

  @override
  Future<int> purgeFailedScans() async => 0;

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => [];

  @override
  Future<void> deleteAllLocalScans() async {}
}

void main() {
  group('EscalationCubit', () {
    late CreateEscalationUseCase createEscalationUseCase;

    setUp(() {
      createEscalationUseCase = CreateEscalationUseCase(
        escalationRepository: _FakeEscalationRepository(),
        scanRepository: _FakeScanRepository(),
      );
    });

    test('formatEscalationText includes crop, disease, confidence, and farmer notes', () {
      final cubit = EscalationCubit(createEscalationUseCase: createEscalationUseCase);

      final scan = Scan(
        id: 'scan-12345678',
        userId: 'u1',
        cropId: 'tomato',
        imageLocalPath: '/tmp/leaf.jpg',
        status: ScanStatus.diagnosed,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const diagnosis = Diagnosis(
        id: 'diag-1',
        scanId: 'scan-12345678',
        diseaseId: 'tomato_early_blight',
        modelVersionId: 'v1',
        confidence: 0.725,
        severity: 'moderate',
        resultState: DiagnosisResultState.lowConfidence,
        treatmentSource: TreatmentSource.llm,
        inferredAt: '2026-08-24T12:00:00Z',
      );

      final text = cubit.formatEscalationText(
        scan: scan,
        diagnosis: diagnosis,
        farmerNotes: 'Lower leaves spotted with brown rings',
      );

      expect(text, contains('TOMATO'));
      expect(text, contains('TOMATO EARLY BLIGHT'));
      expect(text, contains('72.5%'));
      expect(text, contains('MODERATE'));
      expect(text, contains('Lower leaves spotted with brown rings'));
    });

    test('shareViaWhatsApp emits Sharing and SharedSuccess states', () async {
      String? sharedText;

      final cubit = EscalationCubit(
        createEscalationUseCase: createEscalationUseCase,
        shareFiles: (files, {subject, text}) async {
          sharedText = text;
          return const ShareResult('success', ShareResultStatus.success);
        },
        shareText: (text, {subject}) async {
          sharedText = text;
          return const ShareResult('success', ShareResultStatus.success);
        },
      );

      final scan = Scan(
        id: 'scan-1',
        userId: 'u1',
        cropId: 'tomato',
        imageLocalPath: '/tmp/leaf.jpg',
        status: ScanStatus.diagnosed,
        capturedAt: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      const diagnosis = Diagnosis(
        id: 'diag-1',
        scanId: 'scan-1',
        diseaseId: 'tomato_early_blight',
        modelVersionId: 'v1',
        confidence: 0.75,
        resultState: DiagnosisResultState.lowConfidence,
        treatmentSource: TreatmentSource.llm,
        inferredAt: '2026-08-24T12:00:00Z',
      );

      final states = <EscalationState>[];
      final sub = cubit.stream.listen(states.add);

      await cubit.shareViaWhatsApp(
        scan: scan,
        diagnosis: diagnosis,
        farmerNotes: 'Notes for agronomist',
      );

      await Future.delayed(Duration.zero);

      expect(states.length, equals(2));
      expect(states[0], isA<EscalationSharing>());
      expect(states[1], isA<EscalationSharedSuccess>());
      expect(sharedText, contains('TOMATO'));

      await sub.cancel();
    });
  });
}
