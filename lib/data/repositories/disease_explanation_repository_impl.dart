// lib/data/repositories/disease_explanation_repository_impl.dart
//
// Reads offline explanation content from SQLite and resolves it to one
// language. Purely local — this content ships with the app / arrives via
// reference-data sync, and is never fetched per-request.

import 'package:drift/drift.dart';

import '../../domain/entities/disease_explanation.dart';
import '../../domain/repositories/disease_explanation_repository.dart';
import '../local/database/app_database.dart';

class DiseaseExplanationRepositoryImpl implements DiseaseExplanationRepository {
  final AppDatabase db;

  DiseaseExplanationRepositoryImpl(this.db);

  @override
  Future<DiseaseExplanation?> getExplanation({
    required String diseaseId,
    required String languageCode,
  }) async {
    final row = await (db.select(db.diseaseExplanationTable)
          ..where((t) => t.diseaseId.equals(diseaseId))
          ..limit(1))
        .getSingleOrNull();

    final confusionRows = await (db.select(db.diseaseConfusionTable)
          ..where((t) => t.diseaseId.equals(diseaseId))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();

    // No explanation row AND no look-alikes: the device genuinely has
    // nothing for this disease.
    if (row == null && confusionRows.isEmpty) return null;

    // Resolve each look-alike's display name. Prefer the label columns; fall
    // back to the referenced disease's own name so an entry that only sets
    // confused_with_disease_id still renders something useful.
    final confusions = <DiseaseConfusion>[];
    for (final c in confusionRows) {
      var label = _pick(
        languageCode,
        en: c.confusedWithLabelEn,
        si: c.confusedWithLabelSi,
        ta: c.confusedWithLabelTa,
      );

      if ((label == null || label.trim().isEmpty) &&
          c.confusedWithDiseaseId != null) {
        final disease = await (db.select(db.diseaseTable)
              ..where((t) => t.id.equals(c.confusedWithDiseaseId!)))
            .getSingleOrNull();
        if (disease != null) {
          label = _pick(
            languageCode,
            en: disease.nameEn,
            si: disease.nameSi,
            ta: disease.nameTa,
          );
        }
      }

      confusions.add(DiseaseConfusion(
        label: label,
        distinguishingSymptoms: _pick(
          languageCode,
          en: c.distinguishingSymptomsEn,
          si: c.distinguishingSymptomsSi,
          ta: c.distinguishingSymptomsTa,
        ),
        confusedWithDiseaseId: c.confusedWithDiseaseId,
      ));
    }

    return DiseaseExplanation(
      diseaseId: diseaseId,
      plantDescription: _pick(
        languageCode,
        en: row?.plantDescriptionEn,
        si: row?.plantDescriptionSi,
        ta: row?.plantDescriptionTa,
      ),
      resultMeaning: _pick(
        languageCode,
        en: row?.resultMeaningEn,
        si: row?.resultMeaningSi,
        ta: row?.resultMeaningTa,
      ),
      confusions: confusions,
      explanationVersion: row?.explanationVersion,
    );
  }

  /// Picks the column for [languageCode], falling back to English when that
  /// language's text is missing or blank. Per-field rather than per-row, so a
  /// partially translated explanation shows translated text where it exists
  /// instead of dropping to English wholesale.
  String? _pick(
    String languageCode, {
    required String? en,
    required String? si,
    required String? ta,
  }) {
    String? preferred;
    switch (languageCode) {
      case 'si':
        preferred = si;
        break;
      case 'ta':
        preferred = ta;
        break;
      default:
        preferred = en;
    }
    if (preferred != null && preferred.trim().isNotEmpty) return preferred;
    if (en != null && en.trim().isNotEmpty) return en;
    return null;
  }
}
