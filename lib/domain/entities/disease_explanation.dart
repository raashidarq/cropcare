// lib/domain/entities/disease_explanation.dart
//
// Pure Dart domain entity — no Drift, no Flutter dependencies.
//
// The offline "help me understand this result" content, as opposed to
// TreatmentResponse's "help me fix it" content. Every field is nullable
// because this content is authored and shipped separately from the app: a
// device may hold a partial explanation, or none at all, and the UI has to
// degrade field by field rather than all-or-nothing.

/// One condition a diagnosis is easily mistaken for.
class DiseaseConfusion {
  /// Display name of the look-alike, already resolved to the active language.
  ///
  /// May name another modelled disease, or something the model cannot predict
  /// at all — nutrient deficiency, water stress, spray burn — which is
  /// usually the more dangerous confusion.
  final String? label;

  /// How to tell this apart from the diagnosed disease in the field.
  final String? distinguishingSymptoms;

  /// The look-alike's disease id, when it is one the app knows about.
  /// Null for non-disease conditions.
  final String? confusedWithDiseaseId;

  const DiseaseConfusion({
    this.label,
    this.distinguishingSymptoms,
    this.confusedWithDiseaseId,
  });

  /// True when there is nothing worth rendering for this entry.
  bool get isEmpty =>
      (label == null || label!.trim().isEmpty) &&
      (distinguishingSymptoms == null ||
          distinguishingSymptoms!.trim().isEmpty);
}

/// Offline explanation of a diagnosis, resolved to one language.
class DiseaseExplanation {
  final String diseaseId;

  /// What the plant is — crop, growth habit, what a healthy one looks like.
  final String? plantDescription;

  /// What the scan result suggests, and how much weight to put on it.
  final String? resultMeaning;

  /// Conditions this result is commonly confused with, in display order.
  final List<DiseaseConfusion> confusions;

  /// Content revision the device holds, for support and debugging.
  final String? explanationVersion;

  const DiseaseExplanation({
    required this.diseaseId,
    this.plantDescription,
    this.resultMeaning,
    this.confusions = const [],
    this.explanationVersion,
  });

  bool get hasPlantDescription =>
      plantDescription != null && plantDescription!.trim().isNotEmpty;

  bool get hasResultMeaning =>
      resultMeaning != null && resultMeaning!.trim().isNotEmpty;

  bool get hasConfusions => confusions.any((c) => !c.isEmpty);

  /// True when the device holds no usable explanation content for this
  /// disease — the expected state until content is delivered.
  bool get isEmpty =>
      !hasPlantDescription && !hasResultMeaning && !hasConfusions;
}
