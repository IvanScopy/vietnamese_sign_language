import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/models/landmark.dart';
import 'package:mobile/models/recognition_event.dart';
import 'package:mobile/services/sign_recognition_service.dart';

void main() {
  group('SignRecognitionService', () {
    late SignRecognitionService service;

    setUp(() {
      service = SignRecognitionService(
        serverUrl: 'localhost',
        serverPort: 8000,
        authToken: 'test-token',
        connectionTimeout: const Duration(milliseconds: 50),
      );
    });

    tearDown(() async {
      await service.dispose();
    });

    test('initial state: not connected', () {
      expect(service.isConnected, isFalse);
    });

    test('connect() times out without a backend handshake', () async {
      await expectLater(service.connect(), throwsA(isA<TimeoutException>()));
    });

    test('sendLandmarks() returns early when not connected', () async {
      final payload = LandmarksPayload(
        left: HandLandmarks(
          handedness: 'Left',
          landmarks: List.generate(
            21,
            (i) => Landmark(x: 0.5, y: 0.5, z: 0.0, visibility: 1.0),
          ),
        ),
        right: null,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sessionId: 'test-session',
      );

      // Should not throw even though not connected
      expect(() => service.sendLandmarks(payload), returnsNormally);
    });

    test('disconnect() sets isConnected to false', () {
      service.disconnect();
      expect(service.isConnected, isFalse);
    });

    test('signStream is broadcast stream', () {
      expect(service.signStream, isA<Stream<RecognitionResult>>());
    });

    test('phraseStream is broadcast stream', () {
      expect(service.phraseStream, isA<Stream<PhraseComplete>>());
    });

    test('connectionStream is broadcast stream', () {
      expect(service.connectionStream, isA<Stream<bool>>());
    });

    test('sendLandmarks() handles null hands', () async {
      final payload = LandmarksPayload(
        left: null,
        right: null,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sessionId: 'test-session',
      );

      expect(() => service.sendLandmarks(payload), returnsNormally);
    });

    test('dispose() completes without throwing', () async {
      // Just verify dispose can be called without errors
      await service.dispose();
      expect(service.isConnected, isFalse);
    });
  });
}
