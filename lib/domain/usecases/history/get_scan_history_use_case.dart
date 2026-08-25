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

    var result = items;

    if (cropId != null && cropId.isNotEmpty && cropId != 'ALL') {
      result = result.where((i) => i.scan.cropId.toLowerCase() == cropId.toLowerCase()).toList();
    }

    if (statusFilter != null && statusFilter.isNotEmpty && statusFilter != 'ALL') {
      if (statusFilter == 'LOW_CONFIDENCE') {
        result = result.where((i) => (i.diagnosis?.confidence ?? 1.0) < 0.80).toList();
      } else if (statusFilter == 'SHARED') {
        result = result.where((i) => i.scan.status.value == 'SHARED').toList();
      } else if (statusFilter == 'HEALTHY') {
        result = result.where((i) => i.diagnosis?.isHealthy ?? false).toList();
      } else if (statusFilter == 'DATE_TODAY') {
        final now = DateTime.now();
        result = result.where((i) {
          final d = i.scan.capturedAt;
          return d.year == now.year && d.month == now.month && d.day == now.day;
        }).toList();
      } else if (statusFilter == 'DATE_WEEK') {
        final now = DateTime.now();
        final sevenDaysAgo = now.subtract(const Duration(days: 7));
        result = result.where((i) => i.scan.capturedAt.isAfter(sevenDaysAgo)).toList();
      } else if (statusFilter == 'DATE_MONTH') {
        final now = DateTime.now();
        final thirtyDaysAgo = now.subtract(const Duration(days: 30));
        result = result.where((i) => i.scan.capturedAt.isAfter(thirtyDaysAgo)).toList();
      } else if (statusFilter.startsWith('CROP_')) {
        final targetCrop = statusFilter.substring(5).toLowerCase();
        result = result.where((i) => i.scan.cropId.toLowerCase() == targetCrop).toList();
      }
    }

    return result;
  }
}
