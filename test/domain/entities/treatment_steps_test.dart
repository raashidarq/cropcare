// Guidance renders as short steps. The backend authors them directly; the
// on-device guideline table stores prose, so those are split for display.
//
// The split is crude on purpose — the seeded guidelines really are lists of
// actions written as sentences ("Prune affected leaves. Spray copper.") and a
// wrong split costs an odd line break, not meaning.

import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/domain/entities/treatment.dart';

void main() {
  group('splitIntoSteps', () {
    test('splits prose on sentence ends', () {
      expect(
        TreatmentResponse.splitIntoSteps(
          'Prune affected leaves. Spray copper fungicide. Water at the base.',
        ),
        [
          'Prune affected leaves.',
          'Spray copper fungicide.',
          'Water at the base.',
        ],
      );
    });

    test('handles a single sentence with no trailing stop', () {
      expect(
        TreatmentResponse.splitIntoSteps('Remove infected leaves'),
        ['Remove infected leaves'],
      );
    });

    test('keeps question and exclamation marks as boundaries', () {
      expect(
        TreatmentResponse.splitIntoSteps('Act now! Do not wait.'),
        ['Act now!', 'Do not wait.'],
      );
    });

    test('empty prose yields no steps rather than one blank one', () {
      expect(TreatmentResponse.splitIntoSteps('   '), isEmpty);
    });
  });

  group('effective steps', () {
    test('authored steps win over the prose', () {
      const treatment = TreatmentResponse(
        summary: 's',
        whatToDo: 'Ignore this prose. It should not be used.',
        whatToAvoid: 'Nor this.',
        doSteps: ['Authored step one', 'Authored step two'],
        avoidSteps: ['Authored avoid'],
      );

      expect(treatment.effectiveDoSteps,
          ['Authored step one', 'Authored step two']);
      expect(treatment.effectiveAvoidSteps, ['Authored avoid']);
    });

    test('prose is split when no steps were authored', () {
      const treatment = TreatmentResponse(
        summary: 's',
        whatToDo: 'Prune leaves. Spray copper.',
        whatToAvoid: 'Do not compost.',
      );

      expect(treatment.effectiveDoSteps, ['Prune leaves.', 'Spray copper.']);
      expect(treatment.effectiveAvoidSteps, ['Do not compost.']);
    });
  });

  group('fromJson', () {
    test('reads the step lists the backend now sends', () {
      final treatment = TreatmentResponse.fromJson(const {
        'summary': 'A fungus.',
        'what_to_do': 'Joined prose.',
        'what_to_avoid': 'Joined avoid.',
        'what_to_do_steps': ['Step one', 'Step two'],
        'what_to_avoid_steps': ['Avoid one'],
        'recheck_after_days': 5,
        'interpretation_id': 'i-1',
      });

      expect(treatment.doSteps, ['Step one', 'Step two']);
      expect(treatment.avoidSteps, ['Avoid one']);
      expect(treatment.recheckAfterDays, 5);
    });

    test('a response without step lists still works', () {
      // A server that predates the change, or a cached older payload.
      final treatment = TreatmentResponse.fromJson(const {
        'summary': 'A fungus.',
        'what_to_do': 'Prune leaves. Spray copper.',
        'what_to_avoid': 'Do not compost.',
        'recheck_after_days': 5,
      });

      expect(treatment.doSteps, isEmpty);
      expect(treatment.effectiveDoSteps, ['Prune leaves.', 'Spray copper.']);
    });

    test('blank entries in the step lists are dropped', () {
      final treatment = TreatmentResponse.fromJson(const {
        'summary': 's',
        'what_to_do': '',
        'what_to_avoid': '',
        'what_to_do_steps': ['Real step', '', '   '],
      });

      expect(treatment.doSteps, ['Real step']);
    });
  });
}
