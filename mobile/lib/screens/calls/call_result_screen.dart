import 'package:flutter/material.dart';
import 'package:mobile/models/call_state.dart';

/// Shows state-specific UI for call outcomes.
///
/// States: ended, missed, rejected, cancelled, busy, failed.
/// Uses UI-SPEC copywriting contract for headlines and body text.
///
/// For ended state: shows "Save text transcript?" prompt.
/// For failed state: shows "Retry" button.
/// All states: "Back to home" button.
class CallResultScreen extends StatelessWidget {
  final CallState callState;
  final String? callerName;

  const CallResultScreen({
    super.key,
    required this.callState,
    this.callerName,
  });

  @override
  Widget build(BuildContext context) {
    final name = callerName ?? 'Contact';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _CallStateIcon(state: callState),
              const SizedBox(height: 24),
              Text(
                _getHeadline(callState),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _getBodyText(callState, name),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Transcript save prompt for ended state
              if (callState == CallState.ended) ...[
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
                      FilledButton.icon(
                        onPressed: () {
                          // TODO: Save transcript
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Transcript saving coming soon'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Save transcript'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              // Retry button for failed state
              if (callState == CallState.failed) ...[
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
