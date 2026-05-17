import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';

/// Service for connecting to LiveKit rooms for video calls.
///
/// Handles room connection, track publishing (camera/microphone), and cleanup.
/// Token is received from authenticated backend endpoint only and is not persisted.
class LiveKitCallService {
  Room? _room;
  bool _isConnected = false;

  /// Stream of room events for track subscription changes
  final StreamController<RoomEvent> _eventController =
      StreamController<RoomEvent>.broadcast();

  Stream<RoomEvent> get events => _eventController.stream;
  bool get isConnected => _isConnected;
  Room? get room => _room;

  /// Connect to a LiveKit room and publish camera + microphone tracks.
  ///
  /// [url] - LiveKit WebSocket URL (e.g., ws://10.0.2.2:7880)
  /// [token] - Short-lived, room-scoped JWT from backend accept/token endpoint
  Future<Room> connect(String url, String token) async {
    if (_isConnected && _room != null) {
      debugPrint('[LiveKitCall] Already connected, disconnecting first');
      await disconnect();
    }

    _room = Room(
      roomOptions: const RoomOptions(
        adaptiveStream: true,
        dynacast: true,
      ),
    );

    // Set up event forwarding
    final listener = _room!.createListener();
    listener.on<RoomEvent>((event) {
      if (!_eventController.isClosed) {
        _eventController.add(event);
      }
    });

    try {
      await _room!.connect(url, token);

      // Enable camera
      try {
        await _room!.localParticipant?.setCameraEnabled(true);
      } catch (e) {
        debugPrint('[LiveKitCall] Could not enable camera: $e');
      }

      // Enable microphone
      try {
        await _room!.localParticipant?.setMicrophoneEnabled(true);
      } catch (e) {
        debugPrint('[LiveKitCall] Could not enable microphone: $e');
      }

      _isConnected = true;
      debugPrint('[LiveKitCall] Connected to room');

      return _room!;
    } catch (e) {
      debugPrint('[LiveKitCall] Connection failed: $e');
      await _room?.disconnect();
      _room = null;
      _isConnected = false;
      rethrow;
    }
  }

  /// Disconnect from the current room.
  Future<void> disconnect() async {
    if (_room != null) {
      await _room!.disconnect();
      _room = null;
      _isConnected = false;
      debugPrint('[LiveKitCall] Disconnected');
    }
  }

  /// Toggle microphone mute state.
  Future<void> toggleMicrophone() async {
    final localParticipant = _room?.localParticipant;
    if (localParticipant == null) return;

    final isMicEnabled = localParticipant.isMicrophoneEnabled();
    await localParticipant.setMicrophoneEnabled(!isMicEnabled);
  }

  /// Toggle camera on/off state.
  Future<void> toggleCamera() async {
    final localParticipant = _room?.localParticipant;
    if (localParticipant == null) return;

    final isCameraEnabled = localParticipant.isCameraEnabled();
    await localParticipant.setCameraEnabled(!isCameraEnabled);
  }

  /// Dispose all resources. Token is discarded — not persisted.
  Future<void> dispose() async {
    await disconnect();
    await _eventController.close();
  }
}
