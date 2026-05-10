// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'landmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Landmark _$LandmarkFromJson(Map<String, dynamic> json) => Landmark(
  x: (json['x'] as num).toDouble(),
  y: (json['y'] as num).toDouble(),
  z: (json['z'] as num).toDouble(),
  visibility: (json['visibility'] as num).toDouble(),
);

Map<String, dynamic> _$LandmarkToJson(Landmark instance) => <String, dynamic>{
  'x': instance.x,
  'y': instance.y,
  'z': instance.z,
  'visibility': instance.visibility,
};

HandLandmarks _$HandLandmarksFromJson(Map<String, dynamic> json) =>
    HandLandmarks(
      handedness: json['handedness'] as String,
      landmarks: (json['landmarks'] as List<dynamic>)
          .map((e) => Landmark.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$HandLandmarksToJson(HandLandmarks instance) =>
    <String, dynamic>{
      'handedness': instance.handedness,
      'landmarks': instance.landmarks.map((e) => e.toJson()).toList(),
    };

LandmarksPayload _$LandmarksPayloadFromJson(Map<String, dynamic> json) =>
    LandmarksPayload(
      left: json['left'] == null
          ? null
          : HandLandmarks.fromJson(json['left'] as Map<String, dynamic>),
      right: json['right'] == null
          ? null
          : HandLandmarks.fromJson(json['right'] as Map<String, dynamic>),
      timestamp: (json['timestamp'] as num).toInt(),
      sessionId: json['sessionId'] as String,
    );

Map<String, dynamic> _$LandmarksPayloadToJson(LandmarksPayload instance) =>
    <String, dynamic>{
      'left': instance.left?.toJson(),
      'right': instance.right?.toJson(),
      'timestamp': instance.timestamp,
      'sessionId': instance.sessionId,
    };
