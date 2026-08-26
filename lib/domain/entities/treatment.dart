// lib/domain/entities/treatment.dart
//
// Pure Dart domain entity for treatment guidance.

class TreatmentResponse {
  final String summary;

  /// Prose forms. Kept because the on-device guideline table stores prose, and
  /// because read-aloud wants flowing sentences rather than a list.
  final String whatToDo;
  final String whatToAvoid;

  /// The forms the screen renders: short, ordered, one action each.
  ///
  /// The backend authors these directly. For on-device guidelines, which are
  /// stored as prose, they are derived by splitting on sentence boundaries —
  /// see [splitIntoSteps]. Either way the farmer gets a list they can work
  /// through one line at a time instead of a paragraph to parse.
  final List<String> doSteps;
  final List<String> avoidSteps;

  final int? recheckAfterDays;
  final String? interpretationId;

  const TreatmentResponse({
    required this.summary,
    required this.whatToDo,
    required this.whatToAvoid,
    this.doSteps = const [],
    this.avoidSteps = const [],
    this.recheckAfterDays,
    this.interpretationId,
  });

  /// Steps to render for "do this", falling back to splitting the prose when
  /// the source did not provide a list.
  List<String> get effectiveDoSteps =>
      doSteps.isNotEmpty ? doSteps : splitIntoSteps(whatToDo);

  List<String> get effectiveAvoidSteps =>
      avoidSteps.isNotEmpty ? avoidSteps : splitIntoSteps(whatToAvoid);

  /// Splits a prose blob into displayable steps.
  ///
  /// Used for the on-device guidelines, which were authored as one or two
  /// sentences per field. Splitting on sentence ends is crude but reliable for
  /// that content, and far better than rendering a paragraph: the seeded
  /// guidelines really are lists of actions written as sentences
  /// ("Prune affected leaves. Spray copper fungicide.").
  ///
  /// Abbreviations are not a concern here — this content contains none, and a
  /// wrong split costs a slightly odd line break, not meaning.
  static List<String> splitIntoSteps(String prose) {
    if (prose.trim().isEmpty) return const [];

    final parts = prose
        .split(RegExp(r'(?<=[.!?])\s+'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    return parts.isEmpty ? [prose.trim()] : parts;
  }

  factory TreatmentResponse.fromJson(Map<String, dynamic> json) {
    List<String> steps(String key) {
      final raw = json[key];
      if (raw is! List) return const [];
      return raw
          .map((e) => e.toString().trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }

    return TreatmentResponse(
      summary: json['summary'] as String? ?? '',
      whatToDo: json['what_to_do'] as String? ?? '',
      whatToAvoid: json['what_to_avoid'] as String? ?? '',
      doSteps: steps('what_to_do_steps'),
      avoidSteps: steps('what_to_avoid_steps'),
      recheckAfterDays: json['recheck_after_days'] as int?,
      interpretationId: json['interpretation_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'what_to_do': whatToDo,
      'what_to_avoid': whatToAvoid,
      'what_to_do_steps': doSteps,
      'what_to_avoid_steps': avoidSteps,
      'recheck_after_days': recheckAfterDays,
      'interpretation_id': interpretationId,
    };
  }
}
