import '../entities/disease_explanation.dart';

abstract class DiseaseExplanationRepository {
  /// Offline explanation for [diseaseId], with text resolved to
  /// [languageCode] (falling back to English per field when a translation
  /// is missing).
  ///
  /// Returns null when the device holds no explanation row at all. An
  /// explanation that exists but is only partly filled in comes back as a
  /// [DiseaseExplanation] with null fields, so callers can render what is
  /// there — see [DiseaseExplanation.isEmpty].
  Future<DiseaseExplanation?> getExplanation({
    required String diseaseId,
    required String languageCode,
  });
}
