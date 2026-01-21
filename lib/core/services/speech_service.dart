import 'dart:async';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service for speech-to-text and voice input processing
///
/// Supports multiple languages common in Sub-Saharan Africa:
/// - English (en)
/// - French (fr)
/// - Swahili (sw)
/// - Kinyarwanda (rw)
class SpeechService {
  static final _log = Logger('SpeechService');
  
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isInitialized = false;
  bool _isListening = false;
  String _currentLocale = 'en_US';
  
  /// Currently supported locales
  static const Map<String, String> supportedLocales = {
    'en': 'en_US',
    'fr': 'fr_FR',
    'sw': 'sw_KE',
    'rw': 'rw_RW',
  };

  /// Initialize the speech recognition service
  Future<bool> initialize() async {
    if (_isInitialized) return true;
    
    try {
      _isInitialized = await _speech.initialize(
        onError: (error) {
          _log.warning('Speech recognition error: ${error.errorMsg}');
        },
        onStatus: (status) {
          _log.fine('Speech status: $status');
        },
      );
      
      if (_isInitialized) {
        _log.info('Speech recognition initialized successfully');
        await _loadAvailableLocales();
      } else {
        _log.warning('Speech recognition initialization failed');
      }
      
      return _isInitialized;
    } catch (e, stackTrace) {
      _log.severe('Failed to initialize speech recognition', e, stackTrace);
      return false;
    }
  }

  Future<void> _loadAvailableLocales() async {
    final locales = await _speech.locales();
    _log.fine('Available locales: ${locales.map((l) => l.localeId).join(', ')}');
  }

  /// Check if speech recognition is available
  bool get isAvailable => _isInitialized;

  /// Check if currently listening
  bool get isListening => _isListening;

  /// Set the language for speech recognition
  /// 
  /// [languageCode] should be one of: 'en', 'fr', 'sw', 'rw'
  void setLanguage(String languageCode) {
    final locale = supportedLocales[languageCode];
    if (locale != null) {
      _currentLocale = locale;
      _log.info('Set speech language to: $locale');
    } else {
      _log.warning('Unsupported language code: $languageCode, using default');
    }
  }

  /// Start listening for speech input
  /// 
  /// [onResult] is called with recognized text (partial and final)
  /// [onListening] is called when listening state changes
  /// [onError] is called when an error occurs
  Future<void> startListening({
    required ValueChanged<String> onResult,
    ValueChanged<bool>? onListening,
    ValueChanged<String>? onError,
    Duration? listenFor,
    bool partialResults = true,
  }) async {
    if (!_isInitialized) {
      final initialized = await initialize();
      if (!initialized) {
        onError?.call('Speech recognition not available');
        return;
      }
    }

    if (_isListening) {
      _log.info('Already listening, stopping first');
      await stopListening();
    }

    try {
      _isListening = true;
      onListening?.call(true);

      await _speech.listen(
        onResult: (result) {
          _log.fine('Speech result: ${result.recognizedWords} (final: ${result.finalResult})');
          onResult(result.recognizedWords);
        },
        listenFor: listenFor ?? const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        localeId: _currentLocale,
        listenOptions: stt.SpeechListenOptions(
          partialResults: partialResults,
          cancelOnError: true,
          listenMode: stt.ListenMode.confirmation,
        ),
      );
    } catch (e, stackTrace) {
      _log.warning('Error starting speech recognition', e, stackTrace);
      _isListening = false;
      onListening?.call(false);
      onError?.call('Failed to start listening: $e');
    }
  }

