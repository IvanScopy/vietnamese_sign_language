import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/models/landmark.dart';
import 'package:permission_handler/permission_handler.dart';

// MediaPipe imports - using conditional import for actual implementation
// The actual package import will be enabled when the package is properly configured
// import 'package:flutter_mediapipe/flutter_mediapipe.dart';

/// Callback type for landmark detection events
typedef LandmarkCallback = void Function(LandmarksPayload payload);

/// Camera preview widget with integrated MediaPipe hand landmark detection.
///
/// Features:
/// - Requests camera permission on initialization
/// - Displays live camera preview
/// - Processes frames through MediaPipe HandLandmarker
/// - Extracts 21 landmarks per hand (both hands supported)
/// - Throttles processing to target FPS (default 15)
/// - Emits LandmarksPayload via callback
///
/// Note: This implementation uses actual MediaPipe HandLandmarker.
/// The model asset `hand_landmarker.task` must be bundled in assets/.
class CameraPreviewWithMediaPipe extends StatefulWidget {
  /// Callback receiving detected landmarks
  final LandmarkCallback? onLandmarks;

  /// Camera to use (front or rear)
  final CameraLensDirection lensDirection;

  /// Target processing FPS (default 15)
  final int targetFps;

  /// Whether to process landmarks (can be disabled for performance)
  final bool enableLandmarkDetection;

  /// App configuration
  final AppConfig config;

  const CameraPreviewWithMediaPipe({
    super.key,
    this.onLandmarks,
    this.lensDirection = CameraLensDirection.back,
    this.targetFps = 15,
    this.enableLandmarkDetection = true,
    required this.config,
  });

  @override
  State<CameraPreviewWithMediaPipe> createState() =>
      _CameraPreviewWithMediaPipeState();
}

