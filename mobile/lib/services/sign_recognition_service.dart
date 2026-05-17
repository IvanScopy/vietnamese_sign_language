import 'dart:async';
import 'package:flutter/foundation.dart';
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
  final Duration connectionTimeout;
  String? _sessionId;

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
  String? get sessionId => _sessionId;

  SignRecognitionService({
    required this.serverUrl,
    required this.serverPort,
    required this.authToken,
    this.connectionTimeout = const Duration(seconds: 10),
    String? sessionId,
  }) : _sessionId = sessionId;

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
            .setAuth({'token': authToken})
            .setExtraHeaders({'Authorization': 'Bearer $authToken'})
            .disableAutoConnect()
            .build(),
      );

      _setupEventHandlers();

      _socket!.connect();

      // Wait for connection with timeout
      await _waitForConnection();
    } catch (_) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      _sessionId = null;
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  void _setupEventHandlers() {
    _socket!.on('connect', (_) {
      debugPrint('Socket.io connected: ${_socket!.id}');
    });

    _socket!.on('disconnect', (reason) {
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('Socket.io disconnected: $reason');
    });

    _socket!.on('connect_error', (error) {
      debugPrint('Socket.io connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    _socket!.on('connected', (data) {
      _sessionId = data['sessionId'] as String?;
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('Received connected event: $data');
    });

    _socket!.on('sign_recognized', (data) {
      try {
        final result = RecognitionResult(
          sign: data['sign'] as String,
          confidence: (data['confidence'] as num).toDouble(),
        );
        _signController.add(result);
      } catch (e) {
        debugPrint('Error parsing sign_recognized: $e');
      }
    });

    _socket!.on('phrase_complete', (data) {
      try {
        final phrase = PhraseComplete(
          text: data['text'] as String,
          signs: (data['signs'] as List)
              .map(
                (s) => RecognitionResult(
                  sign: s['sign'] as String,
                  confidence: (s['confidence'] as num).toDouble(),
                ),
              )
              .toList(),
          audio: data['audio'] as String?,
        );
        _phraseController.add(phrase);
      } catch (e) {
        debugPrint('Error parsing phrase_complete: $e');
      }
    });

    _socket!.on('error', (data) {
      debugPrint('Socket.io error: $data');
    });
  }

  Future<void> _waitForConnection() async {
    final completer = Completer<void>();
    late final StreamSubscription<bool> subscription;

    subscription = _connectionController.stream.listen(
      (connected) {
        if (connected && !completer.isCompleted) {
          completer.complete();
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!completer.isCompleted) {
          completer.completeError(error, stackTrace);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            TimeoutException('Connection closed before backend handshake'),
          );
        }
      },
    );

    try {
      await completer.future.timeout(
        connectionTimeout,
        onTimeout: () => throw TimeoutException('Connection timeout'),
      );
    } finally {
      await subscription.cancel();
    }
  }

  /// Send landmarks to the server for recognition
  void sendLandmarks(LandmarksPayload payload) {
    if (!_isConnected || _socket == null) {
      debugPrint('Cannot send landmarks: not connected');
      return;
    }

    final data = {
      'landmarks': {
        if (payload.pose != null)
          'pose': {
            'landmarks': payload.pose!.landmarks
                .map(
                  (lm) => {
                    'x': lm.x,
                    'y': lm.y,
                    'z': lm.z,
                    'visibility': lm.visibility,
                  },
                )
                .toList(),
          },
        if (payload.left != null)
          'left': {
            'handedness': payload.left!.handedness,
            'landmarks': payload.left!.landmarks
                .map(
                  (lm) => {
                    'x': lm.x,
                    'y': lm.y,
                    'z': lm.z,
                    'visibility': lm.visibility,
                  },
                )
                .toList(),
          },
        if (payload.right != null)
          'right': {
            'handedness': payload.right!.handedness,
            'landmarks': payload.right!.landmarks
                .map(
                  (lm) => {
                    'x': lm.x,
                    'y': lm.y,
                    'z': lm.z,
                    'visibility': lm.visibility,
                  },
                )
                .toList(),
          },
      },
      'timestamp': payload.timestamp,
      'sessionId': payload.sessionId,
    };

    _socket!.emit('landmarks', data);
  }

  /// Ask the backend to close the current phrase and emit phrase_complete.
  void completePhrase() {
    if (!_isConnected || _socket == null) {
      return;
    }
    _socket!.emit('complete_phrase', {});
  }

  /// Clear the current backend phrase state.
  void clearPhrase() {
    if (!_isConnected || _socket == null) {
      return;
    }
    _socket!.emit('clear_phrase', {});
  }

  /// Disconnect from the server
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
    _sessionId = null;
  }

  /// Dispose all resources
  Future<void> dispose() async {
    _socket?.dispose();
    await _signController.close();
    await _phraseController.close();
    await _connectionController.close();
  }
}
