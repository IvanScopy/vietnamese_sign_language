/**
 * Shared TypeScript definitions for MediaPipe Holistic landmarks.
 *
 * These types define the contract between clients (Flutter/React) and the
 * recognition service for holistic landmark data (pose + hands).
 *
 * MediaPipe returns normalized coordinates in the range [0, 1] for x, y, z.
 * Visibility represents confidence of landmark detection (0-1).
 *
 * Total dimensions: 67 landmarks × 3D = 201 features
 * - Pose: 25 landmarks × 3 = 75 features
 * - Left hand: 21 landmarks × 3 = 63 features
 * - Right hand: 21 landmarks × 3 = 63 features
 */

/**
 * Single 3D landmark point from MediaPipe.
 * Coordinates are normalized [0, 1] relative to image dimensions.
 */
export interface Landmark {
  x: number;
  y: number;
  z: number;
  visibility: number;
}

/**
 * Hand landmarks container.
 * MediaPipe detects 21 landmarks per hand in standard format.
 */
export interface HandLandmarks {
  /** 'Left' or 'Right' - handedness of the detected hand */
  handedness: 'Left' | 'Right';
  /** Array of exactly 21 landmark points */
  landmarks: Landmark[];
}

/**
 * Pose landmarks container.
 * MediaPipe Holistic detects 25 upper body pose landmarks.
 * Indices: 0=nose, 1=left eye inner, 2=left eye, 3=left eye outer,
 * 4=right eye inner, 5=right eye, 6=right eye outer, 7=left ear,
 * 8=right ear, 9=mouth left, 10=mouth right, 11=left shoulder,
 * 12=right shoulder, 13=left elbow, 14=right elbow, 15=left wrist,
 * 16=right wrist, 17=left pinky, 18=right pinky, 19=left index,
 * 20=right index, 21=left thumb, 22=right thumb, 23=left hip,
 * 24=right hip
 */
export interface PoseLandmarks {
  /** Array of exactly 25 landmark points (upper body) */
  landmarks: Landmark[];
}

/**
 * Complete holistic landmarks payload from client to recognition service.
 * Contains pose and hand landmarks (any may be optional for graceful degradation).
 *
 * Feature vector format (201 dimensions):
 * [pose25×3, left_hand21×3, right_hand21×3]
 */
export interface HolisticLandmarksPayload {
  /** Pose landmarks (upper body - optional for backward compatibility) */
  pose?: PoseLandmarks;

  /** Left hand landmarks (optional - may not be visible) */
  left?: HandLandmarks;

  /** Right hand landmarks (optional - may not be visible) */
  right?: HandLandmarks;

  /** Unix timestamp in milliseconds when frame was captured */
  timestamp: number;

  /** Unique session identifier for the recognition session */
  sessionId: string;
}

/**
 * @deprecated Use HolisticLandmarksPayload for new implementations.
 * Kept for backward compatibility with existing hand-only pipelines.
 */
export type HandLandmarksPayload = HolisticLandmarksPayload;
