import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image_picker/image_picker.dart';

import 'package:cropcare/domain/entities/crop.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/crop_repository.dart';
import 'package:cropcare/domain/usecases/crop/get_supported_crops_use_case.dart';
import 'package:cropcare/presentation/home/home_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/scan/add_photo_screen.dart';
import 'package:cropcare/presentation/scan/capture_screen.dart';

class _FakeCropRepository implements CropRepository {
  @override
  Future<List<Crop>> getSupportedCrops() async => [
        const Crop(id: 'tomato', nameEn: 'Tomato', nameSi: 'තක්කාලි', nameTa: 'தக்காளி'),
        const Crop(id: 'chili', nameEn: 'Chili', nameSi: 'මිරිස්', nameTa: 'මිளகாய்'),
        const Crop(id: 'potato', nameEn: 'Potato', nameSi: 'අර්තාපල්', nameTa: 'உருளைக்கிழங்கு'),
      ];
}

class _FailingImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    throw Exception('Permission denied');
  }
}

class _NullReturningImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    return null; // User cancelled
  }
}

void main() {
  final user = LocalUser(
    id: 'test-user-123',
    isGuest: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets('AddPhotoScreen renders Take Photo, Choose from Gallery, and informational supported crops', (tester) async {
    final getCropsUseCase = GetSupportedCropsUseCase(_FakeCropRepository());

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: AddPhotoScreen(
            user: user,
            getSupportedCropsUseCase: getCropsUseCase,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify title and actions
    expect(find.text('New Scan'), findsOneWidget);
    expect(find.byKey(const Key('add_photo_camera_button')), findsOneWidget);
    expect(find.byKey(const Key('add_photo_gallery_button')), findsOneWidget);

    // Verify informational supported crops section and non-tappable chips
    expect(find.text('Supported Crops'), findsOneWidget);
    expect(find.byKey(const Key('supported_crops_info_grid')), findsOneWidget);
    expect(find.byKey(const Key('supported_crop_chip_tomato')), findsOneWidget);
    expect(find.byKey(const Key('supported_crop_chip_chili')), findsOneWidget);
    expect(find.byKey(const Key('supported_crop_chip_potato')), findsOneWidget);
  });

  testWidgets(
    'HomeScreen scan action goes straight to the camera, not to a '
    'camera-or-gallery chooser screen',
    (tester) async {
      final getCropsUseCase = GetSupportedCropsUseCase(_FakeCropRepository());

      await tester.pumpWidget(
        LocalizationProvider(
          languageCode: 'en',
          child: MaterialApp(
            home: HomeScreen(
              user: user,
              getSupportedCropsUseCase: getCropsUseCase,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('home_start_scan_button')));
      // Bounded pumps, not pumpAndSettle: the viewfinder shows an
      // indeterminate progress indicator while it works out whether the
      // device has a camera, and pumpAndSettle never returns on one.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The intermediate AddPhotoScreen was removed from the scan path:
      // gallery is now a control inside the camera UI, so the common case
      // ("I am standing in front of a sick plant") costs one tap, not two.
      expect(find.byType(AddPhotoScreen), findsNothing);
      expect(find.byType(CaptureScreen), findsOneWidget);
      // Which state CaptureScreen lands in depends on the camera permission,
      // which the test host denies; the viewfinder's own controls are
      // asserted in capture_screen_test.dart. What matters here is only that
      // the chooser screen is no longer in the path.
    },
  );

  testWidgets('Gallery cancellation leaves AddPhotoScreen cleanly without crashing', (tester) async {
    final getCropsUseCase = GetSupportedCropsUseCase(_FakeCropRepository());
    final nullPicker = _NullReturningImagePicker();

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: AddPhotoScreen(
            user: user,
            getSupportedCropsUseCase: getCropsUseCase,
            imagePicker: nullPicker,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Choose from Gallery
    await tester.tap(find.byKey(const Key('add_photo_gallery_button')));
    await tester.pumpAndSettle();

    // Still cleanly on AddPhotoScreen
    expect(find.byType(AddPhotoScreen), findsOneWidget);
    expect(find.byKey(const Key('add_photo_gallery_button')), findsOneWidget);
  });

  testWidgets('Gallery permission denial shows explanation dialog with settings button', (tester) async {
    final getCropsUseCase = GetSupportedCropsUseCase(_FakeCropRepository());
    final failingPicker = _FailingImagePicker();

    await tester.pumpWidget(
      LocalizationProvider(
        languageCode: 'en',
        child: MaterialApp(
          home: AddPhotoScreen(
            user: user,
            getSupportedCropsUseCase: getCropsUseCase,
            imagePicker: failingPicker,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Choose from Gallery
    await tester.tap(find.byKey(const Key('add_photo_gallery_button')));
    await tester.pumpAndSettle();

    // Verify permission dialog is shown
    expect(find.byKey(const Key('gallery_permission_dialog')), findsOneWidget);
    expect(find.text('Gallery Permission Required'), findsOneWidget);
    expect(find.byKey(const Key('open_app_settings_dialog_button')), findsOneWidget);
  });
}
