import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/models/landmark.dart';
import 'package:mobile/models/recognition_event.dart';
import 'package:mobile/services/buffer_manager.dart';
import 'package:mobile/services/sign_recognition_service.dart';
import 'package:mobile/widgets/camera_preview.dart';
import 'package:mobile/widgets/text_panel.dart';

/// Main screen for sign language recognition.
///
/// Displays a split view with camera preview on the left and recognized
/// text panel on the right. Manages the recognition pipeline from camera
/// through buffer to backend service.
class RecognitionScreen extends StatefulWidget {
  /// Recognition service host
  final String serverUrl;

  /// Recognition service port
  final int serverPort;

  /// JWT auth token
  final String authToken;

  /// App configuration
  final AppConfig config;

  const RecognitionScreen({
    super.key,
    required this.serverUrl,
    required this.serverPort,
    required this.authToken,
    required this.config,
  });

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  late SignRecognitionService _recognitionService;
  late BufferManager _bufferManager;

  /// Current accumulated signs in the phrase
  final List<RecognitionResult> _currentSigns = [];

  /// Latest phrase completion (cleared after acknowledgment)
  PhraseComplete? _lastPhrase;

  /// Connection status
  bool _isConnected = false;

  /// Camera lens direction
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  /// Error message (if any)
  String? _errorMessage;

  /// Latency measurement (round-trip time in ms)
  int? _lastLatencyMs;

  /// Average latency over last N measurements
  final List<int> _latencySamples = [];
  static const int _maxLatencySamples = 20;

  @override
  void initState() {
    super.initState();

    // Initialize buffer manager with 30-frame window and 2.5s phrase timeout
    _bufferManager = BufferManager(
      windowSize: 30,
      phraseTimeoutMs: 2500,
    );

    // Initialize recognition service
    _recognitionService = SignRecognitionService(
      serverUrl: widget.serverUrl,
      serverPort: widget.serverPort,
      authToken: widget.authToken,
    );

    // Set up stream listeners
    _setupListeners();

    // Connect to service
    _connect();
  }

