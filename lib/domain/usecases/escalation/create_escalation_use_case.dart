// lib/domain/usecases/escalation/create_escalation_use_case.dart
//
// Creates an escalation record and updates the scan status to 'SHARED'.

import 'dart:math';

import '../../entities/escalation.dart';
import '../../entities/scan.dart';
import '../../repositories/escalation_repository.dart';
import '../../repositories/scan_repository.dart';

class CreateEscalationUseCase {
  final EscalationRepository escalationRepository;
  final ScanRepository scanRepository;

  CreateEscalationUseCase({
    required this.escalationRepository,
    required this.scanRepository,
  });

  static String _generateUuid() {
    final random = Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40;
    values[8] = (values[8] & 0x3f) | 0x80;
    return [
      values.sublist(0, 4).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(4, 6).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(6, 8).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(8, 10).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
      values.sublist(10, 16).map((b) => b.toRadixString(16).padLeft(2, '0')).join(),
    ].join('-');
  }

  Future<Escalation> call({
    required String scanId,
    required String diagnosisId,
    String? notes,
    String sharedVia = 'WHATSAPP',
  }) async {
    final now = DateTime.now().toIso8601String();
    final escalation = Escalation(
      id: _generateUuid(),
      scanId: scanId,
      diagnosisId: diagnosisId,
      notes: notes,
      sharedVia: sharedVia,
      sharedAt: now,
      createdAt: now,
    );

    // 1. Save escalation record
    final saved = await escalationRepository.createEscalation(escalation);

    // 2. Update scan status to 'SHARED'
    await scanRepository.updateScanStatus(scanId, ScanStatus.shared);

    return saved;
  }
}
