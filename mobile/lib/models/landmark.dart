import 'package:json_annotation/json_annotation.dart';

part 'landmark.g.dart';

/// Single 3D landmark point from MediaPipe.
/// Coordinates are normalized [0, 1] relative to image dimensions.
@JsonSerializable()
class Landmark {
  final double x;
  final double y;
  final double z;
  final double visibility;

  const Landmark({
    required this.x,
    required this.y,
    required this.z,
    required this.visibility,
  });

  factory Landmark.fromJson(Map<String, dynamic> json) =>
      _$LandmarkFromJson(json);

  Map<String, dynamic> toJson() => _$LandmarkToJson(this);

  @override
  String toString() =>
      'Landmark(x: $x, y: $y, z: $z, visibility: $visibility)';
}

/// Hand landmarks container.
/// MediaPipe detects 21 landmarks per hand in standard format.
@JsonSerializable(explicitToJson: true)
class HandLandmarks {
  /// 'Left' or 'Right' - handedness of the detected hand
  final String handedness;

  /// Array of exactly 21 landmark points
  final List<Landmark> landmarks;

  const HandLandmarks({
    required this.handedness,
    required this.landmarks,
  });

  factory HandLandmarks.fromJson(Map<String, dynamic> json) =>
      _$HandLandmarksFromJson(json);

  Map<String, dynamic> toJson() => _$HandLandmarksToJson(this);

  @override
  String toString() => 'HandLandmarks(handedness: $handedness, landmarks: ${landmarks.length})';
}

/// Complete landmarks payload from client to recognition service.
/// Contains landmarks for both hands (either may be optional).
@JsonSerializable(explicitToJson: true)
class LandmarksPayload {
  /// Left hand landmarks (optional - may not be visible)
  @JsonKey(name: 'left')
  final HandLandmarks? left;

  /// Right hand landmarks (optional - may not be visible)
  @JsonKey(name: 'right')
  final HandLandmarks? right;

  /// Unix timestamp in milliseconds when frame was captured
  final int timestamp;

  /// Unique session identifier for the recognition session
  @JsonKey(name: 'sessionId')
  final String sessionId;

  const LandmarksPayload({
    this.left,
    this.right,
    required this.timestamp,
    required this.sessionId,
  });

  factory LandmarksPayload.fromJson(Map<String, dynamic> json) =>
      _$LandmarksPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$LandmarksPayloadToJson(this);

  @override
  String toString() =>
      'LandmarksPayload(left: ${left != null}, right: ${right != null}, timestamp: $timestamp, sessionId: $sessionId)';
}
