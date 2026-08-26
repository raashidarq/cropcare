// lib/data/local/tts/text_to_speech_service.dart
//
// Service managing Text-To-Speech audio playback for localized treatment guidance.

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

abstract class TtsService {
  ValueListenable<bool> get isPlaying;
  Future<void> speak({
    required String text,
    required String languageCode,
    /// Playback pace, 0.0–1.0. The Accessibility screen exposes this because
    /// read-aloud is a primary path through the app for anyone who does not
    /// read comfortably, and the right pace differs a lot per person.
    double speechRate,
  });
  Future<void> stop();
  void dispose();
}

class TextToSpeechService implements TtsService {
  final FlutterTts _flutterTts;
  final ValueNotifier<bool> _isPlayingNotifier = ValueNotifier<bool>(false);

  TextToSpeechService({FlutterTts? flutterTts})
      : _flutterTts = flutterTts ?? FlutterTts() {
    _initTts();
  }

  @override
  ValueListenable<bool> get isPlaying => _isPlayingNotifier;

  void _initTts() {
    try {
      _flutterTts.setStartHandler(() {
        _isPlayingNotifier.value = true;
      });

      _flutterTts.setCompletionHandler(() {
        _isPlayingNotifier.value = false;
      });

      _flutterTts.setCancelHandler(() {
        _isPlayingNotifier.value = false;
      });

      _flutterTts.setErrorHandler((dynamic message) {
        _isPlayingNotifier.value = false;
      });
    } catch (_) {}
  }

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
    double speechRate = 0.5,
  }) async {
    if (text.trim().isEmpty) return;

    try {
      // Map app language code to BCP-47 locale tag
      final ttsLanguage = _mapLanguageCode(languageCode);

      // Was hardcoded to 0.5, which silently ignored the user's setting.
      await _flutterTts.setSpeechRate(speechRate.clamp(0.1, 1.0));
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Check if language is available; if not, default gracefully
      final isAvailable = await _flutterTts.isLanguageAvailable(ttsLanguage);
      if (isAvailable == 1 || isAvailable == true) {
        await _flutterTts.setLanguage(ttsLanguage);
      } else {
        // Fallback to English if Sinhala/Tamil voice is missing on device TTS engine
        await _flutterTts.setLanguage('en-US');
      }

      _isPlayingNotifier.value = true;
      await _flutterTts.speak(text);
    } catch (e) {
      _isPlayingNotifier.value = false;
    }
  }

  @override
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {} finally {
      _isPlayingNotifier.value = false;
    }
  }

  String _mapLanguageCode(String code) {
    switch (code) {
      case 'si':
        return 'si-LK';
      case 'ta':
        return 'ta-IN';
      case 'en':
      default:
        return 'en-US';
    }
  }

  @override
  void dispose() {
    stop();
    _isPlayingNotifier.dispose();
  }
}
