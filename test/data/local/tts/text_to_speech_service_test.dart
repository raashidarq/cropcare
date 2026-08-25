import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:cropcare/data/local/tts/text_to_speech_service.dart';

class _FakeTtsService implements TtsService {
  final ValueNotifier<bool> _playingNotifier = ValueNotifier<bool>(false);
  String? lastSpokenText;
  String? lastLanguageCode;

  @override
  ValueListenable<bool> get isPlaying => _playingNotifier;

  @override
  Future<void> speak({
    required String text,
    required String languageCode,
  }) async {
    lastSpokenText = text;
    lastLanguageCode = languageCode;
    _playingNotifier.value = true;
  }

  @override
  Future<void> stop() async {
    _playingNotifier.value = false;
  }

  @override
  void dispose() {
    _playingNotifier.dispose();
  }
}

void main() {
  group('TtsService', () {
    test('speak updates state to playing and records text', () async {
      final fakeTts = _FakeTtsService();

      expect(fakeTts.isPlaying.value, isFalse);

      await fakeTts.speak(
        text: 'Late blight detected. Spray fungicide.',
        languageCode: 'en',
      );

      expect(fakeTts.isPlaying.value, isTrue);
      expect(fakeTts.lastSpokenText, equals('Late blight detected. Spray fungicide.'));
      expect(fakeTts.lastLanguageCode, equals('en'));

      await fakeTts.stop();
      expect(fakeTts.isPlaying.value, isFalse);

      fakeTts.dispose();
    });
  });
}
