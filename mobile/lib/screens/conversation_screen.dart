import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:mobile/config/app_config.dart';
import 'package:mobile/models/conversation.dart';
import 'package:mobile/models/landmark.dart';
import 'package:mobile/models/recognition_event.dart';
import 'package:mobile/screens/conversation_history_screen.dart';
import 'package:mobile/services/conversation_history_service.dart';
import 'package:mobile/services/sign_recognition_service.dart';
import 'package:mobile/services/speech_transcription_service.dart';
import 'package:mobile/widgets/camera_preview.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class ConversationScreen extends StatefulWidget {
  final AppConfig config;
  final String authToken;
  final SignRecognitionService? recognitionService;
  final SpeechTranscriptionService? speechTranscriptionService;
  final ConversationHistoryService? historyService;
  final bool autoConnect;
  final bool enableCamera;

  const ConversationScreen({
    super.key,
    required this.config,
    required this.authToken,
    this.recognitionService,
    this.speechTranscriptionService,
    this.historyService,
    this.autoConnect = true,
    this.enableCamera = true,
  });

  @override
  State<ConversationScreen> createState() => _ConversationScreenState();
}

class _ConversationScreenState extends State<ConversationScreen> {
  late final SignRecognitionService _recognitionService;
  late final bool _ownsRecognitionService;
  late final SpeechTranscriptionService _speechTranscriptionService;
  late final bool _ownsSpeechTranscriptionService;

  ConversationHistoryService? _historyService;
  StreamSubscription<RecognitionResult>? _signSubscription;
  StreamSubscription<PhraseComplete>? _phraseSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final TextEditingController _draftController = TextEditingController();
  final List<ConversationMessage> _messages = [];

  late ConversationSession _session;
  ConversationRole _activeRole = ConversationRole.signer;
  ConversationMessageSource _draftSource = ConversationMessageSource.manual;
  double? _draftConfidence;
  bool _isRecognitionConnected = false;
  bool _isSaving = false;
  bool _isSpeechCaptureActive = false;
  bool _isTranscribing = false;
  bool _speechCaptureTouched = false;
  String? _lastAudioData;
  String? _recognitionError;
  CameraLensDirection _lensDirection = CameraLensDirection.back;

  @override
  void initState() {
    super.initState();
    _session = ConversationSession(
      id: 'session-${DateTime.now().microsecondsSinceEpoch}',
      startedAt: DateTime.now(),
      messages: _messages,
    );

    _ownsRecognitionService = widget.recognitionService == null;
    _recognitionService =
        widget.recognitionService ??
        SignRecognitionService(
          serverUrl: widget.config.serverUrl,
          serverPort: widget.config.serverPort,
          authToken: widget.authToken,
        );

    _ownsSpeechTranscriptionService = widget.speechTranscriptionService == null;
    _speechTranscriptionService =
        widget.speechTranscriptionService ??
        SpeechTranscriptionService(apiBaseUrl: widget.config.httpUrl);

    _historyService = widget.historyService;
    _loadHistoryService();
    _setupRecognitionListeners();

    if (widget.autoConnect) {
      _connectRecognition();
    }
  }

  Future<void> _loadHistoryService() async {
    if (_historyService != null) {
      return;
    }

    final service = await ConversationHistoryService.create();
    if (mounted) {
      setState(() {
        _historyService = service;
      });
    }
  }

