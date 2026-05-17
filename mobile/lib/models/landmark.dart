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
  String toString() => 'Landmark(x: $x, y: $y, z: $z, visibility: $visibility)';
}

/// Hand landmarks container.
/// MediaPipe detects 21 landmarks per hand in standard format.
@JsonSerializable(explicitToJson: true)
class HandLandmarks {
  /// 'Left' or 'Right' - handedness of the detected hand
  final String handedness;

  /// Array of exactly 21 landmark points
  final List<Landmark> landmarks;

  const HandLandmarks({required this.handedness, required this.landmarks});

  factory HandLandmarks.fromJson(Map<String, dynamic> json) =>
      _$HandLandmarksFromJson(json);

  Map<String, dynamic> toJson() => _$HandLandmarksToJson(this);

  @override
  String toString() =>
      'HandLandmarks(handedness: $handedness, landmarks: ${landmarks.length})';
}

/// Pose landmarks container for MediaPipe Pose Landmarker.
/// Contains 33 MediaPipe pose landmarks.
///
/// Landmark indices:
/// 0=nose, 1=left eye inner, 2=left eye, 3=left eye outer,
/// 4=right eye inner, 5=right eye, 6=right eye outer, 7=left ear,
/// 8=right ear, 9=mouth left, 10=mouth right, 11=left shoulder,
/// 12=right shoulder, 13=left elbow, 14=right elbow, 15=left wrist,
/// 16=right wrist, 17=left pinky, 18=right pinky, 19=left index,
/// 20=right index, 21=left thumb, 22=right thumb, 23=left hip,
/// 24=right hip
@JsonSerializable(explicitToJson: true)
class PoseLandmarks {
  /// Array of exactly 33 landmark points.
  final List<Landmark> landmarks;

  const PoseLandmarks({required this.landmarks});

  factory PoseLandmarks.fromJson(Map<String, dynamic> json) =>
      _$PoseLandmarksFromJson(json);

  Map<String, dynamic> toJson() => _$PoseLandmarksToJson(this);

  @override
  String toString() => 'PoseLandmarks(landmarks: ${landmarks.length})';
}

/// Complete holistic landmarks payload from client to recognition service.
/// Contains pose and hand landmarks for full-body sign language recognition.
///
/// Feature vector format (225 dimensions):
/// - Pose: 33 landmarks × 3 (x, y, z) = 99 features
/// - Left hand: 21 landmarks × 3 = 63 features
/// - Right hand: 21 landmarks × 3 = 63 features
/// Total: 225 dimensions
@JsonSerializable(explicitToJson: true)
class HolisticLandmarksPayload {
  /// Pose landmarks (optional - may not be visible)
  final PoseLandmarks? pose;

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

  const HolisticLandmarksPayload({
    this.pose,
    this.left,
    this.right,
    required this.timestamp,
    required this.sessionId,
  });

  factory HolisticLandmarksPayload.fromJson(Map<String, dynamic> json) =>
      _$HolisticLandmarksPayloadFromJson(json);

  Map<String, dynamic> toJson() => _$HolisticLandmarksPayloadToJson(this);

  @override
  String toString() =>
      'HolisticLandmarksPayload(pose: ${pose != null}, left: ${left != null}, right: ${right != null}, timestamp: $timestamp, sessionId: $sessionId)';
}

/// @deprecated Use HolisticLandmarksPayload for new implementations.
/// Kept for backward compatibility with existing hand-only pipelines.
typedef LandmarksPayload = HolisticLandmarksPayload;
