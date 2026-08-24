// lib/domain/entities/diagnosis.dart
//
// Pure Dart domain entity — no Drift, no Flutter dependencies.

/// Result state of a diagnosis run.
enum DiagnosisResultState {
  confident,       // confidence >= threshold
  lowConfidence,   // confidence < threshold but a class was identified
  unsupported,     // top class belongs to a crop not in our system (e.g. Apple)
  analysisFailed,  // inference threw an exception
}

/// Source of the treatment guidance attached to this diagnosis.
enum TreatmentSource {
  localFallback, // from treatment_guideline table
  llm,           // from remote LLM (future)
}

/// A single alternative prediction from the model.
class AlternativePrediction {
  final String diseaseId;
  final double confidence;

  const AlternativePrediction({
    required this.diseaseId,
    required this.confidence,
  });
}

/// Domain entity representing one ML inference result for a scan.
class Diagnosis {
  final String id;
  final String scanId;

  /// Null when resultState == unsupported or analysisFailed.
  final String? diseaseId;

  /// ID of the ModelVersion row used to produce this result.
  final String modelVersionId;

  /// Softmax probability of the top class, 0.0–1.0.
  final double confidence;

  final DiagnosisResultState resultState;

  /// Severity inherited from the disease row. Null for healthy / unsupported.
  final String? severity;

  /// Top-N runner-up predictions. Empty list if not available.
  final List<AlternativePrediction> alternatives;

  final TreatmentSource treatmentSource;

  /// Set when treatmentSource == localFallback.
  final String? treatmentGuidelineId;

  /// ISO8601 timestamp.
  final String inferredAt;

  const Diagnosis({
    required this.id,
    required this.scanId,
    this.diseaseId,
    required this.modelVersionId,
    required this.confidence,
    required this.resultState,
    this.severity,
    this.alternatives = const [],
    required this.treatmentSource,
    this.treatmentGuidelineId,
    required this.inferredAt,
  });

  bool get isHealthy => diseaseId?.endsWith('_healthy') ?? false;
}
