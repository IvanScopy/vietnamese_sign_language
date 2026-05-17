import 'dart:async';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/models/landmark.dart';
import 'package:permission_handler/permission_handler.dart';

/// Callback type for landmark detection events
typedef LandmarkCallback = void Function(HolisticLandmarksPayload payload);

/// Camera preview widget with integrated MediaPipe Holistic landmark detection.
///
/// Features:
/// - Requests camera permission on initialization
/// - Displays live camera preview
/// - Processes frames through native Android MediaPipe Pose + Hand Landmarker
/// - Extracts 33 pose landmarks + 21 landmarks per hand (both hands)
/// - Throttles processing to target FPS (default 15)
/// - Emits HolisticLandmarksPayload via callback
///
/// Note: This implementation uses native Android MediaPipe Tasks models.
/// The task files are packaged with the app as Android assets.
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

  // Native plugin communication
  static const MethodChannel _methodChannel = MethodChannel(
    'co.vslbridge/mediapipe_holistic/method',
  );
  static const EventChannel _eventChannel = EventChannel(
    'co.vslbridge/mediapipe_holistic/event',
  );

  StreamSubscription? _eventSubscription;
  bool _isPluginInitialized = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  @override
  void didUpdateWidget(CameraPreviewWithMediaPipe oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.lensDirection != widget.lensDirection) {
      _restartCamera();
    }
  }

  Future<void> _initialize() async {
    try {
      // Request camera permission
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Camera permission denied. Please grant camera access to use sign recognition.';
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

      // Initialize native MediaPipe plugin
      final pluginReady = await _initializeNativePlugin();
      if (!pluginReady) {
        return;
      }

      // Start image stream for frame processing
      _startImageStream();

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _hasError = false;
        });
      }
    } catch (e, stackTrace) {
      debugPrint('Camera initialization error: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Failed to initialize camera: $e';
        });
      }
    }
  }

  Future<bool> _initializeNativePlugin() async {
    try {
      // Set up event channel listener
      _eventSubscription = _eventChannel.receiveBroadcastStream().listen(
        _onNativeEvent,
        onError: (error) {
          debugPrint('Native plugin event error: $error');
        },
      );

      // Initialize the plugin with configuration
      await _methodChannel.invokeMethod('initialize', {
        'options': {
          'minDetectionConfidence': widget.config.minDetectionConfidence,
          'minTrackingConfidence': widget.config.minDetectionConfidence,
          'modelComplexity': 1, // 0=Lite, 1=Full
        },
      });

      // Start processing
      await _methodChannel.invokeMethod('start');

      _isPluginInitialized = true;
      debugPrint('Native MediaPipe pose + hand plugin initialized');
      return true;
    } catch (e, stackTrace) {
      debugPrint('Failed to initialize native plugin: $e\n$stackTrace');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Failed to initialize MediaPipe pose and hand detection. Please reinstall the app.';
        });
      }
      return false;
    }
  }

  Future<void> _restartCamera() async {
    setState(() {
      _isInitialized = false;
      _hasError = false;
      _errorMessage = null;
    });

    _lastFrameTime = 0;
    _isPluginInitialized = false;
    await _eventSubscription?.cancel();
    _eventSubscription = null;

    try {
      await _methodChannel.invokeMethod('close');
    } catch (e) {
      debugPrint('Error closing native plugin during camera restart: $e');
    }

    try {
      await _cameraController?.stopImageStream();
    } catch (_) {
      // Some platform camera implementations throw if the stream is not active.
    }
    await _cameraController?.dispose();
    _cameraController = null;

    if (mounted) {
      await _initialize();
    }
  }

  void _onNativeEvent(dynamic event) {
    if (event is! Map) {
      return;
    }

    try {
      final timestamp =
          event['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch;

      PoseLandmarks? poseLandmarks;
      HandLandmarks? leftLandmarks;
      HandLandmarks? rightLandmarks;

      // Extract pose landmarks
      if (event['pose'] != null) {
        final poseData = event['pose'] as Map;
        final landmarksData = poseData['landmarks'] as List?;
        if (landmarksData != null) {
          final landmarks = landmarksData
              .map(
                (lm) => Landmark(
                  x: (lm['x'] as num).toDouble(),
                  y: (lm['y'] as num).toDouble(),
                  z: (lm['z'] as num).toDouble(),
                  visibility: (lm['visibility'] as num?)?.toDouble() ?? 1.0,
                ),
              )
              .toList();

          poseLandmarks = PoseLandmarks(landmarks: landmarks);
        }
      }

      // Extract left hand landmarks
      if (event['left'] != null) {
        final leftData = event['left'] as Map;
        final handedness = leftData['handedness'] as String? ?? 'Left';
        final landmarksData = leftData['landmarks'] as List?;
        if (landmarksData != null) {
          final landmarks = landmarksData
              .map(
                (lm) => Landmark(
                  x: (lm['x'] as num).toDouble(),
                  y: (lm['y'] as num).toDouble(),
                  z: (lm['z'] as num).toDouble(),
                  visibility: (lm['visibility'] as num?)?.toDouble() ?? 1.0,
                ),
              )
              .toList();

          leftLandmarks = HandLandmarks(
            handedness: handedness,
            landmarks: landmarks,
          );
        }
      }

      // Extract right hand landmarks
      if (event['right'] != null) {
        final rightData = event['right'] as Map;
        final handedness = rightData['handedness'] as String? ?? 'Right';
        final landmarksData = rightData['landmarks'] as List?;
        if (landmarksData != null) {
          final landmarks = landmarksData
              .map(
                (lm) => Landmark(
                  x: (lm['x'] as num).toDouble(),
                  y: (lm['y'] as num).toDouble(),
                  z: (lm['z'] as num).toDouble(),
                  visibility: (lm['visibility'] as num?)?.toDouble() ?? 1.0,
                ),
              )
              .toList();

          rightLandmarks = HandLandmarks(
            handedness: handedness,
            landmarks: landmarks,
          );
        }
      }

      final payload = HolisticLandmarksPayload(
        pose: poseLandmarks,
        left: leftLandmarks,
        right: rightLandmarks,
        timestamp: timestamp,
        sessionId: '', // Will be set by higher-level service
      );

      widget.onLandmarks?.call(payload);
    } catch (e) {
      debugPrint('Error parsing native event: $e');
    }
  }

  void _startImageStream() {
    final controller = _cameraController;
    if (controller == null || !controller.value.isInitialized) {
      return;
    }

    final frameInterval = 1000 ~/ widget.targetFps;

    controller.startImageStream((CameraImage image) {
      final now = DateTime.now().millisecondsSinceEpoch;

      // Throttle to target FPS
      if (now - _lastFrameTime < frameInterval) {
        return;
      }
      _lastFrameTime = now;

      if (widget.enableLandmarkDetection &&
          widget.onLandmarks != null &&
          _isPluginInitialized) {
        // Process frame asynchronously without awaiting
        _processFrame(image, now);
      }
    });
  }

  Future<void> _processFrame(CameraImage image, int timestamp) async {
    if (!_isPluginInitialized) {
      return;
    }

    try {
      // Convert YUV to RGB
      final rgbBytes = await _convertYUVToRGB(image);

      // Send to native plugin for processing
      await _methodChannel.invokeMethod('processImage', {
        'imageData': rgbBytes,
        'width': image.width,
        'height': image.height,
        'timestamp': timestamp,
      });
    } catch (e) {
      debugPrint('Error processing frame: $e');
    }
  }

  Future<Uint8List> _convertYUVToRGB(CameraImage image) async {
    // YUV420 to RGB conversion
    final yPlane = image.planes[0];
    final uPlane = image.planes[1];
    final vPlane = image.planes[2];

    final yBuffer = yPlane.bytes;
    final uBuffer = uPlane.bytes;
    final vBuffer = vPlane.bytes;

    final width = image.width;
    final height = image.height;

    // Allocate RGB buffer (4 bytes per pixel for RGBA)
    final rgbBuffer = Uint8List(width * height * 4);

    int rgbIndex = 0;
    int yIndex = 0;

    // YUV420: chroma subsampled by 2 both horizontally and vertically
    for (int j = 0; j < height; j++) {
      for (int i = 0; i < width; i++) {
        final y = yBuffer[yIndex++] & 0xff;

        // Get corresponding U and V values (subsampled)
        final uvIndex = ((j ~/ 2) * (width ~/ 2)) + (i ~/ 2);
        final v = vBuffer[uvIndex] & 0xff;
        final u = uBuffer[uvIndex] & 0xff;

        // Convert YUV to RGB using standard conversion
        final int r = (y + 1.370705 * (v - 128)).clamp(0, 255).toInt();
        final int g = (y - 0.337633 * (u - 128) - 0.698001 * (v - 128))
            .clamp(0, 255)
            .toInt();
        final int b = (y + 1.732446 * (u - 128)).clamp(0, 255).toInt();

        // RGBA format
        rgbBuffer[rgbIndex++] = r;
        rgbBuffer[rgbIndex++] = g;
        rgbBuffer[rgbIndex++] = b;
        rgbBuffer[rgbIndex++] = 255; // Alpha
      }
    }

    return rgbBuffer;
  }

  @override
  void dispose() {
    _eventSubscription?.cancel();
    _methodChannel.invokeMethod('close').catchError((e) {
      debugPrint('Error closing native plugin: $e');
    });
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
    return Center(child: CameraPreview(_cameraController!));
  }
}
