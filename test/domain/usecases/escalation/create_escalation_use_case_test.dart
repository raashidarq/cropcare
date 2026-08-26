import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/escalation.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/escalation_repository.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/escalation/create_escalation_use_case.dart';

class _FakeEscalationRepository implements EscalationRepository {
  Escalation? savedEscalation;

  @override
  Future<Escalation> createEscalation(Escalation escalation) async {
    savedEscalation = escalation;
    return escalation;
  }

  @override
  Future<List<Escalation>> getEscalationsByScanId(String scanId) async => [];
}

class _FakeScanRepository implements ScanRepository {
  String? updatedScanId;
  ScanStatus? updatedStatus;

  @override
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {
    updatedScanId = scanId;
    updatedStatus = status;
  }

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
  group('CreateEscalationUseCase', () {
    test('creates escalation and updates scan status to SHARED', () async {
      final fakeEscRepo = _FakeEscalationRepository();
      final fakeScanRepo = _FakeScanRepository();

      final useCase = CreateEscalationUseCase(
        escalationRepository: fakeEscRepo,
        scanRepository: fakeScanRepo,
      );

      final result = await useCase(
        scanId: 'scan-123',
        diagnosisId: 'diag-456',
        notes: 'Leaves curling and yellowing',
        sharedVia: 'WHATSAPP',
      );

      expect(result.scanId, equals('scan-123'));
      expect(result.diagnosisId, equals('diag-456'));
      expect(result.notes, equals('Leaves curling and yellowing'));
      expect(result.sharedVia, equals('WHATSAPP'));

      expect(fakeEscRepo.savedEscalation, isNotNull);
      expect(fakeScanRepo.updatedScanId, equals('scan-123'));
      expect(fakeScanRepo.updatedStatus, equals(ScanStatus.shared));
    });
  });
}
