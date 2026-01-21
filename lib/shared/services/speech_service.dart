// ============================================================================
// SPEECH SERVICE - shared/services/speech_service.dart
// ============================================================================

import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';

class SpeechService {
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _tts = FlutterTts();

  /// Initialize speech recognition
  Future<bool> initializeSpeech() async {
    return await _speech.initialize();
  }

  /// Start listening
  Future<void> startListening({
    required Function(String) onResult,
    String localeId = 'en_US',
  }) async {
    await _speech.listen(
      onResult: (result) => onResult(result.recognizedWords),
      localeId: localeId,
    );
  }

  /// Stop listening
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Speak text
  Future<void> speak(String text) async {
    await _tts.setLanguage('en-US');
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.speak(text);
  }

  /// Stop speaking
  Future<void> stopSpeaking() async {
    await _tts.stop();
  }

  bool get isListening => _speech.isListening;
}
