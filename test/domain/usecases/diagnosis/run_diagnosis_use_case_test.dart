import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/database/app_database.dart';
import 'package:cropcare/data/local/ml/ml_inference_service.dart';
import 'package:cropcare/data/repositories/crop_repository_impl.dart';
import 'package:cropcare/data/repositories/diagnosis_repository_impl.dart';
import 'package:cropcare/data/repositories/disease_repository_impl.dart';
import 'package:cropcare/data/repositories/scan_repository_impl.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/usecases/diagnosis/run_diagnosis_use_case.dart';
import 'package:cropcare/domain/usecases/diagnosis/validate_image_use_case.dart';

/// A stand-in [MlInferenceService] that returns a canned [InferenceResult]
/// (or throws) instead of running a real TFLite interpreter — `runInference`
/// is a normal overridable instance method, so no DI refactor is needed to
/// make this class testable.
class _FakeMlInferenceService extends MlInferenceService {
  final InferenceResult? resultToReturn;
  final Object? exceptionToThrow;
  int callCount = 0;

  _FakeMlInferenceService({this.resultToReturn, this.exceptionToThrow});

  @override
  Future<InferenceResult> runInference(String imageLocalPath) async {
    callCount++;
    if (exceptionToThrow != null) throw exceptionToThrow!;
    return resultToReturn!;
  }
}

