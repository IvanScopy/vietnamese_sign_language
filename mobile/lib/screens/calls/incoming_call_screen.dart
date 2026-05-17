import 'package:flutter/material.dart';
import 'package:mobile/models/call_state.dart';
import 'package:mobile/services/call_api_service.dart';

/// Full-screen incoming call UI with Accept/Reject actions.
///
/// On mount: fetches current call state from backend to verify call is still RINGING
/// (prevents stale push opens per D-14).
///
/// Uses UI-SPEC colors: Accept (#16A34A green), Reject (#DC2626 red).
/// Stable visual affordance (no flashing/pulsing strobes per D-17).
class IncomingCallScreen extends StatefulWidget {
  final CallApiService callApiService;
  final int callId;
  final String? fromUserName;

  const IncomingCallScreen({
    super.key,
    required this.callApiService,
    required this.callId,
    this.fromUserName,
  });

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  bool _isLoading = true;
  bool _isUnavailable = false;

  @override
  void initState() {
    super.initState();
    _verifyCallState();
  }

  Future<void> _verifyCallState() async {
    try {
      final session = await widget.callApiService.getCallState(widget.callId);
      if (!mounted) return;

      if (session.state != CallState.ringing) {
        setState(() {
          _isUnavailable = true;
          _isLoading = false;
        });
        // Auto-dismiss after 2 seconds
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        });
        return;
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUnavailable = true;
        _isLoading = false;
      });
    }
  }

  Future<void> _onAccept() async {
    try {
      final session = await widget.callApiService.acceptCall(widget.callId);
      if (!mounted) return;

      Navigator.of(context).pushReplacementNamed(
        '/calls/active',
        arguments: {
          'callSession': session,
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept call: $e')),
      );
    }
  }

  Future<void> _onReject() async {
    try {
      await widget.callApiService.rejectCall(widget.callId);
    } catch (_) {
      // Best effort — still navigate away
    }
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_isUnavailable) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.call_missed, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              const Text(
                'Call unavailable',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    final callerName = widget.fromUserName ?? 'Unknown caller';

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Caller identity at top
            const Spacer(),
            const CircleAvatar(
              radius: 48,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 48, color: Colors.white),
            ),
            const SizedBox(height: 16),
            Text(
              callerName,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Incoming video call',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const Spacer(),
            // Stable green indicator (no flashing per D-17)
            Container(
              width: 16,
              height: 16,
              decoration: const BoxDecoration(
                color: Color(0xFF16A34A),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(height: 48),
            // Accept and Reject buttons in lower third
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Reject button
                  _CallActionButton(
                    icon: Icons.call_end,
                    label: 'Reject',
                    color: const Color(0xFFDC2626),
                    onPressed: _onReject,
                  ),
                  // Accept button
                  _CallActionButton(
                    icon: Icons.call,
                    label: 'Accept',
                    color: const Color(0xFF16A34A),
                    onPressed: _onAccept,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }
}

class _CallActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _CallActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 64,
          height: 64,
          child: FloatingActionButton(
            backgroundColor: color,
            onPressed: onPressed,
            child: Icon(icon, size: 32, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}
