// lib/domain/entities/escalation.dart
//
// Pure Dart domain entity for expert escalation and WhatsApp share records.

class Escalation {
  final String id;
  final String scanId;
  final String diagnosisId;
  final String? notes;
  final String sharedVia;
  final String? sharedAt;
  final String createdAt;

  const Escalation({
    required this.id,
    required this.scanId,
    required this.diagnosisId,
    this.notes,
    this.sharedVia = 'WHATSAPP',
    this.sharedAt,
    required this.createdAt,
  });
}
