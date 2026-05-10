import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:mobile/models/landmark.dart';
import 'package:mobile/models/recognition_event.dart';

/// Service for connecting to the recognition backend via Socket.io.
///
/// Handles:
/// - Connection management with JWT authentication
/// - Streaming landmarks to server
/// - Receiving recognition results and phrase completion events
class SignRecognitionService {
  io.Socket? _socket;
  final String serverUrl;
  final int serverPort;
  final String authToken;
  final String? sessionId;

  bool _isConnected = false;
  bool _isConnecting = false;

  /// Stream of recognized signs
  final StreamController<RecognitionResult> _signController =
      StreamController<RecognitionResult>.broadcast();

  /// Stream of phrase completion events
  final StreamController<PhraseComplete> _phraseController =
      StreamController<PhraseComplete>.broadcast();

  /// Stream of connection status changes
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<RecognitionResult> get signStream => _signController.stream;
  Stream<PhraseComplete> get phraseStream => _phraseController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;
  bool get isConnected => _isConnected;

  SignRecognitionService({
    required this.serverUrl,
    required this.serverPort,
    required this.authToken,
    this.sessionId,
  });

  /// Connect to the recognition service
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      final uri = 'http://$serverUrl:$serverPort';
      _socket = io.io(
        uri,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setExtraHeaders({'Authorization': 'Bearer $authToken'})
            .disableAutoConnect()
            .build(),
      );

      _setupEventHandlers();

      _socket!.connect();

      // Wait for connection with timeout
      await _waitForConnection();
    } finally {
      _isConnecting = false;
    }
  }

  void _setupEventHandlers() {
    _socket!.on('connect', (_) {
      _isConnected = true;
      _connectionController.add(true);
      print('Socket.io connected: ${_socket!.id}');
    });

    _socket!.on('disconnect', (reason) {
      _isConnected = false;
      _connectionController.add(false);
      print('Socket.io disconnected: $reason');
    });

    _socket!.on('connect_error', (error) {
      print('Socket.io connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.on('connected', (data) {
      print('Received connected event: $data');
    });

    _socket!.on('sign_recognized', (data) {
      try {
        final result = RecognitionResult(
          sign: data['sign'] as String,
          confidence: (data['confidence'] as num).toDouble(),
        );
        _signController.add(result);
      } catch (e) {
        print('Error parsing sign_recognized: $e');
      }
    });

    _socket!.on('phrase_complete', (data) {
      try {
        final phrase = PhraseComplete(
          text: data['text'] as String,
          signs: (data['signs'] as List)
              .map((s) => RecognitionResult(
                    sign: s['sign'] as String,
                    confidence: (s['confidence'] as num).toDouble(),
                  ))
              .toList(),
          audio: data['audio'] as String?,
        );
        _phraseController.add(phrase);
      } catch (e) {
        print('Error parsing phrase_complete: $e');
      }
    });

    _socket!.on('error', (data) {
      print('Socket.io error: $data');
    });
  }

  Future<void> _waitForConnection() async {
    final completer = Completer<void>();
    void listener(bool connected) {
      if (connected) {
        completer.complete();
      }
    }

    _connectionController.stream.listen(listener);

    try {
      await completer.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timeout');
        },
      );
    } finally {
      // Note: In production, would need to unsubscribe
    }
  }

  /// Send landmarks to the server for recognition
  void sendLandmarks(LandmarksPayload payload) {
    if (!_isConnected || _socket == null) {
      print('Cannot send landmarks: not connected');
      return;
    }

    final data = {
      'landmarks': {
        if (payload.left != null)
          'left': {
            'handedness': payload.left!.handedness,
            'landmarks': payload.left!.landmarks
                .map((lm) => {
                      'x': lm.x,
                      'y': lm.y,
                      'z': lm.z,
                      'visibility': lm.visibility,
                    })
                .toList(),
          },
        if (payload.right != null)
          'right': {
            'handedness': payload.right!.handedness,
            'landmarks': payload.right!.landmarks
                .map((lm) => {
                      'x': lm.x,
                      'y': lm.y,
                      'z': lm.z,
                      'visibility': lm.visibility,
                    })
                .toList(),
          },
      },
      'timestamp': payload.timestamp,
      'sessionId': payload.sessionId,
    };

    _socket!.emit('landmarks', data);
  }

  /// Disconnect from the server
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }

  /// Dispose all resources
  Future<void> dispose() async {
    _socket?.dispose();
    await _signController.close();
    await _phraseController.close();
    await _connectionController.close();
  }
}
