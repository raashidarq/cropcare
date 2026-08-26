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
  static const _kWifiOnlyKey = 'cropcare_sync_wifi_only';

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

  /// Defaults to TRUE, unlike auto-sync.
  ///
  /// Auto-sync defaults off because uploading at all is the farmer's choice.
  /// Once they have made that choice, the safe default for *how* is the one
  /// that does not spend their mobile data: someone who opts into background
  /// syncing has not thereby agreed to pay for it by the megabyte.
  Future<bool> getWifiOnly() async {
    try {
      final raw = await _storage.read(key: _kWifiOnlyKey);
      return raw != 'false';
    } catch (_) {
      return true;
    }
  }

  Future<void> setWifiOnly(bool enabled) async {
    try {
      await _storage.write(key: _kWifiOnlyKey, value: enabled ? 'true' : 'false');
    } catch (_) {}
  }
}