  void _setupRecognitionListeners() {
    _connectionSubscription = _recognitionService.connectionStream.listen((
      connected,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecognitionConnected = connected;
        if (connected) {
          _recognitionError = null;
        }
      });
    });

    _signSubscription = _recognitionService.signStream.listen((result) {
      if (!mounted || _activeRole != ConversationRole.signer) {
        return;
      }

      final currentText = _draftController.text.trim();
      final nextText = currentText.isEmpty
          ? result.sign
          : '$currentText ${result.sign}';

      setState(() {
        _draftController.text = nextText;
        _draftController.selection = TextSelection.collapsed(
          offset: _draftController.text.length,
        );
        _draftSource = ConversationMessageSource.recognition;
        _draftConfidence = result.confidence;
      });
    });

    _phraseSubscription = _recognitionService.phraseStream.listen((phrase) {
      if (!mounted || _activeRole != ConversationRole.signer) {
        return;
      }

      final confidence = _averageConfidence(phrase.signs);
      setState(() {
        _draftController.text = phrase.text;
        _draftController.selection = TextSelection.collapsed(
          offset: _draftController.text.length,
        );
        _draftSource = ConversationMessageSource.recognition;
        _draftConfidence = confidence;
        _lastAudioData = phrase.audio;
      });
    });
  }

  Future<void> _connectRecognition() async {
    try {
      await _recognitionService.connect();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isRecognitionConnected = false;
        _recognitionError = 'Recognition offline';
      });
    }
  }

  @override
  void dispose() {
    _signSubscription?.cancel();
    _phraseSubscription?.cancel();
    _connectionSubscription?.cancel();
    _draftController.dispose();
    _audioPlayer.dispose();
    _audioRecorder.dispose();
    if (_ownsSpeechTranscriptionService) {
      _speechTranscriptionService.dispose();
    }
    if (_ownsRecognitionService) {
      _recognitionService.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversation'),
        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
          IconButton(
            tooltip: _isRecognitionConnected ? 'Connected' : 'Reconnect',
            icon: Icon(
              _isRecognitionConnected ? Icons.cloud_done : Icons.cloud_off,
              color: _isRecognitionConnected ? Colors.green : Colors.red,
            ),
            onPressed: _isRecognitionConnected ? null : _connectRecognition,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: _ParticipantPanel(
                role: ConversationRole.speaker,
                activeRole: _activeRole,
                messages: _messages,
                isRotated: true,
                accentColor: Colors.blue,
                activeInput: _buildSpeakerInput(),
              ),
            ),
            _buildTurnControl(),
            Expanded(
              child: _ParticipantPanel(
                role: ConversationRole.signer,
                activeRole: _activeRole,
                messages: _messages,
                isRotated: false,
                accentColor: Colors.green,
                activeInput: _buildSignerInput(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTurnControl() {
    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.symmetric(
          horizontal: BorderSide(color: Theme.of(context).dividerColor),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: SegmentedButton<ConversationRole>(
              segments: const [
                ButtonSegment(
                  value: ConversationRole.signer,
                  icon: Icon(Icons.back_hand),
                  label: Text('Sign'),
                ),
                ButtonSegment(
                  value: ConversationRole.speaker,
                  icon: Icon(Icons.mic),
                  label: Text('Speak'),
                ),
              ],
              selected: {_activeRole},
              onSelectionChanged: (selection) {
                _switchRole(selection.first);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'Save',
            onPressed: _isSaving ? null : _saveCurrentSession,
            icon: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
          ),
        ],
      ),
    );
  }

  Widget _buildSignerInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 112,
          height: 72,
          child: widget.enableCamera
              ? CameraPreviewWithMediaPipe(
                  onLandmarks: _onLandmarksDetected,
                  lensDirection: _lensDirection,
                  targetFps: widget.config.targetFps,
                  enableLandmarkDetection: _isRecognitionConnected,
                  config: widget.config,
                )
              : const _CameraPlaceholder(),
        ),
        IconButton(
          tooltip: 'Camera',
          onPressed: _toggleCamera,
          icon: Icon(
            _lensDirection == CameraLensDirection.back
                ? Icons.camera_rear
                : Icons.camera_front,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DraftComposer(
            controller: _draftController,
            hintText: 'Signer text',
            source: _recognitionError == null
                ? _draftSource
                : ConversationMessageSource.manual,
            confidence: _draftConfidence,
            onChanged: () {
              _draftSource = ConversationMessageSource.manual;
              _draftConfidence = null;
            },
            onConfirm: () => _confirmDraft(playAudio: false),
            onConfirmAndPlay: _lastAudioData == null
                ? null
                : () => _confirmDraft(playAudio: true),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeakerInput() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton.filledTonal(
          tooltip: _isSpeechCaptureActive ? 'Stop' : 'Speak',
          onPressed: _isTranscribing ? null : _toggleSpeechCapture,
          icon: _isTranscribing
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(_isSpeechCaptureActive ? Icons.stop : Icons.mic),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _DraftComposer(
            controller: _draftController,
            hintText: 'Speaker text',
            source: _speechCaptureTouched
                ? ConversationMessageSource.speech
                : ConversationMessageSource.manual,
            confidence: null,
            onChanged: () {
              if (!_isSpeechCaptureActive) {
                _speechCaptureTouched = false;
              }
            },
            onConfirm: () => _confirmDraft(playAudio: false),
            onConfirmAndPlay: null,
          ),
        ),
      ],
    );
  }

  void _switchRole(ConversationRole role) {
    if (role == _activeRole) {
      return;
    }

    _confirmDraft(playAudio: false);

    setState(() {
      _activeRole = role;
      _draftController.clear();
      _draftSource = ConversationMessageSource.manual;
      _draftConfidence = null;
      _lastAudioData = null;
      _isSpeechCaptureActive = false;
      _speechCaptureTouched = false;
    });
  }

  Future<void> _confirmDraft({required bool playAudio}) async {
    final text = _draftController.text.trim();
    if (text.isEmpty) {
      return;
    }

    final source = _activeRole == ConversationRole.signer
        ? _draftSource
        : (_speechCaptureTouched
              ? ConversationMessageSource.speech
              : ConversationMessageSource.manual);

    final message = ConversationMessage(
      id: 'message-${DateTime.now().microsecondsSinceEpoch}',
      role: _activeRole,
      source: source,
      status: ConversationMessageStatus.confirmed,
      text: text,
      timestamp: DateTime.now(),
      confidence: _activeRole == ConversationRole.signer
          ? _draftConfidence
          : null,
    );

    setState(() {
      _messages.add(message);
      _draftController.clear();
      _draftSource = ConversationMessageSource.manual;
      _draftConfidence = null;
      _isSpeechCaptureActive = false;
      _speechCaptureTouched = false;
    });

    if (playAudio) {
      await _playLastAudio();
    }

    await _saveCurrentSession();
  }

  Future<void> _saveCurrentSession() async {
    final service = _historyService;
    if (service == null || !_messages.any((message) => message.isConfirmed)) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      _session = _session.copyWith(
        endedAt: DateTime.now(),
        messages: List<ConversationMessage>.from(_messages),
      );
      await service.saveSession(_session);
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _playLastAudio() async {
    final audioData = _lastAudioData;
    if (audioData == null || audioData.isEmpty) {
      return;
    }

    try {
      await _audioPlayer.play(BytesSource(base64Decode(audioData)));
    } catch (_) {
      try {
        final uriData = UriData.parse(audioData);
        await _audioPlayer.play(BytesSource(uriData.contentAsBytes()));
      } catch (_) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Audio unavailable')));
        }
      }
    }
  }

  Future<void> _toggleSpeechCapture() async {
    if (_isSpeechCaptureActive) {
      await _stopSpeechCapture();
      return;
    }

    await _startSpeechCapture();
  }

  Future<void> _startSpeechCapture() async {
    final hasPermission = await _audioRecorder.hasPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Microphone unavailable')));
      }
      return;
    }

    final tempDirectory = await getTemporaryDirectory();
    final path =
        '${tempDirectory.path}/vsl-speech-${DateTime.now().microsecondsSinceEpoch}.m4a';

    await _audioRecorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc),
      path: path,
    );

    setState(() {
      _isSpeechCaptureActive = true;
      _speechCaptureTouched = true;
    });
  }

  Future<void> _stopSpeechCapture() async {
    setState(() {
      _isSpeechCaptureActive = false;
      _isTranscribing = true;
      _speechCaptureTouched = true;
    });

    try {
      final path = await _audioRecorder.stop();
      if (path == null) {
        return;
      }

      final audioBytes = await File(path).readAsBytes();
      final transcript = await _speechTranscriptionService.transcribeAudioBytes(
        audioBytes,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _draftController.text = transcript;
        _draftController.selection = TextSelection.collapsed(
          offset: _draftController.text.length,
        );
      });
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Speech unavailable')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isTranscribing = false;
        });
      }
    }
  }

  void _toggleCamera() {
    setState(() {
      _lensDirection = _lensDirection == CameraLensDirection.back
          ? CameraLensDirection.front
          : CameraLensDirection.back;
    });
  }

  void _onLandmarksDetected(HolisticLandmarksPayload payload) {
    if (_activeRole != ConversationRole.signer || !_isRecognitionConnected) {
      return;
    }

    final payloadWithSession = HolisticLandmarksPayload(
      pose: payload.pose,
      left: payload.left,
      right: payload.right,
      timestamp: payload.timestamp,
      sessionId: payload.sessionId.isEmpty
          ? _recognitionService.sessionId ?? ''
          : payload.sessionId,
    );

    _recognitionService.sendLandmarks(payloadWithSession);
  }

  Future<void> _openHistory() async {
    await _saveCurrentSession();

    if (!mounted) {
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            ConversationHistoryScreen(historyService: _historyService),
      ),
    );
  }

  double? _averageConfidence(List<RecognitionResult> signs) {
    if (signs.isEmpty) {
      return null;
    }
    final sum = signs.fold<double>(0, (total, sign) => total + sign.confidence);
    return sum / signs.length;
  }
}