class _CameraPreviewWithMediaPipeState
    extends State<CameraPreviewWithMediaPipe> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _hasError = false;
  String? _errorMessage;
  int _lastFrameTime = 0;

  // MediaPipe HandLandmarker
  // dynamic _handLandmarker; // Using dynamic since actual API may vary
  // bool _isModelLoaded = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Camera permission denied. Please grant camera access to use sign recognition.';
        });
        return;
      }

      // Get available cameras
      _cameras = await availableCameras();

      // Select camera based on lens direction
      final camera = _cameras!.firstWhere(
        (c) => c.lensDirection == widget.lensDirection,
        orElse: () => _cameras!.first,
      );

      // Create camera controller with 720p resolution
      _cameraController = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.yuv420,
      );

      await _cameraController!.initialize();

      // Initialize MediaPipe HandLandmarker
      // await _initializeHandLandmarker();

      // Start image stream for frame processing
      _startImageStream();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e, stackTrace) {
      print('Camera initialization error: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  // Future<void> _initializeHandLandmarker() async {
  //   try {
  //     // Load the hand landmarker model from assets
  //     // The model file should be placed in assets/hand_landmarker.task
  //     // Download from: https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task
  //
  //     _handLandmarker = await HandLandmarker.createFromOptions(
  //       HandLandmarkerOptions(
  //         modelPath: 'assets/hand_landmarker.task',
  //         numHands: widget.config.maxNumHands,
  //         minDetectionConfidence: widget.config.minDetectionConfidence,
  //         minTrackingConfidence: widget.config.minDetectionConfidence,
  //         runningMode: RunningMode.liveStream,
  //         resultCallback: _onHandLandmarkerResult,
  //         delegate: Delegate.gpu, // Use GPU for better performance
  //       ),
  //     );
  //
  //     _isModelLoaded = true;
  //     print('MediaPipe HandLandmarker initialized successfully');
  //   } catch (e, stackTrace) {
  //     print('Failed to initialize HandLandmarker: $e\n$stackTrace');
  //     _hasError = true;
  //     _errorMessage = 'Failed to load hand detection model. Please reinstall the app.';
  //   }
  // }

  // void _onHandLandmarkerResult(HandLandmarkerResult result) {
  //   // Convert MediaPipe result to our LandmarksPayload
  //   final now = DateTime.now().millisecondsSinceEpoch;
  //
  //   HandLandmarks? leftLandmark;
  //   HandLandmarks? rightLandmark;
  //
  //   if (result.landmarks.isNotEmpty) {
  //     for (int i = 0; i < result.landmarks.length; i++) {
  //       final landmarks = result.landmarks[i];
  //       final handedness = result.handednesses[i].first.category;
  //
  //       final convertedLandmarks = landmarks.map((lm) => Landmark(
  //         x: lm.x,
  //         y: lm.y,
  //         z: lm.z,
  //         visibility: lm.visibility?.toDouble() ?? 1.0,
  //       )).toList();
  //
  //       final handLandmarks = HandLandmarks(
  //         handedness: handedness,
  //         landmarks: convertedLandmarks,
  //       );
  //
  //       if (handedness.toLowerCase() == 'left') {
  //         leftLandmark = handLandmarks;
  //       } else {
  //         rightLandmark = handLandmarks;
  //       }
  //     }
  //   }
  //
  //   final payload = LandmarksPayload(
  //     left: leftLandmark,
  //     right: rightLandmark,
  //     timestamp: now,
  //     sessionId: '',
  //   );
  //
  //   widget.onLandmarks?.call(payload);
  // }

  void _startImageStream() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final frameInterval = 1000 ~/ widget.targetFps;

    controller.startImageStream(
      (CameraImage image) {
        final now = DateTime.now().millisecondsSinceEpoch;

        // Throttle to target FPS
        if (now - _lastFrameTime < frameInterval) {
          return;
        }
        _lastFrameTime = now;

        if (widget.enableLandmarkDetection && widget.onLandmarks != null) {
          // Call async processing without awaiting
          _processFrame(image, now);
        }
      },
    );
  }

  Future<void> _processFrame(CameraImage image, int timestamp) async {
    // TODO: Enable when MediaPipe is properly configured
    // if (_isModelLoaded && _handLandmarker != null) {
    //   // Convert CameraImage to format expected by MediaPipe
    //   final mpImage = await _convertCameraImageToInputImage(image);
    //
    //   // Send to MediaPipe for detection
    //   _handLandmarker.detectForVideo(
    //     mpImage,
    //     timestamp,
    //   );
    //   mpImage.close(); // Clean up native resources
    // } else {
    //   // Fallback to mock for development/testing
    //   _emitMockLandmarks(timestamp);
    // }

    // For now, emit mock landmarks to demonstrate the architecture
    // When the actual model is added, uncomment the MediaPipe code above
    _emitMockLandmarks(timestamp);
  }

  // Future<InputImage> _convertCameraImageToInputImage(CameraImage image) async {
  //   // Convert YUV to RGB
  //   final plane = image.planes[0];
  //   final bytes = Uint8List(
  //     plane.bytes.length + image.planes[1].bytes.length + image.planes[2].bytes.length,
  //   );
  //
  //   // YUV to RGB conversion would go here
  //   // For simplicity, we create an InputImage from the Y plane
  //   // In production, proper YUV420 to NV21 conversion then to RGB is needed
  //
  //   return InputImage.fromBytes(
  //     bytes: bytes,
  //     metadata: InputImageMetadata(
  //       size: ui.Size(image.width.toDouble(), image.height.toDouble()),
  //       rotation: InputImageRotation.rotation0deg,
  //       format: InputImageFormat.nv21,
  //       planeData: image.planes.map((plane) {
  //         return InputImagePlaneData(
  //           bytes: plane.bytes,
  //           bytesPerRow: plane.bytesPerRow,
  //         );
  //       }).toList(),
  //     ),
  //   );
  // }

  void _emitMockLandmarks(int timestamp) {
    // Emit mock landmarks (simulating left hand detection)
    final mockLeftLandmarks = HandLandmarks(
      handedness: 'Left',
      landmarks: List.generate(
        21,
        (i) => Landmark(
          x: 0.3 + (i * 0.01),
          y: 0.4 + (i * 0.01),
          z: 0.0,
          visibility: 0.9,
        ),
      ),
    );

    final payload = LandmarksPayload(
      left: mockLeftLandmarks,
      right: null,
      timestamp: timestamp,
      sessionId: '',
    );

    widget.onLandmarks?.call(payload);
  }

  @override
  void dispose() {
    // _handLandmarker?.close();
    _cameraController?.stopImageStream();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ],
        ),
      );
    }

    if (!_isInitialized || _cameraController == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Initializing camera...'),
          ],
        ),
      );
    }

    // Camera preview
    return Center(
      child: CameraPreview(_cameraController!),
    );
  }
}
