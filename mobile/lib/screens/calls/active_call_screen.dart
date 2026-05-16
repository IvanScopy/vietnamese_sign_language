import 'dart:async';

import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:mobile/models/call_state.dart';
import 'package:mobile/services/call_api_service.dart';
import 'package:mobile/services/livekit_call_service.dart';

/// Active call UI with remote video, local preview, and controls.
///
/// Remote video fills the screen via LiveKit VideoTrackRenderer.
/// Local preview as small top-corner tile.
/// Bottom control bar: mute mic, camera on/off, switch camera, End call.
///
/// Handles permission errors with recoverable screen.
/// Placeholder area reserved at bottom for translation overlays (Plan 05).
class ActiveCallScreen extends StatefulWidget {
  final LiveKitCallService liveKitCallService;
  final CallApiService callApiService;
  final CallSession callSession;
  final String liveKitUrl;

  const ActiveCallScreen({
    super.key,
    required this.liveKitCallService,
    required this.callApiService,
    required this.callSession,
    required this.liveKitUrl,
  });

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen> {
  Room? _room;
  bool _isMicMuted = false;
  bool _isCameraOff = false;
  bool _hasPermissionError = false;
  String? _connectionStatus;
  Timer? _statusTimer;
  StreamSubscription<RoomEvent>? _eventsSubscription;

  @override
  void initState() {
    super.initState();
    _connectToRoom();
  }

  Future<void> _connectToRoom() async {
    final token = widget.callSession.token;
    if (token == null || token.isEmpty) {
      debugPrint('[ActiveCall] No token available');
      return;
    }

    try {
      _room = await widget.liveKitCallService.connect(
        widget.liveKitUrl,
        token,
      );

      if (!mounted) return;

      // Listen for room events
      _eventsSubscription = widget.liveKitCallService.events.listen(_onRoomEvent);

      setState(() {
        _connectionStatus = 'Connected';
      });

      // Update status periodically
      _statusTimer = Timer.periodic(const Duration(seconds: 5), (_) {
        if (mounted && _room != null) {
          setState(() {
            _connectionStatus = 'Connected';
          });
        }
      });
    } catch (e) {
      if (!mounted) return;
      final isPermission = e.toString().toLowerCase().contains('permission');
      setState(() {
        _hasPermissionError = isPermission;
        _connectionStatus = 'Connection failed';
      });
    }
  }

  void _onRoomEvent(RoomEvent event) {
    if (!mounted) return;
    if (event is RoomDisconnectedEvent) {
      setState(() {
        _connectionStatus = 'Disconnected';
      });
    }
  }

  Future<void> _onEndCall() async {
    try {
      await widget.callApiService.endCall(widget.callSession.callId);
    } catch (_) {
      // Best effort
    }
    await widget.liveKitCallService.disconnect();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed(
        '/calls/result',
        arguments: {'callState': CallState.ended},
      );
    }
  }

  Future<void> _toggleMic() async {
    await widget.liveKitCallService.toggleMicrophone();
    if (mounted) {
      setState(() {
        _isMicMuted = !_isMicMuted;
      });
    }
  }

