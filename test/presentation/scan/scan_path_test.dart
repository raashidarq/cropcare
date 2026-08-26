import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/crop.dart';
import 'package:cropcare/domain/entities/local_user.dart';
import 'package:cropcare/domain/repositories/crop_repository.dart';
import 'package:cropcare/domain/usecases/crop/get_supported_crops_use_case.dart';
import 'package:cropcare/presentation/home/home_screen.dart';
import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/scan/capture_screen.dart';

class _FakeCropRepository implements CropRepository {
  @override
  Future<List<Crop>> getSupportedCrops() async => [
        const Crop(id: 'tomato', nameEn: 'Tomato', nameSi: 'තක්කාලි', nameTa: 'தக்காளி'),
        const Crop(id: 'chili', nameEn: 'Chili', nameSi: 'මිරිස්', nameTa: 'මිளகாய்'),
      ];
}

void main() {
  final user = LocalUser(
    id: 'test-user-123',
    isGuest: true,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  testWidgets(
    'Starting a scan opens the camera directly, with no chooser screen in between',
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

      // The intermediate camera-or-gallery chooser was removed from the scan
      // path (TD-015): gallery is now a control inside the camera UI, so the
      // common case ("I am standing in front of a sick plant") costs one tap,
      // not two. This asserts the shortcut has not regressed.
      expect(find.byType(CaptureScreen), findsOneWidget);
    },
  );
}
