// lib/data/local/speech/speech_recognition_service.dart
//
// Speech-to-text for the observations field: the input-side counterpart to
// TextToSpeechService, and deliberately shaped like it (a ValueListenable for
// the active state, an explicit dispose) so the record and read-aloud controls
// behave as a pair.
//
// Why this exists: typing is the worst interaction in this app for its
// audience. Sinhala and Tamil on-screen keyboards are slow and unfamiliar to
// many users, the farmer is usually one-handed in a field, and limited
// literacy is an explicit design constraint across the codebase — it is why
// read-aloud is a first-class control on the result screen.
//
// Language support is the platform's, not this package's. `speech_to_text`
// drives the device recognizer, so whether Sinhala or Tamil work at all
// depends on the language packs installed on that particular phone. That is
// why `localeAvailable` exists and why the UI must ask before offering the
// mic: an English-only mic button would serve exactly the users who least
// need it.
//
// No audio is stored. Transcription goes straight into the text field, and
// the recognizer is stopped and released on dispose.

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Why a recording attempt could not start. Distinguished so the UI can say
/// something specific instead of failing silently.
enum SpeechUnavailableReason {
  /// The user said no, but can be asked again.
  permissionDenied,

  /// The user said "don't ask again"; only the system settings screen helps.
  permissionPermanentlyDenied,

  /// No recognizer on the device, or it refused to initialise.
  unavailableOnDevice,

  /// A recognizer exists but has nothing installed for this language.
  languageNotInstalled,
}

class SpeechUnavailable implements Exception {
  final SpeechUnavailableReason reason;

  const SpeechUnavailable(this.reason);
}

/// Microphone permission, behind an interface so tests can inject a fake.
///
/// Mirrors `CameraPermissionService` in scan_cubit.dart, with one deliberate
/// difference: that one wraps its calls in a blanket `catch (_)` that reports
/// a plugin failure as a denial. That conflation is a known weakness there,
/// not a pattern worth spreading, so it is not repeated here.
abstract class MicrophonePermissionService {
  Future<ph.PermissionStatus> checkPermission();
  Future<ph.PermissionStatus> requestPermission();
  Future<bool> openAppSettings();
}

class DefaultMicrophonePermissionService
    implements MicrophonePermissionService {
  const DefaultMicrophonePermissionService();

  @override
  Future<ph.PermissionStatus> checkPermission() =>
      ph.Permission.microphone.status;

  @override
  Future<ph.PermissionStatus> requestPermission() =>
      ph.Permission.microphone.request();

  @override
  Future<bool> openAppSettings() => ph.openAppSettings();
}

abstract class SpeechRecognitionService {
  /// True while the recognizer is listening. Drives the record button, the
  /// same way `TtsService.isPlaying` drives read-aloud.
  ValueListenable<bool> get isListening;

  /// Prepares the recognizer. Returns false when the device has none.
  Future<bool> initialize();

  /// Whether the device can transcribe [languageCode] at all.
  Future<bool> localeAvailable(String languageCode);

  /// Starts listening, reporting partial text as the farmer speaks.
  ///
  /// Throws [SpeechUnavailable] rather than failing quietly, so the caller can
  /// explain which of the several possible problems occurred.
  Future<void> startListening({
    required String languageCode,
    required ValueChanged<String> onResult,
  });

  Future<void> stopListening();

  /// Opens the system settings page, for a permanently denied permission.
  Future<void> openAppSettings();

  void dispose();
}

class DeviceSpeechRecognitionService implements SpeechRecognitionService {
  final stt.SpeechToText _speech;
  final MicrophonePermissionService _permissions;
  final ValueNotifier<bool> _isListening = ValueNotifier<bool>(false);

  bool _initialized = false;

  DeviceSpeechRecognitionService({
    stt.SpeechToText? speechToText,
    MicrophonePermissionService? permissionService,
  })  : _speech = speechToText ?? stt.SpeechToText(),
        _permissions = permissionService ??
            const DefaultMicrophonePermissionService();

  @override
  ValueListenable<bool> get isListening => _isListening;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        // Both handlers exist to keep `_isListening` honest. Without them the
        // button stays lit after the recognizer has given up on its own,
        // which reads as a hung app.
        onStatus: (status) {
          _isListening.value = status == 'listening';
        },
        onError: (_) {
          _isListening.value = false;
        },
      );
    } catch (_) {
      _initialized = false;
    }
    return _initialized;
  }

  @override
  Future<bool> localeAvailable(String languageCode) async {
    if (!await initialize()) return false;
    try {
      final locales = await _speech.locales();
      final wanted = _localeTagFor(languageCode).toLowerCase();
      final prefix = languageCode.toLowerCase();
      return locales.any((l) {
        final id = l.localeId.toLowerCase().replaceAll('-', '_');
        return id == wanted.toLowerCase().replaceAll('-', '_') ||
            id.startsWith('${prefix}_') ||
            id == prefix;
      });
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> startListening({
    required String languageCode,
    required ValueChanged<String> onResult,
  }) async {
    final status = await _permissions.checkPermission();
    var granted = status.isGranted;

    if (!granted) {
      if (status.isPermanentlyDenied) {
        throw const SpeechUnavailable(
          SpeechUnavailableReason.permissionPermanentlyDenied,
        );
      }
      final requested = await _permissions.requestPermission();
      if (requested.isPermanentlyDenied) {
        throw const SpeechUnavailable(
          SpeechUnavailableReason.permissionPermanentlyDenied,
        );
      }
      granted = requested.isGranted;
    }

    if (!granted) {
      throw const SpeechUnavailable(SpeechUnavailableReason.permissionDenied);
    }

    if (!await initialize()) {
      throw const SpeechUnavailable(
        SpeechUnavailableReason.unavailableOnDevice,
      );
    }

    if (!await localeAvailable(languageCode)) {
      throw const SpeechUnavailable(
        SpeechUnavailableReason.languageNotInstalled,
      );
    }

    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      listenOptions: stt.SpeechListenOptions(
        localeId: _localeTagFor(languageCode),
        // Partial results are what make the mic feel alive. Without them the
        // farmer sees nothing until they stop talking, which reads as broken.
        partialResults: true,
        cancelOnError: true,
        // Generous windows: silence detection is unreliable in wind and field
        // noise, and cutting someone off mid-sentence is worse than waiting.
        // There is always an explicit stop control.
        listenFor: const Duration(seconds: 60),
        pauseFor: const Duration(seconds: 6),
      ),
    );
    _isListening.value = true;
  }

  @override
  Future<void> stopListening() async {
    try {
      await _speech.stop();
    } catch (_) {
      // Stopping a recognizer that already stopped is not an error worth
      // surfacing; the state below is what the UI reads.
    }
    _isListening.value = false;
  }

  @override
  Future<void> openAppSettings() async {
    await _permissions.openAppSettings();
  }

  @override
  void dispose() {
    try {
      _speech.cancel();
    } catch (_) {}
    _isListening.dispose();
  }

  /// Maps the app's language code to a BCP-47 tag, matching the mapping
  /// TextToSpeechService already uses for the same three languages.
  static String _localeTagFor(String languageCode) {
    switch (languageCode) {
      case 'si':
        return 'si_LK';
      case 'ta':
        return 'ta_IN';
      default:
        return 'en_US';
    }
  }
}
