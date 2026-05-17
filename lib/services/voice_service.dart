import 'package:flutter_tts/flutter_tts.dart';

class VoiceService {
  VoiceService._();
  static final VoiceService instance = VoiceService._();

  final FlutterTts _tts = FlutterTts();

  bool isEnabled = false;
  bool _initialized = false;

  Future<void> initialize({String languageCode = 'en-US'}) async {
    if (!_initialized) {
      await _tts.setLanguage(languageCode);
      await _tts.setSpeechRate(0.45);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } else {
      await _tts.setLanguage(languageCode);
    }
  }

  Future<void> setLanguage(String languageCode) async {
    await initialize(languageCode: languageCode);
  }

  Future<void> speak(String text) async {
    if (!isEnabled) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakForced(String text, {String languageCode = 'en-US'}) async {
    await initialize(languageCode: languageCode);
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> stop() async {
    await _tts.stop();
  }
}