  /// Stop listening for speech input
  Future<void> stopListening() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      _log.info('Stopped listening');
    }
  }

  /// Cancel listening for speech input
  Future<void> cancelListening() async {
    if (_isListening) {
      await _speech.cancel();
      _isListening = false;
      _log.info('Cancelled listening');
    }
  }

  /// Cancel the current listening session
  Future<void> cancel() async {
    await _speech.cancel();
    _isListening = false;
    _log.info('Cancelled speech recognition');
  }

  /// Detect the most likely language from a text sample
  /// 
  /// Uses simple heuristics based on common words and characters
  String detectLanguage(String text) {
    final lower = text.toLowerCase();
    
    // Kinyarwanda indicators
    if (_containsAny(lower, ['mwaramutse', 'muraho', 'amakuru', 'ni', 'ndi', 'ubu', 'iki', 'kuri'])) {
      return 'rw';
    }
    
    // Swahili indicators
    if (_containsAny(lower, ['habari', 'jambo', 'asante', 'kwenda', 'kutoka', 'hapa', 'sasa', 'nina'])) {
      return 'sw';
    }
    
    // French indicators
    if (_containsAny(lower, ['je', 'veux', 'aller', 'bonjour', 'merci', 'où', 'demain', 'aujourd'])) {
      return 'fr';
    }
    
    // Default to English
    return 'en';
  }

  bool _containsAny(String text, List<String> words) {
    return words.any((word) => text.contains(word));
  }

  /// Get a user-friendly name for a language code
  static String getLanguageName(String code) {
    switch (code) {
      case 'en':
        return 'English';
      case 'fr':
        return 'Français';
      case 'sw':
        return 'Kiswahili';
      case 'rw':
        return 'Kinyarwanda';
      default:
        return code.toUpperCase();
    }
  }

  /// Dispose of resources
  void dispose() {
    if (_isListening) {
      _speech.cancel();
    }
    _isInitialized = false;
    _isListening = false;
  }
}

/// Widget that provides voice input with visual feedback
class VoiceInputButton extends StatefulWidget {
  /// Callback with recognized text
  final ValueChanged<String> onResult;
  
  /// Callback when listening state changes
  final ValueChanged<bool>? onListening;
  
  /// Error callback
  final ValueChanged<String>? onError;
  
  /// Language code ('en', 'fr', 'sw', 'rw')
  final String languageCode;
  
  /// Button size
  final double size;
  
  /// Custom inactive color
  final Color? inactiveColor;
  
  /// Custom active color
  final Color? activeColor;

  const VoiceInputButton({
    super.key,
    required this.onResult,
    this.onListening,
    this.onError,
    this.languageCode = 'en',
    this.size = 56,
    this.inactiveColor,
    this.activeColor,
  });

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  final SpeechService _speechService = SpeechService();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _speechService.setLanguage(widget.languageCode);
  }

  @override
  void didUpdateWidget(VoiceInputButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.languageCode != widget.languageCode) {
      _speechService.setLanguage(widget.languageCode);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechService.dispose();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speechService.stopListening();
      setState(() => _isListening = false);
      _pulseController.stop();
      _pulseController.reset();
      widget.onListening?.call(false);
    } else {
      setState(() => _isListening = true);
      _pulseController.repeat(reverse: true);
      widget.onListening?.call(true);
      
      await _speechService.startListening(
        onResult: (text) {
          if (text.isNotEmpty) {
            widget.onResult(text);
          }
        },
        onListening: (listening) {
          if (!listening && mounted) {
            setState(() => _isListening = false);
            _pulseController.stop();
            _pulseController.reset();
            widget.onListening?.call(false);
          }
        },
        onError: (error) {
          setState(() => _isListening = false);
          _pulseController.stop();
          _pulseController.reset();
          widget.onListening?.call(false);
          widget.onError?.call(error);
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactiveColor = widget.inactiveColor ?? theme.colorScheme.primary;
    final activeColor = widget.activeColor ?? theme.colorScheme.error;

    return GestureDetector(
      onTap: _toggleListening,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            width: widget.size * (_isListening ? _pulseAnimation.value : 1.0),
            height: widget.size * (_isListening ? _pulseAnimation.value : 1.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _isListening
                  ? activeColor.withValues(alpha: 0.15)
                  : inactiveColor.withValues(alpha: 0.1),
              border: Border.all(
                color: _isListening ? activeColor : inactiveColor,
                width: 2,
              ),
              boxShadow: _isListening
                  ? [
                      BoxShadow(
                        color: activeColor.withValues(alpha: 0.3),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Icon(
              _isListening ? Icons.mic : Icons.mic_none,
              size: widget.size * 0.5,
              color: _isListening ? activeColor : inactiveColor,
            ),
          );
        },
      ),
    );
  }
}
