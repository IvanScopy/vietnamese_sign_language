import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket.io client for receiving call lifecycle events.
///
/// Server-authoritative: this service ONLY listens for events emitted by the server.
/// It does NOT emit call lifecycle events (per D-12).
///
/// Events listened for:
/// - call:incoming: { callId, fromUserId, expiresAt, type: 'VIDEO_CALL' }
/// - call:accepted: { callId, roomName }
/// - call:rejected, call:cancelled, call:ended, call:missed, call:busy: { callId }
class CallSignalingService {
  io.Socket? _socket;
  final String websocketUrl;
  final String authToken;
  final Duration connectionTimeout;

  bool _isConnected = false;
  bool _isConnecting = false;

  /// Stream of incoming call notifications
  final StreamController<Map<String, dynamic>> _incomingCallController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of call accepted events
  final StreamController<Map<String, dynamic>> _callAcceptedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of call rejected events
  final StreamController<Map<String, dynamic>> _callRejectedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of call cancelled events
  final StreamController<Map<String, dynamic>> _callCancelledController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of call ended events
  final StreamController<Map<String, dynamic>> _callEndedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of call missed events
  final StreamController<Map<String, dynamic>> _callMissedController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of call busy events
  final StreamController<Map<String, dynamic>> _callBusyController =
      StreamController<Map<String, dynamic>>.broadcast();

  /// Stream of connection status changes
  final StreamController<bool> _connectionController =
      StreamController<bool>.broadcast();

  Stream<Map<String, dynamic>> get incomingCallStream =>
      _incomingCallController.stream;
  Stream<Map<String, dynamic>> get callAcceptedStream =>
      _callAcceptedController.stream;
  Stream<Map<String, dynamic>> get callRejectedStream =>
      _callRejectedController.stream;
  Stream<Map<String, dynamic>> get callCancelledStream =>
      _callCancelledController.stream;
  Stream<Map<String, dynamic>> get callEndedStream => _callEndedController.stream;
  Stream<Map<String, dynamic>> get callMissedStream => _callMissedController.stream;
  Stream<Map<String, dynamic>> get callBusyStream => _callBusyController.stream;
  Stream<bool> get connectionStream => _connectionController.stream;

  bool get isConnected => _isConnected;

  CallSignalingService({
    required this.websocketUrl,
    required this.authToken,
    this.connectionTimeout = const Duration(seconds: 10),
  });

  /// Connect to the signaling service
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      return;
    }

    _isConnecting = true;

    try {
      _socket = io.io(
        websocketUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .setAuth({'token': authToken})
            .setExtraHeaders({'Authorization': 'Bearer $authToken'})
            .disableAutoConnect()
            .build(),
      );

      _setupEventHandlers();
      _socket!.connect();

      await _waitForConnection();
    } catch (_) {
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
      _isConnected = false;
      rethrow;
    } finally {
      _isConnecting = false;
    }
  }

  void _setupEventHandlers() {
    _socket!.on('connect', (_) {
      _isConnected = true;
      _connectionController.add(true);
      debugPrint('[CallSignaling] Socket.io connected: ${_socket!.id}');
    });

    _socket!.on('disconnect', (reason) {
      _isConnected = false;
      _connectionController.add(false);
      debugPrint('[CallSignaling] disconnected: $reason');
    });

    _socket!.on('connect_error', (error) {
      debugPrint('[CallSignaling] connection error: $error');
      _isConnected = false;
      _connectionController.add(false);
    });

    // Server-emitted call lifecycle events (read-only)
    _socket!.on('call:incoming', (data) {
      debugPrint('[CallSignaling] call:incoming: $data');
      _incomingCallController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('call:accepted', (data) {
      debugPrint('[CallSignaling] call:accepted: $data');
      _callAcceptedController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('call:rejected', (data) {
      debugPrint('[CallSignaling] call:rejected: $data');
      _callRejectedController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('call:cancelled', (data) {
      debugPrint('[CallSignaling] call:cancelled: $data');
      _callCancelledController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('call:ended', (data) {
      debugPrint('[CallSignaling] call:ended: $data');
      _callEndedController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('call:missed', (data) {
      debugPrint('[CallSignaling] call:missed: $data');
      _callMissedController.add(Map<String, dynamic>.from(data as Map));
    });

    _socket!.on('call:busy', (data) {
      debugPrint('[CallSignaling] call:busy: $data');
      _callBusyController.add(Map<String, dynamic>.from(data as Map));
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

  /// Disconnect from the signaling service
  void disconnect() {
    _socket?.disconnect();
    _isConnected = false;
  }

  /// Dispose all resources
  Future<void> dispose() async {
    _socket?.dispose();
    await _incomingCallController.close();
    await _callAcceptedController.close();
    await _callRejectedController.close();
    await _callCancelledController.close();
    await _callEndedController.close();
    await _callMissedController.close();
    await _callBusyController.close();
    await _connectionController.close();
  }
}
