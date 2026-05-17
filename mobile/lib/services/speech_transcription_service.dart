import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

class SpeechTranscriptionService {
  final String apiBaseUrl;
  final http.Client _client;

  SpeechTranscriptionService({required this.apiBaseUrl, http.Client? client})
    : _client = client ?? http.Client();

  Future<String> transcribeAudioBytes(
    Uint8List audioBytes, {
    String filename = 'speech.m4a',
    String language = 'vi',
  }) async {
    final uri = Uri.parse('$apiBaseUrl/api/stt/transcribe');
    final request = http.MultipartRequest('POST', uri)
      ..fields['language'] = language
      ..files.add(
        http.MultipartFile.fromBytes('audio', audioBytes, filename: filename),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SpeechTranscriptionException(
        'Transcription failed with status ${response.statusCode}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map || decoded['transcript'] is! String) {
      throw SpeechTranscriptionException('Transcription response is invalid');
    }

    return decoded['transcript'] as String;
  }

  void dispose() {
    _client.close();
  }
}

class SpeechTranscriptionException implements Exception {
  final String message;

  SpeechTranscriptionException(this.message);

  @override
  String toString() => message;
}
