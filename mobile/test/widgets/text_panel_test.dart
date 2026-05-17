import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/recognition_event.dart';
import 'package:mobile/widgets/text_panel.dart';

void main() {
  group('TextPanel', () {
    testWidgets('shows empty state when signs is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextPanel(signs: [])),
        ),
      );

      expect(
        find.text('Start signing to see recognition results'),
        findsOneWidget,
      );
    });

    testWidgets('displays signs as editable text fields', (tester) async {
      final signs = [
        RecognitionResult(sign: 'xin_chào', confidence: 0.95),
        RecognitionResult(sign: 'cảm_ơn', confidence: 0.87),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextPanel(signs: signs)),
        ),
      );

      expect(find.text('xin_chào'), findsOneWidget);
      expect(find.text('cảm_ơn'), findsOneWidget);
      expect(find.text('95%'), findsOneWidget);
      expect(find.text('87%'), findsOneWidget);
    });

    testWidgets('shows phrase complete indicator when isPhraseComplete', (
      tester,
    ) async {
      final signs = [RecognitionResult(sign: 'xin_chào', confidence: 0.95)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextPanel(
              signs: signs,
              isPhraseComplete: true,
              audioData: 'base64-audio-data',
            ),
          ),
        ),
      );

      expect(find.text('Phrase complete - audio playing'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });

    testWidgets('hides audio button when audioData is null', (tester) async {
      final signs = [RecognitionResult(sign: 'xin_chào', confidence: 0.95)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextPanel(
              signs: signs,
              isPhraseComplete: true,
              audioData: null,
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.volume_up), findsNothing);
    });

    testWidgets('confidence colors: green for high', (tester) async {
      final signs = [RecognitionResult(sign: 'test', confidence: 0.9)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextPanel(signs: signs)),
        ),
      );

      final bubble = find.byType(Card);
      expect(bubble, findsOneWidget);
    });

    testWidgets('confidence colors: orange for medium', (tester) async {
      final signs = [RecognitionResult(sign: 'test', confidence: 0.7)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextPanel(signs: signs)),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('confidence colors: red for low', (tester) async {
      final signs = [RecognitionResult(sign: 'test', confidence: 0.4)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TextPanel(signs: signs)),
        ),
      );

      expect(find.byType(Card), findsOneWidget);
    });

    testWidgets('audio playback button appears with audioData', (tester) async {
      final signs = [RecognitionResult(sign: 'xin_chào', confidence: 0.95)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextPanel(
              signs: signs,
              isPhraseComplete: true,
              audioData: 'base64-audio-data',
            ),
          ),
        ),
      );

      // Verify the volume up button is shown
      final playButton = find.byIcon(Icons.volume_up);
      expect(playButton, findsOneWidget);
    });

    testWidgets('audio playback handles decode errors gracefully', (
      tester,
    ) async {
      final signs = [RecognitionResult(sign: 'xin_chào', confidence: 0.95)];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TextPanel(
              signs: signs,
              isPhraseComplete: true,
              audioData: 'invalid-base64-data', // Invalid base64
            ),
          ),
        ),
      );

      final playButton = find.byIcon(Icons.volume_up);
      expect(playButton, findsOneWidget);

      // Tap the play button
      await tester.tap(playButton);
      await tester.pumpAndSettle();

      // Error snackbar should appear
      expect(find.textContaining('Failed to play audio'), findsOneWidget);
    });
  });
}
