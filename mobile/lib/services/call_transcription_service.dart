import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:mobile/services/speech_transcription_service.dart';

/// Wraps existing STT and TTS services for in-call use.
///
/// Handles:
/// - Speech transcription during active calls
/// - TTS synthesis via POST /api/tts/synthesize
/// - Sending confirmed sign text to hearing user via API
class CallTranscriptionService {
  final String apiBaseUrl;
  final String authToken;
  final SpeechTranscriptionService _sttService;
  final http.Client _httpClient;

  CallTranscriptionService({
    required this.apiBaseUrl,
    required this.authToken,
    SpeechTranscriptionService? sttService,
  })  : _sttService = sttService ?? SpeechTranscriptionService(apiBaseUrl: apiBaseUrl),
        _httpClient = http.Client();

  /// Transcribe speech audio bytes during an active call.
  Future<String> transcribeSpeech(Uint8List audioBytes) async {
    return _sttService.transcribeAudioBytes(audioBytes);
  }

  /// Synthesize TTS audio from text via the TTS API endpoint.
  ///
  /// POST /api/tts/synthesize with { text, language: 'vi' }
  /// Returns audio data URL or base64 string on success.
  Future<String?> synthesizeTTS(String text) async {
    final uri = Uri.parse('$apiBaseUrl/api/tts/synthesize');
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $authToken',
      },
      body: jsonEncode({
        'text': text,
        'language': 'vi',
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw TTSException('TTS synthesis failed with status ${response.statusCode}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) {
      throw TTSException('TTS response is invalid');
    }

    // Accept either 'audio' (base64) or 'audioUrl' (data URL)
    if (decoded['audioUrl'] is String) {
      return decoded['audioUrl'] as String;
    }
    if (decoded['audio'] is String) {
      return decoded['audio'] as String;
    }

    throw TTSException('TTS response contains no audio data');
  }

  /// Send confirmed sign text to hearing user for display as text overlay.
  ///
  /// This sends the text via the API so it can be relayed to the other
  /// participant via Socket.io or stored for the call transcript.
  Future<void> sendTranscriptToHearingUser(String text) async {
    // For v1, this is a no-op placeholder — the text is displayed locally
    // and the hearing user sees it via the existing Socket.io signaling.
    // A dedicated endpoint can be added when real-time text relay is needed.
    // The text will be saved via the transcript save endpoint after the call.
  }

  /// Dispose of HTTP client resources.
  void dispose() {
    _httpClient.close();
  }
}

class TTSException implements Exception {
  final String message;

  TTSException(this.message);

  @override
  String toString() => message;
}
