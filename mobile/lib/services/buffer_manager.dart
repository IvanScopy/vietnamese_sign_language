import 'dart:async';
import 'package:mobile/models/landmark.dart';
import 'package:mobile/models/recognition_event.dart';

/// BufferManager handles client-side sliding window for sign recognition
/// and phrase boundary detection based on timeouts.
///
/// Mirrors the server-side sliding window buffer:
/// - Accumulates frames until window is full, then emits sign event
/// - Does NOT auto-clear after emission (maintains last frame for sliding)
/// - Phrase timeout (2-3 seconds of inactivity) triggers phrase completion
class BufferManager {
  /// Number of frames to accumulate before emitting a sign event
  final int windowSize;

  /// Timeout in milliseconds after last sign to consider phrase complete
  final int phraseTimeoutMs;

  /// Internal buffer storing feature vectors from frames
  final List<List<double>> _frameBuffer = [];

  /// Accumulated signs for current phrase
  final List<RecognitionResult> _phraseBuffer = [];

  /// Stream controller for sign recognition events
  final StreamController<RecognitionResult> _signController =
      StreamController<RecognitionResult>.broadcast();

  /// Stream controller for phrase completion events
  final StreamController<PhraseComplete> _phraseController =
      StreamController<PhraseComplete>.broadcast();

  /// Timer for phrase timeout detection
  Timer? _phraseTimer;

  /// Stream of recognized signs
  Stream<RecognitionResult> get signStream => _signController.stream;

  /// Stream of phrase completion events
  Stream<PhraseComplete> get phraseStream => _phraseController.stream;

  BufferManager({
    required this.windowSize,
    required this.phraseTimeoutMs,
  });

  /// Process a new frame of landmarks.
  /// Extracts 126-dimensional feature vector and adds to buffer.
  /// When buffer reaches windowSize, emits a sign recognition event.
  void addLandmarks(LandmarksPayload payload) {
    final features = _extractFeatures(payload);
    _frameBuffer.add(features);

    if (_frameBuffer.length >= windowSize) {
      // Emit sign recognition event
      final result = RecognitionResult(
        sign: 'placeholder_sign',
        confidence: 0.85,
      );
      _signController.add(result);
      _phraseBuffer.add(result);

      // Restart phrase timeout timer
      _phraseTimer?.cancel();
      _phraseTimer = Timer(
        Duration(milliseconds: phraseTimeoutMs),
        _onPhraseTimeout,
      );
    }
  }

  /// Extract 126-dimensional feature vector from landmarks.
  /// Left hand: indices 0-62 (21 landmarks × 3 coords)
  /// Right hand: indices 63-125 (21 landmarks × 3 coords)
  List<double> _extractFeatures(LandmarksPayload payload) {
    final features = List<double>.filled(126, 0.0);

    // Extract left hand features (indices 0-62)
    if (payload.left != null) {
      for (int i = 0; i < payload.left!.landmarks.length && i < 21; i++) {
        final base = i * 3;
        features[base] = payload.left!.landmarks[i].x;
        features[base + 1] = payload.left!.landmarks[i].y;
        features[base + 2] = payload.left!.landmarks[i].z;
      }
    }

    // Extract right hand features (indices 63-125)
    if (payload.right != null) {
      for (int i = 0; i < payload.right!.landmarks.length && i < 21; i++) {
        final base = 63 + (i * 3);
        features[base] = payload.right!.landmarks[i].x;
        features[base + 1] = payload.right!.landmarks[i].y;
        features[base + 2] = payload.right!.landmarks[i].z;
      }
    }

    return features;
  }

  /// Handle phrase timeout - emit phrase complete event
  void _onPhraseTimeout() {
    if (_phraseBuffer.isNotEmpty) {
      final text = _phraseBuffer.map((r) => r.sign).join(' ');
      final phrase = PhraseComplete(
        text: text,
        signs: List.from(_phraseBuffer),
      );
      _phraseController.add(phrase);
      _phraseBuffer.clear();
    }
  }

  /// Get current buffer fill count
  int get bufferFill => _frameBuffer.length;

  /// Get accumulated phrase signs count
  int get phraseLength => _phraseBuffer.length;

  /// Check if buffer has accumulated enough frames for a sign
  bool get isReady => _frameBuffer.length >= windowSize;

  /// Clear all buffers and reset state
  void clear() {
    _frameBuffer.clear();
    _phraseBuffer.clear();
    _phraseTimer?.cancel();
    _phraseTimer = null;
  }

  /// Dispose resources
  Future<void> dispose() async {
    _phraseTimer?.cancel();
    await _signController.close();
    await _phraseController.close();
  }
}
