import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/remote/treatment_api_client.dart';
import 'package:cropcare/data/repositories/crop_repository_impl.dart';
import 'package:cropcare/data/repositories/disease_repository_impl.dart';
import 'package:cropcare/data/repositories/treatment_repository_impl.dart';
import 'package:cropcare/domain/entities/treatment.dart';

class _FailingTreatmentApiClient extends TreatmentApiClient {
  @override
  Future<TreatmentResponse> fetchTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  }) async {
    throw Exception('Connection failed');
  }
}

class _SuccessTreatmentApiClient extends TreatmentApiClient {
  @override
  Future<TreatmentResponse> fetchTreatmentGuidance({
    required String cropId,
    required String diseaseId,
    required double confidence,
    required String? severity,
    required String languageCode,
    String? userObservations,
    String? authToken,
  }) async {
    return const TreatmentResponse(
      summary: 'Remote AI summary',
      whatToDo: 'Remote AI what to do',
      whatToAvoid: 'Remote AI what to avoid',
      recheckAfterDays: 3,
      interpretationId: 'ai-interp-999',
    );
  }
}

void main() {
  late AppDatabase db;
  late CropRepositoryImpl cropRepo;
  late DiseaseRepositoryImpl diseaseRepo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    cropRepo = CropRepositoryImpl(db);
    diseaseRepo = DiseaseRepositoryImpl(db);

    // Seed reference data
    await cropRepo.seedCrops();
    await diseaseRepo.seedDiseasesIfEmpty();
  });

  tearDown(() async {
    await db.close();
  });

  group('TreatmentRepositoryImpl', () {
    test('returns remote AI response when apiClient succeeds', () async {
      final repo = TreatmentRepositoryImpl(
        apiClient: _SuccessTreatmentApiClient(),
        db: db,
      );

      final response = await repo.getTreatmentGuidance(
        cropId: 'tomato',
        diseaseId: 'tomato_early_blight',
        confidence: 0.92,
        severity: 'moderate',
        languageCode: 'en',
      );

      expect(response.interpretationId, equals('ai-interp-999'));
      expect(response.summary, equals('Remote AI summary'));
    });

    test('falls back to local SQLite guideline for Apple diseases when offline', () async {
      final repo = TreatmentRepositoryImpl(
        apiClient: _FailingTreatmentApiClient(),
        db: db,
      );

      final response = await repo.getTreatmentGuidance(
        cropId: 'apple',
        diseaseId: 'apple_scab',
        confidence: 0.88,
        severity: 'moderate',
        languageCode: 'en',
      );

      expect(response.interpretationId, isNull);
      expect(response.summary, contains('spots on leaves'));
      expect(response.whatToDo, contains('Captan'));
      expect(response.recheckAfterDays, equals(7));
    });

    test('falls back to local SQLite guideline for Corn diseases in Sinhala when offline', () async {
      final repo = TreatmentRepositoryImpl(
        apiClient: _FailingTreatmentApiClient(),
        db: db,
      );

      final response = await repo.getTreatmentGuidance(
        cropId: 'corn',
        diseaseId: 'corn_gray_leaf_spot',
        confidence: 0.85,
        severity: 'moderate',
        languageCode: 'si',
      );

      expect(response.interpretationId, isNull);
      expect(response.summary, contains('ඉරිඟු කොළ'));
      expect(response.whatToDo, isNotEmpty);
      expect(response.whatToAvoid, isNotEmpty);
    });

    test('falls back to local SQLite guideline for Grape, Citrus, Potato, Squash, Strawberry, and Paddy', () async {
      final repo = TreatmentRepositoryImpl(
        apiClient: _FailingTreatmentApiClient(),
        db: db,
      );

      final diseasesToTest = [
        ('grape', 'grape_black_rot'),
        ('orange', 'orange_citrus_greening'),
        ('potato', 'potato_late_blight'),
        ('squash', 'squash_powdery_mildew'),
        ('strawberry', 'strawberry_leaf_scorch'),
        ('paddy', 'paddy_blast'),
      ];

      for (final (cropId, diseaseId) in diseasesToTest) {
        final response = await repo.getTreatmentGuidance(
          cropId: cropId,
          diseaseId: diseaseId,
          confidence: 0.90,
          severity: 'high',
          languageCode: 'ta',
        );

        expect(response.interpretationId, isNull);
        expect(response.summary, isNotEmpty, reason: 'Summary should not be empty for $diseaseId in Tamil');
        expect(response.whatToDo, isNotEmpty, reason: 'WhatToDo should not be empty for $diseaseId in Tamil');
        expect(response.whatToAvoid, isNotEmpty, reason: 'WhatToAvoid should not be empty for $diseaseId in Tamil');
      }
    });
  });
}
