import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/domain/entities/crop.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/history/export_scan_history_use_case.dart';

class _FakeScanRepository implements ScanRepository {
  List<ScanHistoryItem> historyItems = [];

  @override
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  }) =>
      throw UnimplementedError();

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => historyItems;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {}

  @override
  Future<void> updateScanCrop(String scanId, String cropId) async {}

  @override
  Future<void> deleteAllLocalScans() async {}
}

void main() {
  group('ExportScanHistoryUseCase', () {
    late _FakeScanRepository fakeRepo;
    late ExportScanHistoryUseCase useCase;

    setUp(() {
      fakeRepo = _FakeScanRepository();
      useCase = ExportScanHistoryUseCase(fakeRepo);
    });

    test('generateCsv formats headers and rows correctly with escaping', () {
      final items = [
        ScanHistoryItem(
          scan: Scan(
            id: 'scan-1',
            userId: 'user-1',
            cropId: 'tomato',
            imageLocalPath: '/path/to/img1.jpg',
            status: ScanStatus.diagnosed,
            capturedAt: DateTime.parse('2026-08-25T10:00:00Z'),
            createdAt: DateTime.parse('2026-08-25T10:00:00Z'),
            updatedAt: DateTime.parse('2026-08-25T10:00:00Z'),
          ),
          crop: const Crop(
            id: 'tomato',
            nameEn: 'Tomato',
            nameSi: 'තක්කාලි',
            nameTa: 'தக்காளி',
          ),
          diagnosis: const Diagnosis(
            id: 'diag-1',
            scanId: 'scan-1',
            diseaseId: 'Tomato_Early_blight',
            modelVersionId: 'v1.0',
            confidence: 0.9456,
            resultState: DiagnosisResultState.confident,
            severity: 'MODERATE',
            alternatives: [],
            treatmentSource: TreatmentSource.localFallback,
            inferredAt: '2026-08-25T10:00:00Z',
          ),
        ),
        ScanHistoryItem(
          scan: Scan(
            id: 'scan-2,with,comma',
            userId: 'user-1',
            cropId: 'paddy',
            imageLocalPath: '/path/to/img2.jpg',
            status: ScanStatus.diagnosed,
            capturedAt: DateTime.parse('2026-08-25T11:00:00Z'),
            createdAt: DateTime.parse('2026-08-25T11:00:00Z'),
            updatedAt: DateTime.parse('2026-08-25T11:00:00Z'),
          ),
          crop: const Crop(
            id: 'paddy',
            nameEn: 'Paddy / Rice',
            nameSi: 'වී',
            nameTa: 'நெல்',
          ),
          diagnosis: null,
        ),
      ];

      final csv = useCase.generateCsv(items);

      expect(
        csv,
        contains('Scan ID,Captured Date,Crop,Disease,Confidence (%),Severity,Status,Remote Scan ID'),
      );
      expect(csv, contains('scan-1'));
      expect(csv, contains('Tomato'));
      expect(csv, contains('Tomato_Early_blight'));
      expect(csv, contains('94.6'));
      expect(csv, contains('MODERATE'));
      expect(csv, contains('DIAGNOSED'));

      // Verify escaped comma
      expect(csv, contains('"scan-2,with,comma"'));
      expect(csv, contains('Paddy / Rice'));
    });
  });
}
