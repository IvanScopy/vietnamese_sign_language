import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:mobile/models/recognition_event.dart';

/// Callback for when user edits a sign text
typedef SignEditCallback = void Function(int index, String newText);

/// Widget displaying accumulated recognized signs as chat bubbles.
class TextPanel extends StatefulWidget {
  /// List of recognized signs in the current phrase
  final List<RecognitionResult> signs;

  /// Callback when a sign text is edited
  final SignEditCallback? onSignEdit;

  /// Whether phrase is complete (triggers audio playback indicator)
  final bool isPhraseComplete;

  /// Base64 audio data to play (if available)
  final String? audioData;

  const TextPanel({
    super.key,
    required this.signs,
    this.onSignEdit,
    this.isPhraseComplete = false,
    this.audioData,
  });

  @override
  State<TextPanel> createState() => _TextPanelState();
}

class _TextPanelState extends State<TextPanel> {
  final Map<int, TextEditingController> _controllers = {};
  final FocusNode _focusNode = FocusNode();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    _initControllers();
  }

  void _initControllers() {
    for (int i = 0; i < widget.signs.length; i++) {
      if (!_controllers.containsKey(i)) {
        _controllers[i] = TextEditingController(text: widget.signs[i].sign);
      }
    }
  }

  @override
  void didUpdateWidget(TextPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.signs.length != widget.signs.length) {
      _initControllers();
    }
    // Update text for existing controllers if sign changed
    for (int i = 0; i < widget.signs.length; i++) {
      final controller = _controllers[i];
      if (controller != null && controller.text != widget.signs[i].sign) {
        controller.text = widget.signs[i].sign;
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    _focusNode.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recognized Signs',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (widget.isPhraseComplete && widget.audioData != null)
                IconButton(
                  icon: const Icon(Icons.volume_up, color: Colors.blue),
                  onPressed: _playAudio,
                  tooltip: 'Play audio',
                ),
            ],
          ),
          const SizedBox(height: 8),

          // Signs list
          Expanded(
            child: widget.signs.isEmpty
                ? const Center(
                    child: Text(
                      'Start signing to see recognition results',
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.signs.length,
                    itemBuilder: (context, index) {
                      final sign = widget.signs[index];
                      final controller = _controllers[index]!;

                      return _SignBubble(
                        controller: controller,
                        confidence: sign.confidence,
                        onEdit: (text) {
                          widget.onSignEdit?.call(index, text);
                        },
                        onCommit: () {
                          // Notify parent of edit
                          widget.onSignEdit?.call(index, controller.text);
                        },
                      );
                    },
                  ),
          ),

          // Status bar
          if (widget.isPhraseComplete)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.green[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.green),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Phrase complete - audio playing',
                    style: TextStyle(color: Colors.green),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _playAudio() async {
    if (widget.audioData == null) {
      return;
    }

    try {
      // Decode base64 audio data (WAV format from backend TTS)
      final audioBytes = base64Decode(widget.audioData!);

      // Play audio using audioplayers
      await _audioPlayer.play(BytesSource(audioBytes));

      // Show brief feedback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Playing audio...'),
            duration: Duration(seconds: 1),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('Audio playback error: $e\n$stackTrace');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to play audio: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

/// Single sign bubble with editable text and confidence indicator.
class _SignBubble extends StatelessWidget {
  final TextEditingController controller;
  final double confidence;
  final ValueChanged<String>? onEdit;
  final VoidCallback? onCommit;

  const _SignBubble({
    required this.controller,
    required this.confidence,
    this.onEdit,
    this.onCommit,
  });

  @override
  Widget build(BuildContext context) {
    final confidenceColor = _getConfidenceColor(confidence);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          // Focus the text field for editing
          // In a real implementation, this would show an edit UI
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Confidence indicator
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: confidenceColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),

              // Sign text (editable)
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.zero,
                  ),
                  style: const TextStyle(fontSize: 16),
                  onChanged: onEdit,
                  onSubmitted: (_) => onCommit?.call(),
                ),
              ),

              // Confidence percentage
              Text(
                '${(confidence * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) return Colors.green;
    if (confidence >= 0.6) return Colors.orange;
    return Colors.red;
  }
}
