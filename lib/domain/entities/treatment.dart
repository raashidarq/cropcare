// lib/domain/entities/treatment.dart
//
// Pure Dart domain entity for treatment guidance.

class TreatmentResponse {
  final String summary;
  final String whatToDo;
  final String whatToAvoid;
  final int? recheckAfterDays;
  final String? interpretationId;

  const TreatmentResponse({
    required this.summary,
    required this.whatToDo,
    required this.whatToAvoid,
    this.recheckAfterDays,
    this.interpretationId,
  });

  factory TreatmentResponse.fromJson(Map<String, dynamic> json) {
    return TreatmentResponse(
      summary: json['summary'] as String? ?? '',
      whatToDo: json['what_to_do'] as String? ?? '',
      whatToAvoid: json['what_to_avoid'] as String? ?? '',
      recheckAfterDays: json['recheck_after_days'] as int?,
      interpretationId: json['interpretation_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary': summary,
      'what_to_do': whatToDo,
      'what_to_avoid': whatToAvoid,
      'recheck_after_days': recheckAfterDays,
      'interpretation_id': interpretationId,
    };
  }
}