class _ParticipantPanel extends StatelessWidget {
  final ConversationRole role;
  final ConversationRole activeRole;
  final List<ConversationMessage> messages;
  final bool isRotated;
  final Color accentColor;
  final Widget activeInput;

  const _ParticipantPanel({
    required this.role,
    required this.activeRole,
    required this.messages,
    required this.isRotated,
    required this.accentColor,
    required this.activeInput,
  });

  @override
  Widget build(BuildContext context) {
    final content = _ParticipantPanelContent(
      role: role,
      isActive: role == activeRole,
      messages: messages,
      accentColor: accentColor,
      activeInput: activeInput,
    );

    if (!isRotated) {
      return content;
    }

    return Transform.rotate(angle: math.pi, child: content);
  }
}

class _ParticipantPanelContent extends StatelessWidget {
  final ConversationRole role;
  final bool isActive;
  final List<ConversationMessage> messages;
  final Color accentColor;
  final Widget activeInput;

  const _ParticipantPanelContent({
    required this.role,
    required this.isActive,
    required this.messages,
    required this.accentColor,
    required this.activeInput,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Color.alphaBlend(
        accentColor.withValues(alpha: 0.05),
        Colors.white,
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                role == ConversationRole.signer ? Icons.back_hand : Icons.mic,
                color: accentColor,
              ),
              const SizedBox(width: 8),
              Text(
                role.label,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              _StatusPill(
                label: isActive ? 'Active' : 'Reading',
                color: isActive ? accentColor : Colors.grey,
                icon: isActive ? Icons.radio_button_checked : Icons.visibility,
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isActive)
            Flexible(
              flex: 3,
              child: _ConversationTimeline(
                messages: messages,
                perspectiveRole: role,
                accentColor: accentColor,
              ),
            )
          else
            Expanded(
              child: _ConversationTimeline(
                messages: messages,
                perspectiveRole: role,
                accentColor: accentColor,
              ),
            ),
          if (isActive) ...[
            const SizedBox(height: 8),
            Flexible(flex: 4, child: SingleChildScrollView(child: activeInput)),
          ],
        ],
      ),
    );
  }
}

