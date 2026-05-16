import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mobile/models/call_state.dart';
import 'package:mobile/services/call_api_service.dart';
import 'package:mobile/services/call_signaling_service.dart';

/// Full-screen outgoing ringing UI with Cancel button.
///
/// Listens for call:accepted → navigates to ActiveCallScreen.
/// Listens for call:rejected/call:missed/call:busy → navigates to CallResultScreen.
class OutgoingCallScreen extends StatefulWidget {
  final CallApiService callApiService;
  final CallSignalingService callSignalingService;
  final int callId;
  final String? calleeName;

  const OutgoingCallScreen({
    super.key,
    required this.callApiService,
    required this.callSignalingService,
    required this.callId,
    this.calleeName,
  });

  @override
  State<OutgoingCallScreen> createState() => _OutgoingCallScreenState();
}

class _OutgoingCallScreenState extends State<OutgoingCallScreen> {
  StreamSubscription<Map<String, dynamic>>? _acceptedSub;
  StreamSubscription<Map<String, dynamic>>? _rejectedSub;
  StreamSubscription<Map<String, dynamic>>? _missedSub;
  StreamSubscription<Map<String, dynamic>>? _busySub;

  @override
  void initState() {
    super.initState();
    _setupSignalingListeners();
  }

  void _setupSignalingListeners() {
    _acceptedSub = widget.callSignalingService.callAcceptedStream.listen((data) {
      if (!mounted) return;
      final acceptedCallId = data['callId'] as int?;
      if (acceptedCallId == widget.callId) {
        final roomName = data['roomName'] as String? ?? '';
        Navigator.of(context).pushReplacementNamed(
          '/calls/active',
          arguments: {
            'callSession': CallSession(
              callId: widget.callId,
              roomName: roomName,
              fromUserId: 0,
              state: CallState.active,
            ),
          },
        );
      }
    });

    _rejectedSub = widget.callSignalingService.callRejectedStream.listen((data) {
      if (!mounted) return;
      final eventCallId = data['callId'] as int?;
      if (eventCallId == widget.callId) {
        _goToResult(CallState.rejected);
      }
    });

    _missedSub = widget.callSignalingService.callMissedStream.listen((data) {
      if (!mounted) return;
      final eventCallId = data['callId'] as int?;
      if (eventCallId == widget.callId) {
        _goToResult(CallState.missed);
      }
    });

    _busySub = widget.callSignalingService.callBusyStream.listen((data) {
      if (!mounted) return;
      final eventCallId = data['callId'] as int?;
      if (eventCallId == widget.callId) {
        _goToResult(CallState.busy);
      }
    });
  }

  void _goToResult(CallState state) {
    Navigator.of(context).pushReplacementNamed(
      '/calls/result',
      arguments: {'callState': state},
    );
  }

  Future<void> _onCancel() async {
    try {
      await widget.callApiService.cancelCall(widget.callId);
    } catch (_) {
      // Best effort
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  void dispose() {
    _acceptedSub?.cancel();
    _rejectedSub?.cancel();
    _missedSub?.cancel();
    _busySub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.calleeName ?? 'Contact';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              name,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Ringing...',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              'Connecting video call',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const Spacer(),
            // Cancel button
            Padding(
              padding: const EdgeInsets.only(bottom: 48),
              child: SizedBox(
                width: 64,
                height: 64,
                child: FloatingActionButton(
                  backgroundColor: const Color(0xFFDC2626),
                  onPressed: _onCancel,
                  child: const Icon(Icons.call_end, size: 32, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
