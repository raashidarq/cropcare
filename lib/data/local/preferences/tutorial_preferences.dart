// lib/data/local/preferences/tutorial_preferences.dart
//
// Remembers whether the home walkthrough has been shown.
//
// Secure storage rather than a new column on `app_state`: this is a
// preference, not app state worth a schema migration, and `SyncPreferences`
// already established the pattern.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TutorialPreferences {
  static const _kHomeTutorialSeenKey = 'cropcare_home_tutorial_seen';

  final FlutterSecureStorage _storage;

  TutorialPreferences({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Defaults to true — i.e. "already seen" — when storage cannot be read.
  ///
  /// Erring toward not showing it: a walkthrough that reappears on every
  /// launch because a read failed is far more irritating than one a farmer
  /// misses and can replay from Settings.
  Future<bool> hasSeenHomeTutorial() async {
    try {
      final raw = await _storage.read(key: _kHomeTutorialSeenKey);
      return raw == 'true';
    } catch (_) {
      return true;
    }
  }

  Future<void> setHomeTutorialSeen(bool seen) async {
    try {
      await _storage.write(
        key: _kHomeTutorialSeenKey,
        value: seen ? 'true' : 'false',
      );
    } catch (_) {}
  }
}