  Future<void> _toggleCamera() async {
    await widget.liveKitCallService.toggleCamera();
    if (mounted) {
      setState(() {
        _isCameraOff = !_isCameraOff;
      });
    }
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    _eventsSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasPermissionError) {
      return _PermissionErrorScreen(onEndCall: _onEndCall);
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Remote video fills the screen
          Positioned.fill(
            child: _room != null
                ? _RemoteVideoView(room: _room!)
                : Container(
                    color: Colors.grey[900],
                    child: const Center(
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  ),
          ),

          // Connection status pill
          if (_connectionStatus != null)
            Positioned(
              top: 48,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _connectionStatus == 'Connected'
                            ? Colors.green
                            : Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _connectionStatus!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Local preview tile (top-right corner)
          Positioned(
            top: 48,
            right: 16,
            child: Container(
              width: 90,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white30, width: 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: _room != null
                    ? _LocalPreview(room: _room!)
                    : const Center(
                        child: Icon(Icons.videocam_off, color: Colors.white54),
                      ),
              ),
            ),
          ),

          // Bottom control bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.8)],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ControlButton(
                    icon: _isMicMuted ? Icons.mic_off : Icons.mic,
                    label: 'Mute',
                    isActive: _isMicMuted,
                    onPressed: _toggleMic,
                  ),
                  _ControlButton(
                    icon: _isCameraOff ? Icons.videocam_off : Icons.videocam,
                    label: 'Camera',
                    isActive: _isCameraOff,
                    onPressed: _toggleCamera,
                  ),
                  // End call button (red, prominent)
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: FloatingActionButton(
                      backgroundColor: const Color(0xFFDC2626),
                      onPressed: _onEndCall,
                      child: const Icon(Icons.call_end, size: 28, color: Colors.white),
                    ),
                  ),
                  // Placeholder for switch camera (to be implemented)
                  _ControlButton(
                    icon: Icons.flip_camera_android,
                    label: 'Switch',
                    onPressed: () {
                      // TODO: implement camera switching
                    },
                  ),
                  // Reserved area for translation overlays (Plan 05)
                  const SizedBox(width: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Renders local camera preview.
class _LocalPreview extends StatefulWidget {
  final Room room;

  const _LocalPreview({required this.room});

  @override
  State<_LocalPreview> createState() => _LocalPreviewState();
}

class _LocalPreviewState extends State<_LocalPreview> {
  VideoTrack? _localVideoTrack;

  @override
  void initState() {
    super.initState();
    _findLocalVideoTrack();
  }

  void _findLocalVideoTrack() {
    final localParticipant = widget.room.localParticipant;
    if (localParticipant == null) return;

    for (final pub in localParticipant.trackPublications.values) {
      if (pub.source == TrackSource.camera && pub.track is VideoTrack) {
        setState(() {
          _localVideoTrack = pub.track as VideoTrack;
        });
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final track = _localVideoTrack;
    if (track != null) {
      return VideoTrackRenderer(track);
    }
    return const Center(
      child: Icon(Icons.videocam_off, color: Colors.white54),
    );
  }
}

/// Renders the first available remote video track.
class _RemoteVideoView extends StatefulWidget {
  final Room room;

  const _RemoteVideoView({required this.room});

  @override
  State<_RemoteVideoView> createState() => _RemoteVideoViewState();
}

class _RemoteVideoViewState extends State<_RemoteVideoView> {
  VideoTrack? _remoteTrack;
  CancelListenFunc? _subscription;

  @override
  void initState() {
    super.initState();
    _findRemoteTrack();
    _subscription = widget.room.events.listen(_onRoomEvent);
  }

  void _onRoomEvent(RoomEvent event) {
    if (event is TrackSubscribedEvent) {
      final track = event.track;
      if (track is VideoTrack) {
        setState(() {
          _remoteTrack = track;
        });
      }
    } else if (event is TrackUnsubscribedEvent) {
      setState(() {
        _remoteTrack = null;
      });
    }
  }

  void _findRemoteTrack() {
    for (final participant in widget.room.remoteParticipants.values) {
      for (final pub in participant.trackPublications.values) {
        if (pub.source != TrackSource.screenShareVideo && pub.track is VideoTrack) {
          setState(() {
            _remoteTrack = pub.track as VideoTrack;
          });
          return;
        }
      }
    }
  }

  @override
  void dispose() {
    _subscription?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final track = _remoteTrack;
    if (track != null) {
      return VideoTrackRenderer(track);
    }
    return Container(
      color: Colors.grey[900],
      child: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person, size: 64, color: Colors.white38),
            SizedBox(height: 8),
            Text(
              'Waiting for video...',
              style: TextStyle(color: Colors.white54, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

/// Control button for the bottom bar.
class _ControlButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  const _ControlButton({
    required this.icon,
    required this.label,
    this.isActive = false,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 48,
          height: 48,
          child: IconButton.filledTonal(
            onPressed: onPressed,
            icon: Icon(icon, color: isActive ? Colors.red : Colors.white),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

/// Recoverable permission error screen.
class _PermissionErrorScreen extends StatelessWidget {
  final Future<void> Function() onEndCall;

  const _PermissionErrorScreen({required this.onEndCall});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Camera or microphone unavailable',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please grant permissions in Settings',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // TODO: Open app settings
              },
              icon: const Icon(Icons.settings),
              label: const Text('Open settings'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => onEndCall(),
              child: const Text(
                'End call',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
