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

  /// Marks a scan as rejected by image validation.
  ///
  /// Records the rejection in `image_validation`, sets the scan status to
  /// INVALID_IMAGE, cancels the queued cloud upload that [createScan] had
  /// already enqueued, and deletes the local image file.
  Future<void> rejectInvalidScan({
    required String scanId,
    required String rejectionReason,
  });

  /// Deletes scans that produced no usable result — rejected images, failed
  /// analyses, cancelled attempts — along with their rows, queued uploads and
  /// image files. Returns how many were removed.
  ///
  /// History is meant to be a record of plants the farmer has checked. Failed
  /// attempts filled it with "Unknown" entries that carried no information
  /// and could not be acted on.
  Future<int> purgeFailedScans();

  /// Fetches scans that produced a usable result, joined with their diagnosis
  /// and crop info, ordered newest first. Failed attempts are excluded.
  Future<List<ScanHistoryItem>> getScanHistory();

  /// Deletes all local scans and related history records from this device.
  /// Removes one scan and everything that belongs to it: its diagnosis, any
  /// chat about that diagnosis, its validation record, any escalation, its
  /// queued sync operations, and the photo on disk.
  ///
  /// Local only. A scan already uploaded stays in the cloud — see
  /// `SyncRepository` for remote deletion.
  Future<void> deleteScan(String scanId);

  Future<void> deleteAllLocalScans();
}

