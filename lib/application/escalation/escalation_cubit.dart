// lib/application/escalation/escalation_cubit.dart
//
// Handles formatting escalation packages and invoking native WhatsApp share with photo.

import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/diagnosis.dart';
import '../../domain/entities/scan.dart';
import '../../domain/usecases/escalation/create_escalation_use_case.dart';
import 'escalation_state.dart';

typedef ShareFilesFunction = Future<ShareResult> Function(
  List<XFile> files, {
  String? text,
  String? subject,
});

typedef ShareTextFunction = Future<ShareResult> Function(
  String text, {
  String? subject,
});

class EscalationCubit extends Cubit<EscalationState> {
  final CreateEscalationUseCase createEscalationUseCase;
  final ShareFilesFunction _shareFiles;
  final ShareTextFunction _shareText;

  EscalationCubit({
    required this.createEscalationUseCase,
    ShareFilesFunction? shareFiles,
    ShareTextFunction? shareText,
  })  : _shareFiles = shareFiles ?? Share.shareXFiles,
        _shareText = shareText ?? Share.share,
        super(const EscalationInitial());

  String formatEscalationText({
    required Scan scan,
    required Diagnosis diagnosis,
    String? farmerNotes,
  }) {
    final disease = diagnosis.diseaseId != null
        ? diagnosis.diseaseId!.replaceAll('_', ' ').toUpperCase()
        : 'UNKNOWN ISSUE';
    final confidencePct = (diagnosis.confidence * 100).toStringAsFixed(1);
    final severity = diagnosis.severity != null ? ' | Severity: ${diagnosis.severity!.toUpperCase()}' : '';

    final buffer = StringBuffer();
    buffer.writeln('🌿 *CropCare Diagnosis Escalation*');
    buffer.writeln('• *Crop:* ${scan.cropId.toUpperCase()}');
    buffer.writeln('• *Predicted Issue:* $disease');
    buffer.writeln('• *AI Confidence:* $confidencePct%$severity');
    buffer.writeln('• *Scan ID:* ${scan.id.substring(0, scan.id.length >= 8 ? 8 : scan.id.length)}');

    if (farmerNotes != null && farmerNotes.trim().isNotEmpty) {
      buffer.writeln('\n📝 *Farmer Observations:*');
      buffer.writeln(farmerNotes.trim());
    }

    buffer.writeln('\n_Sent via CropCare Smart Crop Health Companion_');
    return buffer.toString();
  }

  Future<void> shareViaWhatsApp({
    required Scan scan,
    required Diagnosis diagnosis,
    String? farmerNotes,
  }) async {
    emit(const EscalationSharing());
    try {
      final formattedText = formatEscalationText(
        scan: scan,
        diagnosis: diagnosis,
        farmerNotes: farmerNotes,
      );

      // 1. Record escalation and mark scan as SHARED in SQLite
      await createEscalationUseCase(
        scanId: scan.id,
        diagnosisId: diagnosis.id,
        notes: farmerNotes,
        sharedVia: 'WHATSAPP',
      );

      // 2. Share with attached photo file
      final file = File(scan.imageLocalPath);
      if (await file.exists()) {
        await _shareFiles(
          [XFile(scan.imageLocalPath)],
          text: formattedText,
          subject: 'CropCare Diagnosis: ${scan.cropId}',
        );
      } else {
        // Fallback: share text only if file missing
        await _shareText(
          formattedText,
          subject: 'CropCare Diagnosis: ${scan.cropId}',
        );
      }

      emit(EscalationSharedSuccess(shareMessage: formattedText));
    } catch (e) {
      emit(EscalationError(e.toString()));
    }
  }
}
