import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Manages chat history persistence for AI conversations
///
/// Features:
/// - Stores chat history in SharedPreferences
/// - Supports multiple conversation sessions
/// - Automatic session cleanup (configurable max history)
/// - Converts between Gemini Content and serializable format
class ChatHistoryManager {
  static final _log = Logger('ChatHistoryManager');
  
  static const String _keyPrefix = 'chat_history_';
  static const String _sessionsKey = 'chat_sessions';
  static const int defaultMaxMessages = 50;
  static const int defaultMaxSessions = 10;

  final SharedPreferences _prefs;
  final int maxMessages;
  final int maxSessions;

  ChatHistoryManager({
    required SharedPreferences prefs,
    this.maxMessages = defaultMaxMessages,
    this.maxSessions = defaultMaxSessions,
  }) : _prefs = prefs;

  /// Create a manager (async factory)
  static Future<ChatHistoryManager> create({
    int maxMessages = defaultMaxMessages,
    int maxSessions = defaultMaxSessions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    return ChatHistoryManager(
      prefs: prefs,
      maxMessages: maxMessages,
      maxSessions: maxSessions,
    );
  }

  // =========================================================================
  // SESSION MANAGEMENT
  // =========================================================================

  /// Get all active chat session IDs
  List<String> getSessionIds() {
    final sessionsJson = _prefs.getString(_sessionsKey);
    if (sessionsJson == null) return [];
    
    try {
      final list = jsonDecode(sessionsJson) as List<dynamic>;
      return list.cast<String>();
    } catch (e) {
      _log.warning('Failed to parse sessions: $e');
      return [];
    }
  }

  /// Create a new chat session
  Future<String> createSession({String? title}) async {
    final sessionId = 'session_${DateTime.now().millisecondsSinceEpoch}';
    
    // Add to sessions list
    final sessions = getSessionIds();
    sessions.insert(0, sessionId);
    
    // Trim old sessions if needed
    if (sessions.length > maxSessions) {
      final toRemove = sessions.sublist(maxSessions);
      for (final id in toRemove) {
        await deleteSession(id);
      }
      sessions.removeRange(maxSessions, sessions.length);
    }
    
    await _prefs.setString(_sessionsKey, jsonEncode(sessions));
    
    // Store session metadata
    await _prefs.setString('$_keyPrefix${sessionId}_meta', jsonEncode({
      'id': sessionId,
      'title': title ?? 'New Chat',
      'createdAt': DateTime.now().toIso8601String(),
      'updatedAt': DateTime.now().toIso8601String(),
    }));
    
    _log.info('Created chat session: $sessionId');
    return sessionId;
  }

  /// Delete a chat session
  Future<void> deleteSession(String sessionId) async {
    await _prefs.remove('$_keyPrefix$sessionId');
    await _prefs.remove('$_keyPrefix${sessionId}_meta');
    
    final sessions = getSessionIds();
    sessions.remove(sessionId);
    await _prefs.setString(_sessionsKey, jsonEncode(sessions));
    
    _log.info('Deleted chat session: $sessionId');
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    final sessions = getSessionIds();
    for (final id in sessions) {
      await _prefs.remove('$_keyPrefix$id');
      await _prefs.remove('$_keyPrefix${id}_meta');
    }
    await _prefs.remove(_sessionsKey);
    _log.info('Cleared all chat sessions');
  }

  // =========================================================================
  // MESSAGE PERSISTENCE
  // =========================================================================

  /// Save chat history for a session
  Future<void> saveHistory(String sessionId, List<Content> history) async {
    final messages = history.map(_contentToMap).toList();
    
    // Trim to max messages
    if (messages.length > maxMessages) {
      messages.removeRange(0, messages.length - maxMessages);
    }
    
    await _prefs.setString('$_keyPrefix$sessionId', jsonEncode(messages));
    
    // Update session metadata
    final metaJson = _prefs.getString('$_keyPrefix${sessionId}_meta');
    if (metaJson != null) {
      try {
        final meta = jsonDecode(metaJson) as Map<String, dynamic>;
        meta['updatedAt'] = DateTime.now().toIso8601String();
        meta['messageCount'] = messages.length;
        await _prefs.setString('$_keyPrefix${sessionId}_meta', jsonEncode(meta));
      } catch (_) {}
    }
    
    _log.fine('Saved ${messages.length} messages for session $sessionId');
  }

  /// Load chat history for a session
  List<Content> loadHistory(String sessionId) {
    final historyJson = _prefs.getString('$_keyPrefix$sessionId');
    if (historyJson == null) return [];
    
    try {
      final messages = jsonDecode(historyJson) as List<dynamic>;
      return messages
          .map((m) => _mapToContent(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _log.warning('Failed to load history for $sessionId: $e');
      return [];
    }
  }

  /// Add a message to history
  Future<void> addMessage(String sessionId, Content message) async {
    final history = loadHistory(sessionId);
    history.add(message);
    await saveHistory(sessionId, history);
  }

  /// Add a user message and response to history
  Future<void> addExchange(
    String sessionId,
    String userMessage,
    String aiResponse,
  ) async {
    final history = loadHistory(sessionId);
    history.add(Content.text(userMessage));
    history.add(Content.model([TextPart(aiResponse)]));
    await saveHistory(sessionId, history);
  }

  // =========================================================================
  // SESSION METADATA
  // =========================================================================

  /// Get session metadata
  Map<String, dynamic>? getSessionMeta(String sessionId) {
    final metaJson = _prefs.getString('$_keyPrefix${sessionId}_meta');
    if (metaJson == null) return null;
    
    try {
      return jsonDecode(metaJson) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  /// Update session title
  Future<void> updateSessionTitle(String sessionId, String title) async {
    final meta = getSessionMeta(sessionId) ?? {
      'id': sessionId,
      'createdAt': DateTime.now().toIso8601String(),
    };
    
    meta['title'] = title;
    meta['updatedAt'] = DateTime.now().toIso8601String();
    
    await _prefs.setString('$_keyPrefix${sessionId}_meta', jsonEncode(meta));
  }

  /// Get all sessions with metadata
  List<Map<String, dynamic>> getAllSessionsWithMeta() {
    final sessions = getSessionIds();
    return sessions
        .map((id) => getSessionMeta(id))
        .whereType<Map<String, dynamic>>()
        .toList();
  }

  // =========================================================================
  // SERIALIZATION HELPERS
  // =========================================================================

  Map<String, dynamic> _contentToMap(Content content) {
    final parts = content.parts
        .whereType<TextPart>()
        .map((p) => p.text)
        .join('\n');
    
    return {
      'role': content.role ?? 'user',
      'text': parts,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  Content _mapToContent(Map<String, dynamic> map) {
    final role = map['role'] as String? ?? 'user';
    final text = map['text'] as String? ?? '';
    
    if (role == 'model') {
      return Content.model([TextPart(text)]);
    }
    return Content.text(text);
  }
}

/// Convenience extension on GeminiService for session management
extension ChatSessionExtension on List<Content> {
  /// Get a formatted transcript of the conversation
  String toTranscript() {
    return map((content) {
      final role = content.role == 'model' ? 'AI' : 'You';
      final text = content.parts
          .whereType<TextPart>()
          .map((p) => p.text)
          .join('\n');
      return '$role: $text';
    }).join('\n\n');
  }
}
