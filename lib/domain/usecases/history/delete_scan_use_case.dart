// lib/domain/usecases/history/delete_scan_use_case.dart

import '../../repositories/scan_repository.dart';

class DeleteScanUseCase {
  final ScanRepository scanRepository;

  DeleteScanUseCase({required this.scanRepository});

  /// Removes one scan and everything attached to it, from this device.
  ///
  /// Local only. A scan that already reached the cloud stays there — the
  /// backend has no delete endpoint for scans yet, and the honest thing is to
  /// say so in the UI rather than imply the copy is gone everywhere.
  Future<void> call(String scanId) => scanRepository.deleteScan(scanId);
}
