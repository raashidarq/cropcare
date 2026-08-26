// lib/data/local/preferences/sync_preferences.dart
//
// Persists the auto-sync preference.
//
// Auto-sync was previously an in-memory flag defaulting to ON, which meant a
// guest who had never signed in still had a background sync path armed, and
// the choice reset on every launch. It now defaults to OFF and survives
// restarts.
//
// Uses FlutterSecureStorage to match how AccessibilityRepositoryImpl already
// stores its settings, rather than introducing a second preference mechanism.

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SyncPreferences {
  static const _kAutoSyncKey = 'cropcare_auto_sync_enabled';

  final FlutterSecureStorage _storage;

  SyncPreferences({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  /// Defaults to false: syncing uploads a farmer's photos over what is often
  /// a metered connection, so it is opt-in.
  Future<bool> getAutoSyncEnabled() async {
    try {
      final raw = await _storage.read(key: _kAutoSyncKey);
      return raw == 'true';
    } catch (_) {
      return false;
    }
  }

  Future<void> setAutoSyncEnabled(bool enabled) async {
    try {
      await _storage.write(key: _kAutoSyncKey, value: enabled ? 'true' : 'false');
    } catch (_) {
      // Non-fatal: the in-memory value still applies for this session.
    }
  }
}
