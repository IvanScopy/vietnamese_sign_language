import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mobile/config/app_config.dart';
import 'package:mobile/models/call_state.dart';

/// Shows state-specific UI for call outcomes.
///
/// States: ended, missed, rejected, cancelled, busy, failed.
/// Uses UI-SPEC copywriting contract for headlines and body text.
///
/// For ended state: shows "Save text transcript?" prompt with Save/Discard actions.
/// For failed state: shows "Retry" button.
/// All states: "Back to home" button.
class CallResultScreen extends StatefulWidget {
  final CallState callState;
  final String? callerName;
  final int? callId;
  final String? transcript;
  final AppConfig? config;
  final String? authToken;

  const CallResultScreen({
    super.key,
    required this.callState,
    this.callerName,
    this.callId,
    this.transcript,
    this.config,
    this.authToken,
  });

  @override
  State<CallResultScreen> createState() => _CallResultScreenState();
}

class _CallResultScreenState extends State<CallResultScreen> {
  bool _isSaving = false;

  Future<void> _saveTranscript() async {
    final callId = widget.callId;
    final config = widget.config;
    final authToken = widget.authToken;
    final transcript = widget.transcript?.trim();

    if (callId == null ||
        config == null ||
        authToken == null ||
        transcript == null ||
        transcript.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transcript saving unavailable')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final uri = Uri.parse('${config.httpUrl}/api/calls/$callId/transcript');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: jsonEncode({'transcript': transcript}),
      );

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transcript saved successfully'),
            backgroundColor: Color(0xFF16A34A),
          ),
        );
        // Navigate home after successful save
        Navigator.of(context).popUntil((route) => route.isFirst);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save transcript')),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save transcript')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _discardTranscript() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard text transcript?'),
        content: const Text(
          'This action cannot be undone. Only confirmed text would have been saved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.callerName ?? 'Contact';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CallStateIcon(state: widget.callState),
              const SizedBox(height: 24),
              Text(
                _getHeadline(widget.callState),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getBodyText(widget.callState, name),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Transcript save prompt for ended state
              if (widget.callState == CallState.ended) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Save text transcript?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Only confirmed text will be saved. Audio and video are not recorded.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Discard button
                          OutlinedButton.icon(
                            onPressed: _isSaving ? null : _discardTranscript,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Discard'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFFDC2626),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Save button
                          FilledButton.icon(
                            onPressed: _isSaving ? null : _saveTranscript,
                            icon: _isSaving
                                ? const SizedBox.square(
                                    dimension: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.save),
                            label: const Text('Save transcript'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Retry button for failed state
              if (widget.callState == CallState.failed) ...[
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
                const SizedBox(height: 16),
              ],
              // Back to home button for all states
              OutlinedButton.icon(
                onPressed: () {
                  // Pop all call routes to go back to home
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.home),
                label: const Text('Back to home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getHeadline(CallState state) {
    switch (state) {
      case CallState.ended:
        return 'Call ended';
      case CallState.missed:
        return 'Missed call';
      case CallState.rejected:
        return 'Call declined';
      case CallState.cancelled:
        return 'Call cancelled';
      case CallState.busy:
        return 'This person is already in a call.';
      case CallState.failed:
        return 'Call failed';
      case CallState.ringing:
      case CallState.active:
        return 'Call in progress';
    }
  }

  String _getBodyText(CallState state, String name) {
    switch (state) {
      case CallState.ended:
        return 'The call with $name has ended.';
      case CallState.missed:
        return 'You missed a call from $name.';
      case CallState.rejected:
        return 'You declined the call from $name.';
      case CallState.cancelled:
        return 'You cancelled the call to $name.';
      case CallState.busy:
        return '$name is currently on another call. Try again later.';
      case CallState.failed:
        return 'Unable to connect the call. Please check your connection.';
      case CallState.ringing:
      case CallState.active:
        return '';
    }
  }
}

class _CallStateIcon extends StatelessWidget {
  final CallState state;

  const _CallStateIcon({required this.state});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (state) {
      case CallState.ended:
        icon = Icons.call_end;
        color = Colors.grey;
      case CallState.missed:
        icon = Icons.call_missed;
        color = Colors.orange;
      case CallState.rejected:
        icon = Icons.call_missed_outgoing;
        color = const Color(0xFFDC2626);
      case CallState.cancelled:
        icon = Icons.cancel_outlined;
        color = Colors.grey;
      case CallState.busy:
        icon = Icons.do_not_disturb_on;
        color = Colors.orange;
      case CallState.failed:
        icon = Icons.error_outline;
        color = Colors.red;
      case CallState.ringing:
      case CallState.active:
        icon = Icons.call;
        color = const Color(0xFF16A34A);
    }

    return Icon(icon, size: 64, color: color);
  }
}
