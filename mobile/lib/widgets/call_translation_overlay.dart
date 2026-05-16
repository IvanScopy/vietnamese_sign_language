import 'dart:async';
import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:mobile/models/user_type.dart';
import 'package:mobile/services/call_transcription_service.dart';
import 'package:mobile/services/sign_recognition_service.dart';
import 'package:mobile/services/speech_transcription_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

/// Combined translation overlay for active video calls.
///
/// For deaf users:
/// - Shows live STT subtitles at the bottom (hearing user's speech)
/// - Shows sign recognition draft text above subtitles
/// - Confirm button sends text to hearing user
/// - Confirm & Play button sends text AND plays TTS
///
/// For hearing users:
/// - Shows received sign text from deaf user as text overlay
///
/// Uses UI-SPEC colors:
/// - Subtitle scrim: #101010 at 72% opacity
/// - Speaker badge: #2563EB
/// - Unclear/low confidence: #F59E0B
/// - Confirm action: #16A34A
/// - Confirm & Play: #2563EB
class CallTranslationOverlay extends StatefulWidget {
  final SignRecognitionService recognitionService;
  final SpeechTranscriptionService sttService;
  final CallTranscriptionService ttsService;
  final UserType currentUserType;
  final String authToken;

  const CallTranslationOverlay({
    super.key,
    required this.recognitionService,
    required this.sttService,
    required this.ttsService,
    required this.currentUserType,
    required this.authToken,
  });

  @override
  State<CallTranslationOverlay> createState() => _CallTranslationOverlayState();
}

class _CallTranslationOverlayState extends State<CallTranslationOverlay> {
  String _draftText = '';
  double? _draftConfidence;
  String _subtitleText = '';
  String _receivedSignText = '';
  bool _isTranscribing = false;
  bool _isPlayingTTS = false;

  StreamSubscription<dynamic>? _signSubscription;
  StreamSubscription<dynamic>? _phraseSubscription;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isSpeechCaptureActive = false;

  @override
  void initState() {
    super.initState();
    _setupRecognitionListeners();
    if (widget.currentUserType == UserType.deaf) {
      _startSpeechCapture();
    }
  }

  void _setupRecognitionListeners() {
    if (widget.currentUserType == UserType.deaf) {
      _signSubscription = widget.recognitionService.signStream.listen((result) {
        if (!mounted) return;
        final currentText = _draftText.trim();
        final nextText = currentText.isEmpty
            ? result.sign
            : '$currentText ${result.sign}';
        setState(() {
          _draftText = nextText;
          _draftConfidence = result.confidence;
        });
      });

      _phraseSubscription = widget.recognitionService.phraseStream.listen((phrase) {
        if (!mounted) return;
        setState(() {
          _draftText = phrase.text;
          final signs = phrase.signs;
          if (signs.isNotEmpty) {
            final sum = signs.fold<double>(
              0,
              (total, sign) => total + sign.confidence,
            );
            _draftConfidence = sum / signs.length;
          }
        });
      });
    }
  }

