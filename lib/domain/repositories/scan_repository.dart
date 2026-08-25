import '../entities/scan.dart';
import '../entities/scan_history_item.dart';

abstract class ScanRepository {
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  });

  Future<Scan?> getScanById(String id);

  /// Updates the status of a scan (e.g. 'SHARED', 'ESCALATED', etc.).
  Future<void> updateScanStatus(String scanId, ScanStatus status);

  /// Updates the derived crop ID of a scan after ML inference completes.
  Future<void> updateScanCrop(String scanId, String cropId);

  /// Fetches all scans joined with their diagnosis and crop info, ordered newest first.
  Future<List<ScanHistoryItem>> getScanHistory();

  /// Deletes all local scans and related history records from this device.
  Future<void> deleteAllLocalScans();
}

