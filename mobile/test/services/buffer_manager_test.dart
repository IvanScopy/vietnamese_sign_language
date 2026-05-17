import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/landmark.dart';
import 'package:mobile/models/recognition_event.dart';
import 'package:mobile/services/buffer_manager.dart';

void main() {
  group('BufferManager', () {
    late BufferManager bufferManager;

    setUp(() {
      bufferManager = BufferManager(
        windowSize: 3,
        phraseTimeoutMs: 50,
      );
    });

    tearDown(() async {
      await bufferManager.dispose();
    });

    test('bufferFill starts at 0', () {
      expect(bufferManager.bufferFill, 0);
    });

    test('bufferFill increments with each frame', () {
      bufferManager.addLandmarks(createMockLandmarks());
      expect(bufferManager.bufferFill, 1);

      bufferManager.addLandmarks(createMockLandmarks());
      expect(bufferManager.bufferFill, 2);

      bufferManager.addLandmarks(createMockLandmarks());
      expect(bufferManager.bufferFill, 3);
    });

    test('isReady false until windowSize reached', () {
      expect(bufferManager.isReady, isFalse);
      bufferManager.addLandmarks(createMockLandmarks());
      expect(bufferManager.isReady, isFalse);
      bufferManager.addLandmarks(createMockLandmarks());
      expect(bufferManager.isReady, isFalse);
    });

    test('isReady true when buffer reaches windowSize', () {
      bufferManager.addLandmarks(createMockLandmarks());
      bufferManager.addLandmarks(createMockLandmarks());
      bufferManager.addLandmarks(createMockLandmarks());
      expect(bufferManager.isReady, isTrue);
    });

    test('signStream emits when buffer reaches windowSize', () async {
      final resultCompleter = Completer<RecognitionResult>();

      bufferManager.signStream.listen((result) {
        if (!resultCompleter.isCompleted) {
          resultCompleter.complete(result);
        }
      });

      bufferManager.addLandmarks(createMockLandmarks());
      bufferManager.addLandmarks(createMockLandmarks());
      expect(resultCompleter.isCompleted, isFalse);

      bufferManager.addLandmarks(createMockLandmarks());

      final result = await resultCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TestFailure('No sign emitted'),
      );

      expect(result, isA<RecognitionResult>());
      expect(result.sign, equals('placeholder_sign'));
      expect(result.confidence, equals(0.85));
    });

    test('phraseLength increases with each sign', () {
      expect(bufferManager.phraseLength, 0);

      // First sign after 3 frames
      for (int i = 0; i < 3; i++) {
        bufferManager.addLandmarks(createMockLandmarks());
      }
      expect(bufferManager.phraseLength, 1);

      // Add 3 more frames: frames 4,5,6
      // Frame 4: buffer=[f1,f2,f3,f4] -> emit (window f2,f3,f4 conceptually)
      // Frame 5: emit (window f3,f4,f5)
      // Frame 6: emit (window f4,f5,f6) -> 3 more emissions = total 4
      // Actually: after initial 3, each additional frame emits once
      for (int i = 0; i < 3; i++) {
        bufferManager.addLandmarks(createMockLandmarks());
      }
      // 3 additional frames after initial window = 3 more emissions
      expect(bufferManager.phraseLength, 4);
    });

    test('phraseStream emits after timeout', () async {
      final phraseCompleter = Completer<PhraseComplete>();

      bufferManager.phraseStream.listen((phrase) {
        if (!phraseCompleter.isCompleted) {
          phraseCompleter.complete(phrase);
        }
      });

      // Trigger first sign
      for (int i = 0; i < 3; i++) {
        bufferManager.addLandmarks(createMockLandmarks());
      }

      // Wait for timeout
      await phraseCompleter.future.timeout(
        const Duration(seconds: 1),
        onTimeout: () => throw TestFailure('PhraseComplete not emitted'),
      );

      expect(phraseCompleter.isCompleted, isTrue);
    });

    test('clear resets all state', () {
      // Build up some state
      for (int i = 0; i < 3; i++) {
        bufferManager.addLandmarks(createMockLandmarks());
      }
      expect(bufferManager.bufferFill, greaterThan(0));
      expect(bufferManager.phraseLength, 1);

      bufferManager.clear();

      expect(bufferManager.bufferFill, 0);
      expect(bufferManager.phraseLength, 0);
      expect(bufferManager.isReady, isFalse);
    });

    test('clear cancels phrase timer', () async {
      final phraseCompleter = Completer<PhraseComplete>();
      bufferManager.phraseStream.listen((phrase) {
        if (!phraseCompleter.isCompleted) {
          phraseCompleter.complete(phrase);
        }
      });

      // Trigger sign
      for (int i = 0; i < 3; i++) {
        bufferManager.addLandmarks(createMockLandmarks());
      }

      // Clear before timeout
      await Future.delayed(const Duration(milliseconds: 10));
      bufferManager.clear();

      // Wait past timeout
      await Future.delayed(const Duration(milliseconds: 100));

      // Should NOT have emitted because timer was cancelled
      expect(phraseCompleter.isCompleted, isFalse);
    });

    test('phrase timer resets with new sign', () async {
      final phraseCompleter = Completer<PhraseComplete>();
      bufferManager.phraseStream.listen((phrase) {
        if (!phraseCompleter.isCompleted) {
          phraseCompleter.complete(phrase);
        }
      });

      // First sign
      for (int i = 0; i < 3; i++) {
        bufferManager.addLandmarks(createMockLandmarks());
      }

      // Wait partial timeout
      await Future.delayed(const Duration(milliseconds: 30));

      // Second sign (resets timer)
      for (int i = 0; i < 3; i++) {
        bufferManager.addLandmarks(createMockLandmarks());
      }

      // Wait less than full timeout from second sign
      await Future.delayed(const Duration(milliseconds: 30));

      // Should NOT have emitted yet
      expect(phraseCompleter.isCompleted, isFalse);

      // Wait for remaining timeout
      await Future.delayed(const Duration(milliseconds: 30));

      // Now should have emitted
      expect(phraseCompleter.isCompleted, isTrue);
    });
  });
}

/// Create mock landmarks payload for testing
LandmarksPayload createMockLandmarks() {
  final now = DateTime.now().millisecondsSinceEpoch;
  final leftLandmarks = HandLandmarks(
    handedness: 'Left',
    landmarks: List.generate(
      21,
      (i) => Landmark(
        x: 0.5 + (i * 0.001),
        y: 0.5 + (i * 0.001),
        z: 0.0,
        visibility: 1.0,
      ),
    ),
  );

  return LandmarksPayload(
    left: leftLandmarks,
    right: null,
    timestamp: now,
    sessionId: 'test-session-${now % 1000}',
  );
}
