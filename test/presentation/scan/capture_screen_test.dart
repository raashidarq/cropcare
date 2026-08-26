import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:cropcare/application/scan/scan_cubit.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/entities/scan.dart';
import 'package:cropcare/domain/entities/scan_history_item.dart';
import 'package:cropcare/domain/repositories/scan_repository.dart';
import 'package:cropcare/domain/usecases/scan/capture_scan_use_case.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:camera/camera.dart';
import 'package:cropcare/presentation/scan/capture_screen.dart';
import 'package:cropcare/services/camera_service.dart';

class FakeCameraPermissionService implements CameraPermissionService {
  final PermissionStatus status;

  FakeCameraPermissionService({required this.status});

  @override
  Future<PermissionStatus> checkPermission() async => status;

  @override
  Future<PermissionStatus> requestPermission() async => status;

  @override
  Future<bool> openAppSettings() async => true;
}

class FakeScanRepository implements ScanRepository {
  @override
  Future<Scan> createScan({
    required String cropId,
    required String imageLocalPath,
    required String userId,
  }) async {
    final now = DateTime.now();
    return Scan(
      id: 'test-scan-id',
      userId: userId,
      cropId: cropId,
      imageLocalPath: imageLocalPath,
      status: ScanStatus.created,
      capturedAt: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  @override
  Future<Scan?> getScanById(String id) async => null;

  @override
  Future<void> updateScanStatus(String scanId, ScanStatus status) async {}

  @override
  Future<void> updateScanCrop(String scanId, String cropId) async {}

  @override
  Future<void> rejectInvalidScan({
    required String scanId,
    required String rejectionReason,
  }) async {}

  @override
  Future<int> purgeFailedScans() async => 0;

  @override
  Future<List<ScanHistoryItem>> getScanHistory() async => [];

  @override
  Future<void> deleteAllLocalScans() async {}
}

/// Stands in for a device with no usable camera — a tablet, an emulator, or
/// a test host with no platform channel. Exercises the gallery-fallback path
/// without needing camera hardware.
class _NoCameraService implements CameraService {
  @override
  Future<List<CameraDescription>> availableCameras() async => const [];

  @override
  CameraController createController(
    CameraDescription description, {
    ResolutionPreset resolution = ResolutionPreset.high,
  }) {
    throw UnimplementedError('no camera in this test');
  }
}

void main() {
  testWidgets(
      'CaptureScreen displays explanation UI when permission is denied and does not crash or show preview',
      (WidgetTester tester) async {
    final fakePermissionService = FakeCameraPermissionService(
      status: PermissionStatus.denied,
    );
    final fakeScanRepo = FakeScanRepository();
    final captureScanUseCase = CaptureScanUseCase(fakeScanRepo);

    final scanCubit = ScanCubit(
      captureScanUseCase: captureScanUseCase,
      permissionService: fakePermissionService,
    );

    final user = LocalUser(
      id: 'guest-123',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LocalizationProvider(
          languageCode: 'en',
          child: CaptureScreen(
            cropId: 'tomato',
            user: user,
            scanCubit: scanCubit,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify explanation UI, gallery fallback button, and back to home button
    expect(find.byKey(const Key('camera_permission_denied_view')), findsOneWidget);
    expect(find.byKey(const Key('open_app_settings_button')), findsOneWidget);
    expect(find.byKey(const Key('gallery_pick_fallback_button')), findsOneWidget);
    expect(find.byKey(const Key('cancel_scan_permission_button')), findsOneWidget);
    expect(find.byKey(const Key('cancel_scan_button')), findsOneWidget);

    // Confirm camera ready view and capture button are NOT rendered
    expect(find.byKey(const Key('camera_ready_view')), findsNothing);
    expect(find.byKey(const Key('capture_button')), findsNothing);
  });

  testWidgets('CaptureScreen shows the viewfinder shell and a gallery fallback when the device has no camera', (WidgetTester tester) async {
    final fakePermissionService = FakeCameraPermissionService(
      status: PermissionStatus.granted,
    );
    final fakeScanRepo = FakeScanRepository();
    final captureScanUseCase = CaptureScanUseCase(fakeScanRepo);

    final scanCubit = ScanCubit(
      captureScanUseCase: captureScanUseCase,
      permissionService: fakePermissionService,
    );

    final user = LocalUser(
      id: 'guest-123',
      isGuest: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LocalizationProvider(
          languageCode: 'en',
          child: CaptureScreen(
            cropId: 'tomato',
            user: user,
            scanCubit: scanCubit,
            cameraService: _NoCameraService(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const Key('cancel_scan_button')), findsOneWidget);
    expect(find.byKey(const Key('camera_ready_view')), findsOneWidget);
    // The shutter and gallery controls still render; the shutter is disabled
    // until the preview reports itself live.
    expect(find.byKey(const Key('capture_button')), findsOneWidget);
    expect(find.byKey(const Key('gallery_pick_button')), findsOneWidget);
    // A device with no camera must still offer a way through, rather than
    // silently doing nothing as the old screen did.
    expect(
      find.byKey(const Key('camera_unavailable_gallery_button')),
      findsOneWidget,
    );
  });
}
