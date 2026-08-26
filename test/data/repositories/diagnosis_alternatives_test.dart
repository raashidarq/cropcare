// Alternatives written before the id fix hold the model's raw class index as
// a string, not a disease id. They rendered to the farmer as a bare number
// under "Not what you see?", which is meaningless.
//
// The repair happens on read, so existing scans fix themselves without a
// migration and without the user having to rescan.

import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/local/ml/ml_inference_service.dart';
import 'package:cropcare/data/repositories/diagnosis_repository_impl.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';

void main() {
  late AppDatabase db;
  late DiagnosisRepositoryImpl repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    await db.customSelect('SELECT 1').get();
    repo = DiagnosisRepositoryImpl(db);
  });

  tearDown(() async => db.close());

  /// Writes a diagnosis row with a hand-built alternatives payload, bypassing
  /// the entity so legacy shapes can be reproduced.
  Future<void> seedWithAlternatives(String alternativesJson) async {
    await db.customStatement(
      "INSERT INTO scan (id, user_id, crop_id, image_local_path, status, "
      "captured_at, created_at, updated_at) VALUES "
      "('scan-1', 'user-1', 'tomato', '/x.jpg', 'DIAGNOSED', "
      "'2026-08-24T12:00:00Z', '2026-08-24T12:00:00Z', '2026-08-24T12:00:00Z')",
    );
    await db.customStatement(
      "INSERT INTO diagnosis (id, scan_id, disease_id, model_version_id, "
      "confidence, result_state, alternatives_json, treatment_source, "
      "inferred_at) VALUES ('diag-1', 'scan-1', 'tomato_early_blight', 'v1', "
      "0.7, 'CONFIDENT', ?, 'LOCAL_FALLBACK', '2026-08-24T12:00:00Z')",
      [alternativesJson],
    );
  }

  test('a stored class index is mapped back to a real disease id', () async {
    // Whatever class 0 is, that is what should come back — not "0".
    final expected = MlInferenceService.diseaseIdAt(0);
    expect(expected, isNotNull, reason: 'class 0 should map to a disease');

    await seedWithAlternatives(jsonEncode([
      {'disease_id': '0', 'confidence': 0.2},
    ]));

    final diagnosis = await repo.getDiagnosisByScanId('scan-1');
    expect(diagnosis!.alternatives.single.diseaseId, expected);
  });

  test('a real disease id is left alone', () async {
    await seedWithAlternatives(jsonEncode([
      {'disease_id': 'tomato_late_blight', 'confidence': 0.2},
    ]));

    final diagnosis = await repo.getDiagnosisByScanId('scan-1');
    expect(diagnosis!.alternatives.single.diseaseId, 'tomato_late_blight');
  });

  test('an index with no disease row is dropped, never shown as a number',
      () async {
    // 9999 is not a class the model has, so nothing can be rendered for it.
    await seedWithAlternatives(jsonEncode([
      {'disease_id': '9999', 'confidence': 0.2},
      {'disease_id': 'tomato_late_blight', 'confidence': 0.1},
    ]));

    final diagnosis = await repo.getDiagnosisByScanId('scan-1');
    expect(diagnosis!.alternatives, hasLength(1));
    expect(diagnosis.alternatives.single.diseaseId, 'tomato_late_blight');
  });

  test('confidences survive the repair', () async {
    await seedWithAlternatives(jsonEncode([
      {'disease_id': '0', 'confidence': 0.23},
    ]));

    final diagnosis = await repo.getDiagnosisByScanId('scan-1');
    expect(diagnosis!.alternatives.single.confidence, closeTo(0.23, 0.0001));
  });

  test('an empty alternatives list stays empty', () async {
    await seedWithAlternatives(jsonEncode(<Map<String, Object?>>[]));

    final diagnosis = await repo.getDiagnosisByScanId('scan-1');
    expect(diagnosis!.alternatives, isEmpty);
  });

  test('a round trip through the entity keeps real ids', () async {
    const diagnosis = Diagnosis(
      id: 'diag-2',
      scanId: 'scan-2',
      diseaseId: 'tomato_early_blight',
      modelVersionId: 'v1',
      confidence: 0.7,
      resultState: DiagnosisResultState.confident,
      treatmentSource: TreatmentSource.localFallback,
      inferredAt: '2026-08-24T12:00:00Z',
      alternatives: [
        AlternativePrediction(
          diseaseId: 'tomato_late_blight',
          confidence: 0.2,
        ),
      ],
    );

    await db.customStatement(
      "INSERT INTO scan (id, user_id, crop_id, image_local_path, status, "
      "captured_at, created_at, updated_at) VALUES "
      "('scan-2', 'user-1', 'tomato', '/x.jpg', 'DIAGNOSED', "
      "'2026-08-24T12:00:00Z', '2026-08-24T12:00:00Z', '2026-08-24T12:00:00Z')",
    );
    await repo.createDiagnosis(diagnosis);

    final read = await repo.getDiagnosisByScanId('scan-2');
    expect(read!.alternatives.single.diseaseId, 'tomato_late_blight');
  });
}
