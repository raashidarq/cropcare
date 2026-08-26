// Every disease the model can name must have on-device guidance.
//
// This is the offline-first promise at its sharpest. A farmer standing in a
// paddy field with no signal gets a diagnosis from the on-device model; if
// there is no on-device guideline behind it, the app names their problem and
// then has nothing to say. That is arguably worse than not diagnosing it.
//
// The failure mode is silent: adding a class to ml/taxonomy.py and retraining
// produces a model that predicts a disease the seeder has never heard of, and
// nothing complains until someone is standing in a field.

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/repositories/crop_repository_impl.dart';
import 'package:cropcare/data/repositories/disease_repository_impl.dart';
import 'package:cropcare/data/repositories/treatment_repository_impl.dart';
import 'package:cropcare/data/remote/treatment_api_client.dart';

/// The non-healthy classes in ml/taxonomy.py. Kept in sync by hand: the
/// notebook generates the Dart seed rows, and this list is what proves they
/// were actually pasted in.
const _classesNeedingGuidance = <String>[
  // rice
  'paddy_bacterial_leaf_blight',
  'paddy_bacterial_leaf_streak',
  'paddy_bacterial_panicle_blight',
  'paddy_blast',
  'paddy_brown_spot',
  'paddy_downy_mildew',
  'paddy_tungro',
  'paddy_dead_heart',
  'paddy_hispa',
  // tomato
  'tomato_bacterial_spot',
  'tomato_early_blight',
  'tomato_late_blight',
  'tomato_leaf_mold',
  'tomato_septoria_leaf_spot',
  'tomato_target_spot',
  'tomato_yellow_leaf_curl_virus',
  'tomato_mosaic_virus',
  'tomato_spider_mites',
  // chili
  'chili_bacterial_spot',
  // potato
  'potato_early_blight',
  'potato_late_blight',
  // cassava
  'cassava_bacterial_blight',
  'cassava_brown_streak',
  'cassava_green_mottle',
  'cassava_mosaic',
  // maize
  'corn_gray_leaf_spot',
  'corn_common_rust',
  'corn_northern_leaf_blight',
];

void main() {
  late AppDatabase db;
  late TreatmentRepositoryImpl treatment;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Crops first: disease.crop_id is a foreign key.
    await CropRepositoryImpl(db).seedCrops();
    await DiseaseRepositoryImpl(db).seedDiseasesIfEmpty();
    treatment = TreatmentRepositoryImpl(
      apiClient: TreatmentApiClient(),
      db: db,
    );
  });

  tearDown(() async => db.close());

  test('every diagnosable disease has on-device guidance in English',
      () async {
    final missing = <String>[];
    for (final id in _classesNeedingGuidance) {
      final g = await treatment.getLocalTreatmentGuidance(
        diseaseId: id,
        languageCode: 'en',
      );
      if (g == null) missing.add(id);
    }
    expect(
      missing,
      isEmpty,
      reason: 'No offline guidance for: ${missing.join(', ')}. A farmer with '
          'no signal would get a diagnosis and nothing to do about it.',
    );
  });

  test('guidance is present in Sinhala and Tamil too', () async {
    for (final lang in ['si', 'ta']) {
      final missing = <String>[];
      for (final id in _classesNeedingGuidance) {
        final g = await treatment.getLocalTreatmentGuidance(
          diseaseId: id,
          languageCode: lang,
        );
        // A null result means no row at all. A row that fell back to English
        // per-field is caught by the next test.
        if (g == null) missing.add(id);
      }
      expect(missing, isEmpty, reason: 'No "$lang" guidance for: $missing');
    }
  });

  test('Sinhala and Tamil guidance is actually translated, not English', () async {
    final untranslated = <String>[];
    for (final id in _classesNeedingGuidance) {
      final en = await treatment.getLocalTreatmentGuidance(
        diseaseId: id, languageCode: 'en');
      for (final lang in ['si', 'ta']) {
        final other = await treatment.getLocalTreatmentGuidance(
          diseaseId: id, languageCode: lang);
        // Per-field English fallback is by design for partial translations,
        // but a whole entry identical to English means it was never done.
        if (other!.whatToDo == en!.whatToDo) untranslated.add('$id/$lang');
      }
    }
    expect(untranslated, isEmpty,
        reason: 'Falls back to English: ${untranslated.join(', ')}');
  });

  test('guidance splits into short, usable steps', () async {
    final problems = <String>[];
    for (final id in _classesNeedingGuidance) {
      final g = await treatment.getLocalTreatmentGuidance(
        diseaseId: id,
        languageCode: 'en',
      );
      final steps = g!.effectiveDoSteps;

      // One step means a farmer is reading a paragraph, which is the thing
      // the redesigned result screen exists to stop.
      if (steps.length < 2) {
        problems.add('$id: only ${steps.length} step(s)');
      }
      for (final step in steps) {
        final words = step.split(RegExp(r'\s+')).length;
        if (words > 18) problems.add('$id: step of $words words: "$step"');
      }
    }
    expect(problems, isEmpty, reason: problems.join('\n'));
  });

  test('the guidance says what to avoid, not just what to do', () async {
    final missing = <String>[];
    for (final id in _classesNeedingGuidance) {
      final g = await treatment.getLocalTreatmentGuidance(
        diseaseId: id,
        languageCode: 'en',
      );
      if (g!.effectiveAvoidSteps.isEmpty) missing.add(id);
    }
    expect(missing, isEmpty, reason: 'No "what to avoid" for: $missing');
  });

  test('a disease with no guideline row returns null rather than a blank card',
      () async {
    final g = await treatment.getLocalTreatmentGuidance(
      diseaseId: 'not_a_real_disease',
      languageCode: 'en',
    );
    expect(g, isNull);
  });
}
