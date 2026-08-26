// The guided walkthrough.
//
// The properties worth protecting are the ones that make it tolerable rather
// than the ones that make it work: it must be escapable at any point, and it
// must never point at a widget that is not on screen.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/presentation/onboarding/localization/localization_provider.dart';
import 'package:cropcare/presentation/shared/widgets/tutorial_overlay.dart';

void main() {
  late GlobalKey targetA;
  late GlobalKey targetB;
  late GlobalKey neverRendered;

  setUp(() {
    targetA = GlobalKey();
    targetB = GlobalKey();
    neverRendered = GlobalKey();
  });

  Widget host(void Function(BuildContext) onReady) {
    return LocalizationProvider(
      languageCode: 'en',
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                ElevatedButton(
                  key: targetA,
                  onPressed: () {},
                  child: const Text('Scan'),
                ),
                const Spacer(),
                ElevatedButton(
                  key: targetB,
                  onPressed: () {},
                  child: const Text('History'),
                ),
                TextButton(
                  onPressed: () => onReady(context),
                  child: const Text('start'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> start(WidgetTester tester, List<TutorialStep> steps) async {
    await tester.pumpWidget(host((ctx) => showTutorial(ctx, steps)));
    await tester.pumpAndSettle();
    await tester.tap(find.text('start'));
    await tester.pumpAndSettle();
  }

  testWidgets('walks through every step and finishes', (tester) async {
    await start(tester, [
      TutorialStep(
        targetKey: targetA,
        titleKey: 'tutorial_scan_title',
        bodyKey: 'tutorial_scan_body',
      ),
      TutorialStep(
        targetKey: targetB,
        titleKey: 'tutorial_nav_title',
        bodyKey: 'tutorial_nav_body',
      ),
    ]);

    expect(find.text('Start here'), findsOneWidget);

    await tester.tap(find.byKey(const Key('tutorial_next_button')));
    await tester.pumpAndSettle();
    expect(find.text('Your scans live here'), findsOneWidget);

    // Last step says "Got it", not "Next".
    expect(find.text('Got it'), findsOneWidget);
    await tester.tap(find.byKey(const Key('tutorial_next_button')));
    await tester.pumpAndSettle();

    expect(find.text('Your scans live here'), findsNothing);
  });

  testWidgets('can be skipped from the very first step', (tester) async {
    await start(tester, [
      TutorialStep(
        targetKey: targetA,
        titleKey: 'tutorial_scan_title',
        bodyKey: 'tutorial_scan_body',
      ),
      TutorialStep(
        targetKey: targetB,
        titleKey: 'tutorial_nav_title',
        bodyKey: 'tutorial_nav_body',
      ),
    ]);

    // A tutorial you cannot leave is a hostage situation.
    await tester.tap(find.byKey(const Key('tutorial_skip_button')));
    await tester.pumpAndSettle();
    expect(find.text('Start here'), findsNothing);
  });

  testWidgets('the last step offers no skip, because next ends it',
      (tester) async {
    await start(tester, [
      TutorialStep(
        targetKey: targetA,
        titleKey: 'tutorial_scan_title',
        bodyKey: 'tutorial_scan_body',
      ),
    ]);

    expect(find.byKey(const Key('tutorial_skip_button')), findsNothing);
    expect(find.text('Got it'), findsOneWidget);
  });

  testWidgets('steps whose target was never rendered are dropped',
      (tester) async {
    await start(tester, [
      TutorialStep(
        targetKey: neverRendered,
        titleKey: 'tutorial_scan_title',
        bodyKey: 'tutorial_scan_body',
      ),
      TutorialStep(
        targetKey: targetB,
        titleKey: 'tutorial_nav_title',
        bodyKey: 'tutorial_nav_body',
      ),
    ]);

    // Pointing a spotlight at empty space is worse than skipping the step.
    expect(find.text('Start here'), findsNothing);
    expect(find.text('Your scans live here'), findsOneWidget);
  });

  testWidgets('nothing is shown when no target exists at all', (tester) async {
    await start(tester, [
      TutorialStep(
        targetKey: neverRendered,
        titleKey: 'tutorial_scan_title',
        bodyKey: 'tutorial_scan_body',
      ),
    ]);

    expect(find.byKey(const Key('tutorial_next_button')), findsNothing);
    // The host screen is still usable.
    expect(find.text('start'), findsOneWidget);
  });

  testWidgets('tapping the backdrop advances', (tester) async {
    await start(tester, [
      TutorialStep(
        targetKey: targetA,
        titleKey: 'tutorial_scan_title',
        bodyKey: 'tutorial_scan_body',
      ),
      TutorialStep(
        targetKey: targetB,
        titleKey: 'tutorial_nav_title',
        bodyKey: 'tutorial_nav_body',
      ),
    ]);

    // The whole surface absorbs taps, so a farmer cannot half-follow the
    // tutorial and half-drive the app underneath it.
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('Your scans live here'), findsOneWidget);
  });
}
