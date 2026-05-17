import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/widgets/app_shell.dart';

void main() {
  group('VslAppShell', () {
    testWidgets('shows exactly four top-level tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VslAppShell(
            authToken: 'token',
            sessionState: VslSessionState.authenticated,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Communicate'), findsOneWidget);
      expect(find.text('Dictionary'), findsOneWidget);
      expect(find.text('SOS'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('History'), findsNothing);

      final navLabels = ['Communicate', 'Dictionary', 'SOS', 'Profile']
          .where((label) => find.text(label).evaluate().isNotEmpty)
          .toList();
      expect(navLabels, equals(['Communicate', 'Dictionary', 'SOS', 'Profile']));
    });

    testWidgets('keeps SOS as a top-level accessible destination', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VslAppShell(
            authToken: 'token',
            sessionState: VslSessionState.authenticated,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel(RegExp(r'SOS|emergency', caseSensitive: false)), findsWidgets);
      await tester.tap(find.text('SOS'));
      await tester.pumpAndSettle();

      expect(find.textContaining('SOS'), findsWidgets);
      expect(find.text('History'), findsNothing);
    });

    testWidgets('makes history reachable from Communicate or Profile, not a fifth tab', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VslAppShell(
            authToken: 'token',
            sessionState: VslSessionState.authenticated,
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Communicate'));
      await tester.pumpAndSettle();
      final communicateHasHistory = find.text('History').evaluate().isNotEmpty;

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();
      final profileHasHistory = find.text('History').evaluate().isNotEmpty;

      expect(communicateHasHistory || profileHasHistory, isTrue);
      expect(find.byType(NavigationDestination), findsNWidgets(4));
    });

    testWidgets('exposes semantic labels for shell controls', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VslAppShell(
            authToken: 'token',
            sessionState: VslSessionState.authenticated,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'Communicate|Dictionary|SOS|Profile')),
        findsWidgets,
      );
    });

    testWidgets('shows session-expired copy and login recovery action', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: VslAppShell(
            authToken: '',
            sessionState: VslSessionState.expired,
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(
        find.text('Your session expired. Log in again to continue.'),
        findsOneWidget,
      );
      expect(find.textContaining('Log in'), findsWidgets);
    });
  });
}
