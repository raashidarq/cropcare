// Enforces what CODEBASE_MAP §9 rule 12 asks for and nothing checked:
// every user-visible string exists in all three languages.
//
// A key present in `en` but missing from `si` does not throw, does not fail a
// build, and does not log. `AppLocalizations.get` falls back to `en` and then
// to the key itself, so the failure mode is a Sinhala-speaking farmer seeing
// `treatment_what_to_avoid` on screen. That is invisible to anyone reviewing a
// diff in English, which is why this is a test and not a convention.

import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/presentation/onboarding/localization/app_localizations.dart';

void main() {
  final tables = AppLocalizations.tables;

  test('all three language tables are present', () {
    expect(tables.keys.toSet(), {'en', 'si', 'ta'});
  });

  test('si and ta define exactly the keys en defines', () {
    final en = tables['en']!.keys.toSet();

    for (final lang in ['si', 'ta']) {
      final keys = tables[lang]!.keys.toSet();

      expect(
        en.difference(keys),
        isEmpty,
        reason: 'Keys missing from "$lang" — these would render as raw key '
            'strings to a $lang reader. Add them to the $lang map in '
            'app_localizations.dart.',
      );
      expect(
        keys.difference(en),
        isEmpty,
        reason: 'Keys in "$lang" with no English counterpart. Either the key '
            'was renamed in en and not here, or it is dead.',
      );
    }
  });

  test('no translation is blank', () {
    for (final entry in tables.entries) {
      for (final pair in entry.value.entries) {
        expect(
          pair.value.trim(),
          isNotEmpty,
          reason: '"${pair.key}" is empty in "${entry.key}".',
        );
      }
    }
  });

  test('no si or ta value is left as the untranslated English string', () {
    final en = tables['en']!;

    // Some values are legitimately identical across languages. They are listed
    // rather than pattern-matched so that adding a new one is a deliberate
    // act, reviewed once, instead of a hole the check silently falls through.
    const sharedAcrossLanguages = {
      'app_title',
      // Endonyms: each language names itself in its own script in the picker,
      // so every table carries the same three strings.
      'lang_english',
      'lang_sinhala',
      'lang_tamil',
      // Used as an acronym in Sinhala and Tamil too, not translated.
      'treatment_source_ai',
      // A phone-number mask, not prose.
      'phone_number_hint',
    };

    for (final lang in ['si', 'ta']) {
      final untranslated = <String>[];
      for (final pair in tables[lang]!.entries) {
        if (sharedAcrossLanguages.contains(pair.key)) continue;
        if (en[pair.key] == pair.value) untranslated.add(pair.key);
      }

      expect(
        untranslated,
        isEmpty,
        reason: 'These "$lang" values are byte-identical to the English one, '
            'which usually means a key was copied across and never '
            'translated: ${untranslated.join(', ')}',
      );
    }
  });
}
