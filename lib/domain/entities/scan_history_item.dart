// lib/domain/entities/scan_history_item.dart
//
// Aggregated domain entity representing a historical scan with diagnosis and crop details.

import 'crop.dart';
import 'diagnosis.dart';
import 'scan.dart';

class ScanHistoryItem {
  final Scan scan;
  final Diagnosis? diagnosis;
  final Crop? crop;

  const ScanHistoryItem({
    required this.scan,
    this.diagnosis,
    this.crop,
  });
}