class _ConversationTimeline extends StatelessWidget {
  final List<ConversationMessage> messages;
  final ConversationRole perspectiveRole;
  final Color accentColor;

  const _ConversationTimeline({
    required this.messages,
    required this.perspectiveRole,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) {
      return Center(
        child: Icon(
          Icons.forum_outlined,
          size: 40,
          color: Theme.of(context).disabledColor,
        ),
      );
    }

    return ListView.builder(
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];
        final isOwn = message.role == perspectiveRole;
        return Align(
          alignment: isOwn ? Alignment.centerRight : Alignment.centerLeft,
          child: _MessageBubble(message: message, isOwn: isOwn),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final bool isOwn;

  const _MessageBubble({required this.message, required this.isOwn});

  @override
  Widget build(BuildContext context) {
    final color = message.role == ConversationRole.signer
        ? Colors.green
        : Colors.blue;
    final background = Color.alphaBlend(
      color.withValues(alpha: 0.12),
      Colors.white,
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 280),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.32)),
        ),
        child: Column(
          crossAxisAlignment: isOwn
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: const TextStyle(fontSize: 15, height: 1.25),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  message.role.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  message.source.label,
                  style: TextStyle(color: Colors.grey[700], fontSize: 11),
                ),
                if (message.isLowConfidence)
                  const Text(
                    'Unclear',
                    style: TextStyle(
                      color: Colors.amber,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DraftComposer extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final ConversationMessageSource source;
  final double? confidence;
  final VoidCallback onChanged;
  final VoidCallback onConfirm;
  final VoidCallback? onConfirmAndPlay;

  const _DraftComposer({
    required this.controller,
    required this.hintText,
    required this.source,
    required this.confidence,
    required this.onChanged,
    required this.onConfirm,
    this.onConfirmAndPlay,
  });

  @override
  Widget build(BuildContext context) {
    final confidence = this.confidence;
    final lowConfidence = confidence != null && confidence < 0.6;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: lowConfidence ? Colors.amber : Theme.of(context).dividerColor,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _StatusPill(
            label: lowConfidence ? 'Unclear' : source.label,
            color: lowConfidence ? Colors.amber : Colors.grey,
            icon: lowConfidence ? Icons.warning_amber : Icons.edit,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: hintText,
                isDense: true,
                border: InputBorder.none,
              ),
              onChanged: (_) => onChanged(),
            ),
          ),
          if (onConfirmAndPlay != null)
            IconButton(
              tooltip: 'Confirm & Play',
              onPressed: onConfirmAndPlay,
              icon: const Icon(Icons.volume_up),
            ),
          IconButton.filled(
            key: const ValueKey('confirm_draft_button'),
            tooltip: 'Confirm',
            onPressed: onConfirm,
            icon: const Icon(Icons.check),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusPill({
    required this.label,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Center(child: Icon(Icons.videocam_off)),
    );
  }
}
