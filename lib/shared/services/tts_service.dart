import 'dart:io';

import 'package:flutter_tts/flutter_tts.dart';
import 'package:logging/logging.dart';

/// Text-to-Speech service for AI responses
///
/// Provides spoken feedback for AI assistant responses,
/// with support for multiple languages common in Sub-Saharan Africa.
class TTSService {
  static final _log = Logger('TTSService');
  
  final FlutterTts _tts = FlutterTts();
  bool _isInitialized = false;
  bool _isSpeaking = false;
  
  /// Supported language codes
  static const supportedLanguages = {
    'en': 'en-US',     // English
    'fr': 'fr-FR',     // French
    'sw': 'sw-KE',     // Swahili
    'rw': 'rw-RW',     // Kinyarwanda (fallback to en if not available)
  };

  /// Initialize the TTS engine
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Set default parameters
      await _tts.setVolume(1.0);
      await _tts.setSpeechRate(0.5);
      await _tts.setPitch(1.0);
      
      // Use English as default
      await _tts.setLanguage('en-US');
      
      // Set up completion handler
      _tts.setCompletionHandler(() {
        _isSpeaking = false;
      });
      
      _tts.setErrorHandler((message) {
        _log.warning('TTS error: $message');
        _isSpeaking = false;
      });
      
      _isInitialized = true;
      _log.info('TTS service initialized');
    } catch (e) {
      _log.warning('Failed to initialize TTS: $e');
    }
  }

  /// Speak the given text
  Future<void> speak(String text, {String languageCode = 'en'}) async {
    if (!_isInitialized) {
      await initialize();
    }
    
    if (text.isEmpty) return;
    
    try {
      // Stop any ongoing speech
      if (_isSpeaking) {
        await stop();
      }
      
      // Set language
      final ttsLanguage = supportedLanguages[languageCode] ?? 'en-US';
      await _tts.setLanguage(ttsLanguage);
      
      _isSpeaking = true;
      await _tts.speak(text);
      _log.fine('Speaking: ${text.substring(0, text.length.clamp(0, 50))}...');
    } catch (e) {
      _log.warning('Failed to speak: $e');
      _isSpeaking = false;
    }
  }

  /// Stop any ongoing speech
  Future<void> stop() async {
    try {
      await _tts.stop();
      _isSpeaking = false;
    } catch (e) {
      _log.warning('Failed to stop TTS: $e');
    }
  }

  /// Check if currently speaking
  bool get isSpeaking => _isSpeaking;

  /// Set speech rate (0.0 to 1.0)
  Future<void> setSpeechRate(double rate) async {
    await _tts.setSpeechRate(rate.clamp(0.0, 1.0));
  }

  /// Check if TTS is available on this device
  Future<bool> isAvailable() async {
    try {
      if (Platform.isIOS) {
        return true; // iOS always has TTS
      }
      final engines = await _tts.getEngines;
      return engines.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get available languages on this device
  Future<List<String>> getAvailableLanguages() async {
    try {
      final languages = await _tts.getLanguages;
      return languages.cast<String>();
    } catch (e) {
      return ['en-US'];
    }
  }

  /// Dispose resources
  Future<void> dispose() async {
    await stop();
    _isInitialized = false;
  }
}
