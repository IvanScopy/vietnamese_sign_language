import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/conversation.dart';
import 'package:mobile/services/conversation_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ConversationHistoryService', () {
    late ConversationHistoryService service;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      service = ConversationHistoryService(preferences);
    });

    test('saveSession stores only confirmed text messages', () async {
      final session = ConversationSession(
        id: 'session-1',
        startedAt: DateTime(2026, 5, 16, 9),
        messages: [
          ConversationMessage(
            id: 'message-1',
            role: ConversationRole.signer,
            source: ConversationMessageSource.recognition,
            status: ConversationMessageStatus.confirmed,
            text: 'xin chào',
            timestamp: DateTime(2026, 5, 16, 9, 1),
            confidence: 0.91,
          ),
          ConversationMessage(
            id: 'message-2',
            role: ConversationRole.speaker,
            source: ConversationMessageSource.manual,
            status: ConversationMessageStatus.draft,
            text: 'draft only',
            timestamp: DateTime(2026, 5, 16, 9, 2),
          ),
        ],
      );

      await service.saveSession(session);
      final sessions = await service.loadSessions();

      expect(sessions, hasLength(1));
      expect(sessions.first.confirmedMessages, hasLength(1));
      expect(sessions.first.confirmedMessages.first.text, 'xin chào');
    });

    test('searchSessions matches confirmed transcript text', () async {
      await service.saveSession(
        ConversationSession(
          id: 'session-1',
          startedAt: DateTime(2026, 5, 16, 9),
          messages: [
            ConversationMessage(
              id: 'message-1',
              role: ConversationRole.signer,
              source: ConversationMessageSource.manual,
              status: ConversationMessageStatus.confirmed,
              text: 'cảm ơn',
              timestamp: DateTime(2026, 5, 16, 9, 1),
            ),
          ],
        ),
      );

      await service.saveSession(
        ConversationSession(
          id: 'session-2',
          startedAt: DateTime(2026, 5, 16, 10),
          messages: [
            ConversationMessage(
              id: 'message-2',
              role: ConversationRole.speaker,
              source: ConversationMessageSource.manual,
              status: ConversationMessageStatus.confirmed,
              text: 'hẹn gặp lại',
              timestamp: DateTime(2026, 5, 16, 10, 1),
            ),
          ],
        ),
      );

      final results = await service.searchSessions('cảm');

      expect(results, hasLength(1));
      expect(results.first.id, 'session-1');
    });

    test('formatSessionAsPlainText includes timestamp, role, and text', () {
      final session = ConversationSession(
        id: 'session-1',
        startedAt: DateTime(2026, 5, 16, 9),
        messages: [
          ConversationMessage(
            id: 'message-1',
            role: ConversationRole.signer,
            source: ConversationMessageSource.manual,
            status: ConversationMessageStatus.confirmed,
            text: 'xin chào',
            timestamp: DateTime(2026, 5, 16, 9, 1),
          ),
        ],
      );

      final output = service.formatSessionAsPlainText(session);

      expect(output, contains('Conversation 2026-05-16 09:00'));
      expect(output, contains('[2026-05-16 09:01] Signer: xin chào'));
    });
  });
}
