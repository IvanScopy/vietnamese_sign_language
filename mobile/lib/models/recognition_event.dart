import 'package:json_annotation/json_annotation.dart';

part 'recognition_event.g.dart';

/// Single recognized sign result from the classifier.
@JsonSerializable()
class RecognitionResult {
  /// The recognized Vietnamese sign (e.g., 'xin_chào', 'cảm_ơn')
  final String sign;

  /// Confidence score from the model (0.0 to 1.0)
  @JsonKey(name: 'confidence')
  final double confidence;

  const RecognitionResult({
    required this.sign,
    required this.confidence,
  });

  factory RecognitionResult.fromJson(Map<String, dynamic> json) =>
      _$RecognitionResultFromJson(json);

  Map<String, dynamic> toJson() => _$RecognitionResultToJson(this);

  @override
  String toString() => 'RecognitionResult(sign: $sign, confidence: $confidence)';
}

/// Phrase completion event - sent when a phrase boundary is detected.
@JsonSerializable()
class PhraseComplete {
  /// The complete recognized text (concatenated signs)
  final String text;

  /// Individual sign results that make up the phrase
  final List<RecognitionResult> signs;

  /// Optional base64-encoded audio for TTS output
  final String? audio;

  const PhraseComplete({
    required this.text,
    required this.signs,
    this.audio,
  });

  factory PhraseComplete.fromJson(Map<String, dynamic> json) =>
      _$PhraseCompleteFromJson(json);

  Map<String, dynamic> toJson() => _$PhraseCompleteToJson(this);

  @override
  String toString() =>
      'PhraseComplete(text: $text, signs: ${signs.length}, audio: ${audio != null})';
}
