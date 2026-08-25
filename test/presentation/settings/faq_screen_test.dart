import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cropcare/presentation/settings/faq_screen.dart';

void main() {
  testWidgets('FaqScreen renders title, categories, and expandable items', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: FaqScreen(),
      ),
    );

    // Verify app bar title
    expect(find.text('Frequently Asked Questions'), findsWidgets);

    // Verify categories
    expect(find.text('Scanning & Diagnosis'), findsOneWidget);
    expect(find.text('Account & Cloud Sync'), findsOneWidget);

    // Verify question is visible
    expect(find.text('How does crop disease detection work?'), findsOneWidget);

    // Tap to expand first FAQ item
    await tester.tap(find.text('How does crop disease detection work?'));
    await tester.pumpAndSettle();

    // Verify answer is revealed
    expect(
      find.textContaining('CropCare uses on-device AI models'),
      findsOneWidget,
    );
  });
}
