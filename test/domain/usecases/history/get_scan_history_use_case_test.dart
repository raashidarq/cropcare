import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/crop.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/history/get_scan_history_use_case.dart';

class _FakeScanRepository implements ScanRepository {
  List<ScanHistoryItem> historyToReturn = [];

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
  Future<List<ScanHistoryItem>> getScanHistory() async => historyToReturn;
  @override
  Future<void> deleteScan(String scanId) async {}


  @override
  Future<void> deleteAllLocalScans() async {}
}

void main() {
  group('GetScanHistoryUseCase', () {
    test('returns all history items and applies filters correctly', () async {
      final fakeScanRepo = _FakeScanRepository();
      const crop = Crop(id: 'tomato', nameEn: 'Tomato', nameSi: 'තක්කාලි', nameTa: 'தக்காளி');

      final item1 = ScanHistoryItem(
        scan: Scan(
          id: 's1',
          userId: 'u1',
          cropId: 'tomato',
          imageLocalPath: '/path1.jpg',
          status: ScanStatus.diagnosed,
          capturedAt: DateTime.parse('2026-08-24T12:00:00Z'),
          createdAt: DateTime.parse('2026-08-24T12:00:00Z'),
          updatedAt: DateTime.parse('2026-08-24T12:00:00Z'),
        ),
        diagnosis: const Diagnosis(
          id: 'd1',
          scanId: 's1',
          diseaseId: 'tomato_early_blight',
          modelVersionId: 'v1',
          confidence: 0.75, // Low confidence
          resultState: DiagnosisResultState.lowConfidence,
          treatmentSource: TreatmentSource.llm,
          inferredAt: '2026-08-24T12:00:00Z',
        ),
        crop: crop,
      );

      final item2 = ScanHistoryItem(
        scan: Scan(
          id: 's2',
          userId: 'u1',
          cropId: 'chili',
          imageLocalPath: '/path2.jpg',
          status: ScanStatus.shared,
          capturedAt: DateTime.parse('2026-08-24T11:00:00Z'),
          createdAt: DateTime.parse('2026-08-24T11:00:00Z'),
          updatedAt: DateTime.parse('2026-08-24T11:00:00Z'),
        ),
        diagnosis: const Diagnosis(
          id: 'd2',
          scanId: 's2',
          diseaseId: 'chili_healthy',
          modelVersionId: 'v1',
          confidence: 0.95,
          resultState: DiagnosisResultState.confident,
          treatmentSource: TreatmentSource.localFallback,
          inferredAt: '2026-08-24T11:00:00Z',
        ),
      );

      fakeScanRepo.historyToReturn = [item1, item2];
      final useCase = GetScanHistoryUseCase(fakeScanRepo);

      // Unfiltered
      final all = await useCase();
      expect(all.length, equals(2));

      // Filter by crop
      final tomatoOnly = await useCase(cropId: 'tomato');
      expect(tomatoOnly.length, equals(1));
      expect(tomatoOnly.first.scan.id, equals('s1'));

      // Filter by low confidence
      final lowConf = await useCase(statusFilter: 'LOW_CONFIDENCE');
      expect(lowConf.length, equals(1));
      expect(lowConf.first.scan.id, equals('s1'));

      // Filter by shared
      final shared = await useCase(statusFilter: 'SHARED');
      expect(shared.length, equals(1));
      expect(shared.first.scan.id, equals('s2'));

      // Filter by healthy
      final healthy = await useCase(statusFilter: 'HEALTHY');
      expect(healthy.length, equals(1));
      expect(healthy.first.scan.id, equals('s2'));

      // Filter by CROP_CHILI statusFilter
      final chiliFilter = await useCase(statusFilter: 'CROP_CHILI');
      expect(chiliFilter.length, equals(1));
      expect(chiliFilter.first.scan.id, equals('s2'));

      // Filter by DATE_WEEK
      final thisWeek = await useCase(statusFilter: 'DATE_WEEK');
      expect(thisWeek, isNotEmpty);
    });
  });
}