void main() {
  late AppDatabase db;
  late ScanRepositoryImpl scanRepository;
  late DiagnosisRepositoryImpl diagnosisRepository;
  late String seededScanId;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    final cropRepo = CropRepositoryImpl(db);
    await cropRepo.seedCrops();
    await DiseaseRepositoryImpl(db).seedDiseasesIfEmpty();

    scanRepository = ScanRepositoryImpl(db);
    diagnosisRepository = DiagnosisRepositoryImpl(db);

    final scan = await scanRepository.createScan(
      cropId: 'tomato',
      imageLocalPath: '/fake/path/leaf.jpg',
      userId: 'test-user',
    );
    seededScanId = scan.id;
  });

  /// Pending SCAN outbox rows for the seeded scan.
  Future<List<SyncOperationTableData>> scanSyncOps() async {
    final rows = await (db.select(db.syncOperationTable)
          ..where((t) => t.entityId.equals(seededScanId)))
        .get();
    return rows.where((r) => r.entityType == 'SCAN').toList();
  }

  RunDiagnosisUseCase useCaseWith(MlInferenceService service) {
    return RunDiagnosisUseCase(
      inferenceService: service,
      diagnosisRepository: diagnosisRepository,
      scanRepository: scanRepository,
      db: db,
    );
  }

  group('RunDiagnosisUseCase — result-state branches', () {
    test('confident: high confidence + low entropy → confident, severity populated', () async {
      // Grab a real seeded disease that has a non-null severityDefault so we
      // can assert the severity-inheritance fix end-to-end.
      final diseaseWithSeverity = await (db.select(db.diseaseTable)
            ..where((t) => t.severityDefault.isNotNull())
            ..limit(1))
          .getSingle();

      final useCase = useCaseWith(_FakeMlInferenceService(
        resultToReturn: InferenceResult(
          topClassIndex: 0,
          confidence: 0.95,
          diseaseId: diseaseWithSeverity.id,
          isSupported: true,
          topFive: [(0, 0.95), (1, 0.02)],
          entropy: 0.05,
        ),
      ));

      final diagnosis = await useCase(
        scanId: seededScanId,
        imageLocalPath: '/fake/path/leaf.jpg',
        validationResult: const ImageValidationResult.valid(),
      );

      expect(diagnosis.resultState, DiagnosisResultState.confident);
      expect(diagnosis.diseaseId, diseaseWithSeverity.id);
      expect(diagnosis.severity, diseaseWithSeverity.severityDefault);
    });

    test('lowConfidence: confidence below threshold → lowConfidence', () async {
      final useCase = useCaseWith(_FakeMlInferenceService(
        resultToReturn: const InferenceResult(
          topClassIndex: 0,
          confidence: 0.40,
          diseaseId: 'tomato_healthy',
          isSupported: true,
          topFive: [(0, 0.40), (1, 0.30)],
          entropy: 0.05,
        ),
      ));

      final diagnosis = await useCase(
        scanId: seededScanId,
        imageLocalPath: '/fake/path/leaf.jpg',
        validationResult: const ImageValidationResult.valid(),
      );

      expect(diagnosis.resultState, DiagnosisResultState.lowConfidence);
    });

    test(
      'entropy downgrade: confidence clears the threshold but the distribution '
      'is too flat → downgraded to lowConfidence, NOT confident',
      () async {
        // NOTE on the numbers: entropy is tightly coupled to max-softmax, so
        // the two fields cannot be set independently. This pair is physically
        // realizable: p_max = 0.72 with the remainder spread ~uniformly over
        // the other 33 classes gives normalized entropy in this region.
        //
        // Updated with the field model: the class count went 38 -> 34, so
        // index 37 no longer exists, and confidenceThreshold went 0.60 ->
        // 0.70, so the old 0.62 no longer clears it.
        //
        // This also bounds what the entropy gate can do: at a high enough
        // p_max even a maximally-flat tail stays under the threshold, so this
        // check only bites in a narrow band just above confidenceThreshold.
        // It is cheap defense-in-depth, NOT the fix for the reported
        // desk-photo bug (that was 98% confident, i.e. normalized entropy
        // <= ~0.05 — no entropy threshold could have rejected it). The real
        // OOD defense is ValidateImageUseCase's content gate.
        final useCase = useCaseWith(_FakeMlInferenceService(
          resultToReturn: const InferenceResult(
            topClassIndex: 19,
            confidence: 0.72, // clears confidenceThreshold (0.70)
            diseaseId: 'tomato_healthy',
            isSupported: true,
            topFive: [(19, 0.72), (0, 0.0085)],
            entropy: 0.56, // exceeds entropyThreshold (0.50)
          ),
        ));

        final diagnosis = await useCase(
          scanId: seededScanId,
          imageLocalPath: '/fake/path/leaf.jpg',
          validationResult: const ImageValidationResult.valid(),
        );

        expect(diagnosis.resultState, DiagnosisResultState.lowConfidence);
      },
    );

    test('unsupported: model reports an unsupported class → unsupported', () async {
      // Note: with all 38 classes currently mapped to a disease id (TD-006),
      // isSupported=false can't actually occur from a real model output
      // today — this exercises the branch as a safety net for a future
      // model version whose class map might not be fully populated. We
      // deliberately keep topClassIndex within the real 38-class range so
      // MlInferenceService.classNameAt (used downstream to derive a crop
      // id) doesn't throw on an out-of-range index.
      final useCase = useCaseWith(_FakeMlInferenceService(
        resultToReturn: const InferenceResult(
          topClassIndex: 0,
          confidence: 0.99,
          diseaseId: null,
          isSupported: false,
          topFive: [(0, 0.99)],
          entropy: 0.02,
        ),
      ));

      final diagnosis = await useCase(
        scanId: seededScanId,
        imageLocalPath: '/fake/path/leaf.jpg',
        validationResult: const ImageValidationResult.valid(),
      );

      expect(diagnosis.resultState, DiagnosisResultState.unsupported);
      expect(diagnosis.diseaseId, isNull);
    });

    test('analysisFailed: inference throws → analysisFailed, does not propagate', () async {
      final useCase = useCaseWith(_FakeMlInferenceService(
        exceptionToThrow: StateError('interpreter not loaded'),
      ));

      final diagnosis = await useCase(
        scanId: seededScanId,
        imageLocalPath: '/fake/path/leaf.jpg',
        validationResult: const ImageValidationResult.valid(),
      );

      expect(diagnosis.resultState, DiagnosisResultState.analysisFailed);
    });

    test(
      'analysisFailed: invalid image (failed ValidateImageUseCase) short-circuits '
      'without ever calling inference',
      () async {
        final fakeService = _FakeMlInferenceService(
          resultToReturn: const InferenceResult(
            topClassIndex: 0,
            confidence: 0.99,
            diseaseId: 'tomato_healthy',
            isSupported: true,
            topFive: [(0, 0.99)],
            entropy: 0.01,
          ),
        );
        final useCase = useCaseWith(fakeService);

        final diagnosis = await useCase(
          scanId: seededScanId,
          imageLocalPath: '/fake/path/desk.jpg',
          validationResult: const ImageValidationResult.invalid(
            ImageRejectionReason.noPlantDetected,
          ),
        );

        expect(diagnosis.resultState, DiagnosisResultState.analysisFailed);
        expect(fakeService.callCount, 0);

        // The image_validation row for this scan should record the reason.
        final validationRow = await (db.select(db.imageValidationTable)
              ..where((t) => t.scanId.equals(seededScanId)))
            .getSingle();
        expect(validationRow.isUsable, 0);
        expect(validationRow.rejectionReason, 'NO_PLANT_DETECTED');
      },
    );
  });

  group('RunDiagnosisUseCase.rejectInvalidImage — rejected-scan cleanup', () {
    test(
      'records the rejection, marks the scan INVALID_IMAGE, and cancels the '
      'queued cloud upload so a rejected photo is never synced',
      () async {
        // createScan() enqueues a SCAN upload op up front, before the image
        // has been validated — confirm that precondition holds.
        final queuedBefore = await scanSyncOps();
        expect(queuedBefore, hasLength(1));
        expect(queuedBefore.single.status, 'PENDING');

        final useCase = useCaseWith(_FakeMlInferenceService());
        await useCase.rejectInvalidImage(
          scanId: seededScanId,
          validationResult: const ImageValidationResult.invalid(
            ImageRejectionReason.noPlantDetected,
          ),
        );

        final validationRow = await (db.select(db.imageValidationTable)
              ..where((t) => t.scanId.equals(seededScanId)))
            .getSingle();
        expect(validationRow.isUsable, 0);
        expect(validationRow.rejectionReason, 'NO_PLANT_DETECTED');

        final scanRow = await (db.select(db.scanTable)
              ..where((t) => t.id.equals(seededScanId)))
            .getSingle();
        expect(scanRow.status, 'INVALID_IMAGE');

        expect(await scanSyncOps(), isEmpty);
      },
    );
  });
}
