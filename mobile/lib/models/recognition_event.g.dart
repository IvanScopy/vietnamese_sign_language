// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recognition_event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RecognitionResult _$RecognitionResultFromJson(Map<String, dynamic> json) =>
    RecognitionResult(
      sign: json['sign'] as String,
      confidence: (json['confidence'] as num).toDouble(),
    );

Map<String, dynamic> _$RecognitionResultToJson(RecognitionResult instance) =>
    <String, dynamic>{'sign': instance.sign, 'confidence': instance.confidence};

PhraseComplete _$PhraseCompleteFromJson(Map<String, dynamic> json) =>
    PhraseComplete(
      text: json['text'] as String,
      signs: (json['signs'] as List<dynamic>)
          .map((e) => RecognitionResult.fromJson(e as Map<String, dynamic>))
          .toList(),
      audio: json['audio'] as String?,
    );

Map<String, dynamic> _$PhraseCompleteToJson(PhraseComplete instance) =>
    <String, dynamic>{
      'text': instance.text,
      'signs': instance.signs,
      'audio': instance.audio,
    };