  void _setupListeners() {
    // Listen for sign recognition from buffer manager
    _bufferManager.signStream.listen((result) {
      if (mounted) {
        setState(() {
          _currentSigns.add(result);
        });
      }
    });

    // Listen for phrase completion from buffer manager
    _bufferManager.phraseStream.listen((phrase) {
      if (mounted) {
        setState(() {
          _lastPhrase = phrase;
        });
        // Optionally auto-play audio here if available
      }
    });

    // Listen for connection status from service
    _recognitionService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isConnected = connected;
        });
      }
    });

    // Listen for server-side sign recognition (alternative path)
    // Track latency: compare current time with when landmarks were sent
    _recognitionService.signStream.listen((result) {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Note: This is a simplified latency measure; in production,
      // you'd track the send timestamp per frame
      // For now, we'll just log the fact that we received something
      print('[Latency] Sign received at $now');

      if (mounted) {
        setState(() {
          _currentSigns.add(result);
        });
      }
    });

    // Listen for server-side phrase completion
    _recognitionService.phraseStream.listen((phrase) {
      if (mounted) {
        setState(() {
          _lastPhrase = phrase;
        });
      }
    });
  }

  Future<void> _connect() async {
    try {
      await _recognitionService.connect();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to connect to recognition service: $e';
      });
    }
  }

  void _toggleCamera() {
    setState(() {
      _lensDirection = _lensDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
    });
  }

  void _clearPhrase() {
    setState(() {
      _currentSigns.clear();
      _lastPhrase = null;
      _bufferManager.clear();
    });
  }

  void _editSign(int index, String newText) {
    if (mounted && index < _currentSigns.length) {
      setState(() {
        _currentSigns[index] = RecognitionResult(
          sign: newText,
          confidence: _currentSigns[index].confidence,
        );
      });
    }
  }

  @override
  void dispose() {
    _recognitionService.dispose();
    _bufferManager.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign Language Recognition'),
        actions: [
          // Connection status indicator
          IconButton(
            icon: Icon(
              _isConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isConnected ? Colors.green : Colors.red,
            ),
            onPressed: _isConnected ? null : _connect,
            tooltip: _isConnected ? 'Connected' : 'Reconnect',
          ),
          // Clear button
          IconButton(
            icon: const Icon(Icons.clear),
            onPressed: _clearPhrase,
            tooltip: 'Clear phrase',
          ),
        ],
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : _buildMainView(),
    );
  }

  Widget _buildMainView() {
    return Column(
      children: [
        // Main content row
        Expanded(
          child: Row(
            children: [
              // Camera preview (left side - takes about 50% width)
              Expanded(
                flex: 1,
                child: CameraPreviewWithMediaPipe(
                  onLandmarks: _onLandmarksDetected,
                  lensDirection: _lensDirection,
                  targetFps: 15,
                  enableLandmarkDetection: true,
                  config: widget.config,
                ),
              ),

              // Divider
              const VerticalDivider(thickness: 1, width: 1),

              // Text panel (right side - takes about 50% width)
              Expanded(
                flex: 1,
                child: TextPanel(
                  signs: _currentSigns,
                  onSignEdit: _editSign,
                  isPhraseComplete: _lastPhrase != null,
                  audioData: _lastPhrase?.audio,
                ),
              ),
            ],
          ),
        ),

        // Bottom controls
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[200],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Camera toggle
          ElevatedButton.icon(
            onPressed: _toggleCamera,
            icon: Icon(
              _lensDirection == CameraLensDirection.back
                  ? Icons.camera_rear
                  : Icons.camera_front,
            ),
            label: Text(
              _lensDirection == CameraLensDirection.back
                  ? 'Switch to Front'
                  : 'Switch to Rear',
            ),
          ),
          const SizedBox(width: 16),

          // Connection status
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _isConnected ? Colors.green[100] : Colors.red[100],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _isConnected ? Colors.green : Colors.red,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _isConnected ? Icons.wifi : Icons.wifi_off,
                  size: 16,
                  color: _isConnected ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 6),
                Text(
                  _isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    fontSize: 12,
                    color: _isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, color: Colors.red, size: 64),
          const SizedBox(height: 16),
          Text(
            _errorMessage ?? 'An error occurred',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _connect,
            child: const Text('Retry Connection'),
          ),
        ],
      ),
    );
  }

  void _onLandmarksDetected(LandmarksPayload payload) {
    final now = DateTime.now().millisecondsSinceEpoch;
    print('[Latency] Landmarks received at $now');

    // Track latency: store the send time in a simple way
    // In production, you'd use a more sophisticated correlation mechanism
    // For now, we'll update a rolling average based on the processing time
    // between frames reaching the screen and being processed
    _updateLatencyMeasurement(now, payload.timestamp);

    // Add session ID from service if available
    final payloadWithSession = LandmarksPayload(
      left: payload.left,
      right: payload.right,
      timestamp: payload.timestamp,
      sessionId: payload.sessionId.isEmpty
          ? _recognitionService.sessionId ?? ''
          : payload.sessionId,
    );

    // Feed landmarks to buffer manager
    _bufferManager.addLandmarks(payloadWithSession);

    // Also send to server if connected
    if (_isConnected) {
      _recognitionService.sendLandmarks(payloadWithSession);
    }
  }

  /// Update latency measurement based on frame-to-processing delta
  void _updateLatencyMeasurement(int now, int frameTimestamp) {
    // This is a simplified measurement.
    // Actual round-trip would require timestamp correlation from server responses
    // For now, we just note the processing time relative to frame capture
    // A more complete implementation would track:
    // - Timestamp when frame was captured (in payload.timestamp)
    // - Current time when we receive landmarks
    // - Time when sign result is returned

    // For demonstration, we'll calculate a placeholder latency
    // In production, the server would include the original timestamp in responses
    final processingDelay = now - frameTimestamp;
    if (processingDelay >= 0 && processingDelay < 5000) {
      _latencySamples.add(processingDelay);
      if (_latencySamples.length > _maxLatencySamples) {
        _latencySamples.removeAt(0);
      }
      final avg = _latencySamples.reduce((a, b) => a + b) / _latencySamples.length;
      print('[Latency] Current processing delay: ${processingDelay}ms, Average: ${avg.round()}ms');

      // Alert if latency exceeds threshold
      if (processingDelay > 1000) {
        print('[Latency WARNING] Processing latency ${processingDelay}ms exceeds 1000ms threshold!');
      }
    }
  }
}
