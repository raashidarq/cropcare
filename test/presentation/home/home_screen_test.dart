import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/crop.dart';
import 'package:cropcare/domain/entities/diagnosis.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/crop_repository.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/crop/get_supported_crops_use_case.dart';
import 'package:cropcare/domain/usecases/history/get_scan_history_use_case.dart';
import 'package:cropcare/presentation/home/home_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';

class _FakeCropRepository implements CropRepository {
  @override
  Future<List<Crop>> getSupportedCrops() async => [
        const Crop(id: 'tomato', nameEn: 'Tomato', nameSi: 'තක්කාලි', nameTa: 'தக்காளி'),
      ];
}

class _FakeScanRepository implements ScanRepository {
  List<ScanHistoryItem> history = [];

  @override
  Future<Scan> createScan({required String cropId, required String imageLocalPath, required String userId}) async {
    throw UnimplementedError();
  }

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {}

  @override
  Future<void> updateScanCrop(String scanId, String cropId) async {}

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => history;

  @override
  Future<void> deleteAllLocalScans() async {}
}

void main() {
  testWidgets('HomeScreen displays scan button, smart account action in appbar, and embedded history', (tester) async {
    final user = LocalUser(
      id: 'user-guest-12345',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final fakeScanRepo = _FakeScanRepository()
      ..history = [
        ScanHistoryItem(
          scan: Scan(
            id: 'scan-hist-1',
            userId: 'user-guest-12345',
            cropId: 'tomato',
            imageLocalPath: '/fake/leaf1.jpg',
            status: ScanStatus.diagnosed,
            capturedAt: DateTime.now(),
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          diagnosis: const Diagnosis(
            id: 'diag-hist-1',
            scanId: 'scan-hist-1',
            diseaseId: 'tomato_early_blight',
            modelVersionId: 'v1',
            confidence: 0.88,
            resultState: DiagnosisResultState.confident,
            treatmentSource: TreatmentSource.llm,
            inferredAt: '2026-08-24T12:00:00Z',
          ),
          crop: const Crop(id: 'tomato', nameEn: 'Tomato', nameSi: 'තක්කාලි', nameTa: 'தக்காளி'),
        )
      ];

    final getCropsUseCase = GetSupportedCropsUseCase(_FakeCropRepository());
    final getHistoryUseCase = GetScanHistoryUseCase(fakeScanRepo);

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: HomeScreen(
            user: user,
            getSupportedCropsUseCase: getCropsUseCase,
            getScanHistoryUseCase: getHistoryUseCase,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 1. Scan Hero Button exists
    expect(find.byKey(const Key('home_start_scan_button')), findsOneWidget);

    // 2. Smart Account Icon exists on AppBar
    expect(find.byKey(const Key('home_account_icon')), findsOneWidget);

    // 3. Hero card displays clean welcome and subtitle
    expect(find.text('Welcome to CropCare!'), findsOneWidget);
    expect(find.text('Detect crop diseases and get treatment advice instantly.'), findsOneWidget);
    expect(find.byKey(const Key('home_link_account_button')), findsNothing);

    // 4. Scan History section is present with history item, Export button, filter dropdown, and scan count
    expect(find.text('Scan History'), findsOneWidget);
    expect(find.byKey(const Key('home_export_history_icon')), findsOneWidget);
    expect(find.text('Export'), findsOneWidget);
    expect(find.byKey(const Key('home_history_filter_dropdown')), findsOneWidget);
    expect(find.byKey(const Key('home_history_scan_count_badge')), findsOneWidget);
    expect(find.text('1 scans'), findsOneWidget);
    expect(find.byKey(const Key('history_card_scan-hist-1')), findsOneWidget);
    expect(find.text('Tomato Early Blight'), findsOneWidget);
    expect(find.text('88%'), findsOneWidget);
  });
}
