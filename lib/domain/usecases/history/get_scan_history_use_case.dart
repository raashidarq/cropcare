// lib/domain/usecases/history/get_scan_history_use_case.dart
//
// Fetches the list of all historical scans with attached diagnosis and crop information.

import '../../entities/scan_history_item.dart';
import '../../repositories/scan_repository.dart';

class GetScanHistoryUseCase {
  final ScanRepository scanRepository;

  GetScanHistoryUseCase(this.scanRepository);

  Future<List<ScanHistoryItem>> call({
    String? cropId,
    String? statusFilter,
  }) async {
    final items = await scanRepository.getScanHistory();

    if (cropId != null && cropId.isNotEmpty) {
      return items.where((i) => i.scan.cropId == cropId).toList();
    }

    if (statusFilter != null && statusFilter.isNotEmpty) {
      if (statusFilter == 'LOW_CONFIDENCE') {
        return items.where((i) => (i.diagnosis?.confidence ?? 1.0) < 0.80).toList();
      } else if (statusFilter == 'SHARED') {
        return items.where((i) => i.scan.status.value == 'SHARED').toList();
      } else if (statusFilter == 'HEALTHY') {
        return items.where((i) => i.diagnosis?.isHealthy ?? false).toList();
      }
    }

    return items;
  }
}
