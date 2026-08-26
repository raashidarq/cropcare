import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/presentation/settings/terms_privacy_screen.dart';

void main() {
  testWidgets('TermsPrivacyScreen displays Terms of Service and Privacy Policy tabs', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: TermsPrivacyScreen(),
      ),
    );

    // Verify TabBar
    expect(find.text('Terms of Service'), findsWidgets);
    expect(find.text('Privacy Policy'), findsWidgets);

    // Initial tab is Terms of Service
    expect(find.text('CropCare Terms of Service'), findsOneWidget);
    expect(find.textContaining('1. Purpose'), findsOneWidget);

    // Tap the Privacy Policy tab. The tabs are text-only now: an icon plus a
    // label squeezed "පෞද්ගලිකත්ව ප්‍රතිපත්තිය" and "தனியுரிமைக் கொள்கை" into
    // half the screen each, and the icons said nothing the words did not.
    await tester.tap(find.text('Privacy Policy').first);
    await tester.pumpAndSettle();

    // Verify Privacy Policy content
    expect(find.text('CropCare Privacy Policy'), findsOneWidget);
    expect(find.textContaining('1. Data Collection'), findsOneWidget);
  });
}
