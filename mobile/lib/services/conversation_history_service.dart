import 'dart:convert';

import 'package:mobile/models/conversation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConversationHistoryService {
  static const String _storageKey = 'vsl_bridge_conversation_history_v1';

  final SharedPreferences _preferences;

  ConversationHistoryService(this._preferences);

  static Future<ConversationHistoryService> create() async {
    final preferences = await SharedPreferences.getInstance();
    return ConversationHistoryService(preferences);
  }

  Future<List<ConversationSession>> loadSessions() async {
    final raw = _preferences.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return [];
      }

      final sessions = decoded
          .whereType<Map>()
          .map(
            (session) => ConversationSession.fromJson(
              Map<String, dynamic>.from(session),
            ),
          )
          .where((session) => session.hasConfirmedMessages)
          .toList();

      sessions.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return sessions;
    } catch (_) {
      return [];
    }
  }

  Future<void> saveSession(ConversationSession session) async {
    final confirmedOnly = session.confirmedMessages;
    if (confirmedOnly.isEmpty) {
      return;
    }

    final sanitized = session.copyWith(
      endedAt: session.endedAt ?? DateTime.now(),
      messages: confirmedOnly,
    );

    final sessions = await loadSessions();
    final withoutExisting = sessions
        .where((existing) => existing.id != sanitized.id)
        .toList();

    withoutExisting.add(sanitized);
    withoutExisting.sort((a, b) => b.startedAt.compareTo(a.startedAt));

    await _preferences.setString(
      _storageKey,
      jsonEncode(withoutExisting.map((item) => item.toJson()).toList()),
    );
  }

  Future<List<ConversationSession>> searchSessions(String query) async {
    final normalized = query.trim().toLowerCase();
    final sessions = await loadSessions();

    if (normalized.isEmpty) {
      return sessions;
    }

    return sessions.where((session) {
      return session.confirmedMessages.any(
        (message) => message.text.toLowerCase().contains(normalized),
      );
    }).toList();
  }

  Future<void> clear() async {
    await _preferences.remove(_storageKey);
  }

  String formatSessionAsPlainText(ConversationSession session) {
    final buffer = StringBuffer();
    buffer.writeln('Conversation ${_formatTimestamp(session.startedAt)}');

    for (final message in session.confirmedMessages) {
      final time = _formatTimestamp(message.timestamp);
      buffer.writeln('[$time] ${message.role.label}: ${message.text.trim()}');
    }

    return buffer.toString().trimRight();
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    String two(int number) => number.toString().padLeft(2, '0');

    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }
}
