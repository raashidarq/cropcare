// lib/domain/repositories/escalation_repository.dart
//
// Abstract interface for persisting and retrieving escalation records.

import '../entities/escalation.dart';

abstract class EscalationRepository {
  Future<Escalation> createEscalation(Escalation escalation);
  Future<List<Escalation>> getEscalationsByScanId(String scanId);
}
