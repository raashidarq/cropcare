// lib/domain/usecases/history/export_scan_history_use_case.dart
//
// Exports all local scan history items into a CSV file and triggers native sharing.

import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../entities/scan_history_item.dart';
import '../../repositories/scan_repository.dart';

class ExportScanHistoryUseCase {
  final ScanRepository scanRepository;

  ExportScanHistoryUseCase(this.scanRepository);

  /// Generates CSV content from scan history items.
  String generateCsv(List<ScanHistoryItem> items) {
    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
      'Scan ID,Captured Date,Crop,Disease,Confidence (%),Severity,Status,Remote Scan ID',
    );

    for (final item in items) {
      final scanId = _escapeCsv(item.scan.id);
      final capturedDate = _escapeCsv(item.scan.capturedAt.toIso8601String());
      final crop = _escapeCsv(item.crop?.nameEn ?? item.scan.cropId);
      final disease = _escapeCsv(item.diagnosis?.diseaseId ?? (item.diagnosis?.isHealthy == true ? 'Healthy' : 'N/A'));
      final confidence = item.diagnosis != null
          ? (item.diagnosis!.confidence * 100).toStringAsFixed(1)
          : 'N/A';
      final severity = _escapeCsv(item.diagnosis?.severity ?? 'N/A');
      final status = _escapeCsv(item.scan.status.value);
      final remoteId = _escapeCsv(item.scan.remoteScanId ?? '');

      buffer.writeln(
        '$scanId,$capturedDate,$crop,$disease,$confidence,$severity,$status,$remoteId',
      );
    }

    return buffer.toString();
  }

  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Exports local scan history to a temporary CSV file and opens the share sheet.
  /// Returns the number of items exported, or 0 if no scans exist.
  Future<int> execute() async {
    final items = await scanRepository.getScanHistory();
    if (items.isEmpty) {
      return 0;
    }

    final csvContent = generateCsv(items);
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/cropcare_scan_history_$timestamp.csv');
    await file.writeAsString(csvContent);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      subject: 'CropCare Scan History Export',
      text: 'Exported scan records from CropCare app.',
    );

    return items.length;
  }
}
