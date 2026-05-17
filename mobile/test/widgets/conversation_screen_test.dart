import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/screens/conversation_screen.dart';
import 'package:mobile/services/conversation_history_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('ConversationScreen', () {
    late ConversationHistoryService historyService;
    late AppConfig config;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      historyService = ConversationHistoryService(preferences);
      config = AppConfig.create(
        environment: 'test',
        serverUrl: 'localhost',
        serverPort: 8000,
      );
    });

    testWidgets('confirms signer and speaker messages into both timelines', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationScreen(
            config: config,
            authToken: 'token',
            historyService: historyService,
            autoConnect: false,
            enableCamera: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'xin chào');
      await tester.ensureVisible(
        find.byKey(const ValueKey('confirm_draft_button')),
      );
      await tester.tap(find.byKey(const ValueKey('confirm_draft_button')));
      await tester.pumpAndSettle();

      expect(find.text('xin chào'), findsNWidgets(2));

      await tester.tap(find.text('Speak').first);
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'chào bạn');
      await tester.ensureVisible(
        find.byKey(const ValueKey('confirm_draft_button')),
      );
      await tester.tap(find.byKey(const ValueKey('confirm_draft_button')));
      await tester.pumpAndSettle();

      expect(find.text('chào bạn'), findsNWidgets(2));

      final sessions = await historyService.loadSessions();
      expect(sessions, hasLength(1));
      expect(sessions.first.confirmedMessages, hasLength(2));
    });

    testWidgets('opens history from the app bar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConversationScreen(
            config: config,
            authToken: 'token',
            historyService: historyService,
            autoConnect: false,
            enableCamera: false,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.history));
      await tester.pumpAndSettle();

      expect(find.text('History'), findsOneWidget);
    });
  });
}