  Future<void> _startSpeechCapture() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission || !mounted) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final path = '${tempDir.path}/vsl-call-stt-${DateTime.now().microsecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path,
      );

      if (!mounted) return;
      setState(() {
        _isSpeechCaptureActive = true;
      });
    } catch (_) {
      // Speech capture unavailable — subtitles will not update
    }
  }

  Future<void> _onConfirm() async {
    final text = _draftText.trim();
    if (text.isEmpty) return;

    await widget.ttsService.sendTranscriptToHearingUser(text);

    if (!mounted) return;
    setState(() {
      _draftText = '';
      _draftConfidence = null;
    });
  }

  Future<void> _onConfirmAndPlay() async {
    final text = _draftText.trim();
    if (text.isEmpty) return;

    await widget.ttsService.sendTranscriptToHearingUser(text);

    if (!mounted) return;
    setState(() {
      _isPlayingTTS = true;
    });

    try {
      final audioResult = await widget.ttsService.synthesizeTTS(text);
      if (audioResult != null && mounted) {
        await _playAudio(audioResult);
      }
    } catch (_) {
      // TTS playback failed — silently continue
    }

    if (!mounted) return;
    setState(() {
      _draftText = '';
      _draftConfidence = null;
      _isPlayingTTS = false;
    });
  }

  Future<void> _playAudio(String audioData) async {
    try {
      // Try as base64 first
      final bytes = base64Decode(audioData);
      await _audioPlayer.play(BytesSource(bytes));
    } catch (_) {
      try {
        // Try as data URL
        final uriData = UriData.parse(audioData);
        await _audioPlayer.play(BytesSource(uriData.contentAsBytes()));
      } catch (_) {
        // Audio unavailable
      }
    }
  }

  @override
  void dispose() {
    _signSubscription?.cancel();
    _phraseSubscription?.cancel();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    if (_isSpeechCaptureActive) {
      _audioRecorder.stop().catchError((_) => null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.currentUserType == UserType.hearing) {
      return _buildHearingUserOverlay();
    }

    return _buildDeafUserOverlay();
  }

  Widget _buildDeafUserOverlay() {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 88, // Above call control bar (which is ~88px tall)
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sign draft overlay
          if (_draftText.isNotEmpty)
            _SignDraftSection(
              draftText: _draftText,
              confidence: _draftConfidence,
              onConfirm: _onConfirm,
              onConfirmAndPlay: _onConfirmAndPlay,
              isPlayingTTS: _isPlayingTTS,
            ),

          // Subtitle overlay
          if (_subtitleText.isNotEmpty || _isTranscribing)
            _SubtitleSection(
              subtitle: _subtitleText,
              isTranscribing: _isTranscribing,
            ),
        ],
      ),
    );
  }

  Widget _buildHearingUserOverlay() {
    if (_receivedSignText.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      left: 0,
      right: 0,
      bottom: 88,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFF101010).withOpacity(0.85),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Signer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _receivedSignText,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sign draft section showing current recognition text with Confirm/Confirm & Play.
class _SignDraftSection extends StatelessWidget {
  final String draftText;
  final double? confidence;
  final VoidCallback onConfirm;
  final VoidCallback onConfirmAndPlay;
  final bool isPlayingTTS;

  const _SignDraftSection({
    required this.draftText,
    this.confidence,
    required this.onConfirm,
    required this.onConfirmAndPlay,
    this.isPlayingTTS = false,
  });

  @override
  Widget build(BuildContext context) {
    final isLowConfidence = confidence != null && confidence! < 0.60;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF101010).withOpacity(0.85),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isLowConfidence
              ? const Color(0xFFF59E0B)
              : Colors.white.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            draftText,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white,
              height: 1.5,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (isLowConfidence) ...[
            const SizedBox(height: 4),
            const Text(
              'Unclear',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFFF59E0B),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isPlayingTTS)
                const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2563EB),
                  ),
                )
              else ...[
                IconButton(
                  tooltip: 'Confirm & Play',
                  onPressed: onConfirmAndPlay,
                  icon: const Icon(Icons.volume_up, color: Color(0xFF2563EB)),
                ),
                IconButton.filled(
                  tooltip: 'Confirm',
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFF16A34A),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

/// Subtitle section showing live STT transcription.
class _SubtitleSection extends StatelessWidget {
  final String subtitle;
  final bool isTranscribing;

  const _SubtitleSection({
    required this.subtitle,
    this.isTranscribing = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF101010).withOpacity(0.72),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF2563EB),
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'Speaker',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: isTranscribing
                ? const SizedBox(
                    height: 20,
                    child: LinearProgressIndicator(
                      color: Colors.white54,
                      minHeight: 3,
                    ),
                  )
                : Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      height: 1.5,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
        ],
      ),
    );
  }
}
