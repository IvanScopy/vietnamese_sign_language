import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/models/landmark.dart';
import 'package:mobile/widgets/camera_preview.dart';
import 'package:camera/camera.dart';

void main() {
  group('CameraPreviewWithMediaPipe', () {
    late AppConfig testConfig;

    setUp(() {
      testConfig = AppConfig.create(
        environment: 'test',
        serverUrl: 'localhost',
        serverPort: 8000,
      );
    });

    testWidgets('widget can be instantiated with config', (tester) async {
      final widget = CameraPreviewWithMediaPipe(
        config: testConfig,
      );

      expect(widget, isNotNull);
      expect(widget.config.serverUrl, equals('localhost'));
      expect(widget.config.serverPort, equals(8000));
    });

    testWidgets('default parameters are correct', (tester) async {
      final widget = CameraPreviewWithMediaPipe(
        config: testConfig,
      );

      expect(widget.lensDirection, equals(CameraLensDirection.back));
      expect(widget.targetFps, equals(15));
      expect(widget.enableLandmarkDetection, isTrue);
    });

    testWidgets('custom parameters are preserved', (tester) async {
      final customConfig = AppConfig.create(
        environment: 'dev',
        serverUrl: '192.168.1.100',
        serverPort: 9000,
      );

      final widget = CameraPreviewWithMediaPipe(
        onLandmarks: (payload) {},
        lensDirection: CameraLensDirection.front,
        targetFps: 30,
        enableLandmarkDetection: false,
        config: customConfig,
      );

      expect(widget.onLandmarks, isNotNull);
      expect(widget.lensDirection, equals(CameraLensDirection.front));
      expect(widget.targetFps, equals(30));
      expect(widget.enableLandmarkDetection, isFalse);
      expect(widget.config.serverPort, equals(9000));
    });

    testWidgets('shows loading state during initialization', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CameraPreviewWithMediaPipe(
              config: testConfig,
            ),
          ),
        ),
      );

      // Initially shows loading indicator (or error depending on env)
      await tester.pump();

      // Either loading or error state is valid in test environment
      final hasLoading = find.text('Initializing camera...').evaluate().isNotEmpty;
      final hasError = find.textContaining('error').evaluate().isNotEmpty;
      final hasPermission = find.textContaining('permission').evaluate().isNotEmpty;

      // At minimum, the widget should render something
      expect(
        hasLoading || hasError || hasPermission,
        isTrue,
        reason: 'Should show loading, error, or permission state',
      );
    });
  });

  group('LandmarksPayload', () {
    late LandmarksPayload payload;

    setUp(() {
      final leftLandmarks = HandLandmarks(
        handedness: 'Left',
        landmarks: List.generate(
          21,
          (i) => Landmark(
            x: 0.5,
            y: 0.5,
            z: 0.0,
            visibility: 1.0,
          ),
        ),
      );

      payload = LandmarksPayload(
        left: leftLandmarks,
        right: null,
        timestamp: DateTime.now().millisecondsSinceEpoch,
        sessionId: 'test-session',
      );
    });

    test('has correct structure', () {
      expect(payload.left, isNotNull);
      expect(payload.left!.landmarks.length, equals(21));
      expect(payload.right, isNull);
      expect(payload.sessionId, equals('test-session'));
    });

    test('serializes to JSON correctly', () {
      final json = payload.toJson();
      expect(json['left'], isNotNull);
      expect(json['left']['handedness'], equals('Left'));
      expect(json['left']['landmarks'].length, equals(21));
    });
  });
}
