/**
 * Shared TypeScript definitions for MediaPipe hand landmarks.
 *
 * These types define the contract between clients (Flutter/React) and the
 * recognition service for hand landmark data.
 *
 * MediaPipe returns normalized coordinates in the range [0, 1] for x, y, z.
 * Visibility represents confidence of landmark detection (0-1).
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
 * Complete landmarks payload from client to recognition service.
 * Contains landmarks for both hands (either may be optional).
 */
export interface LandmarksPayload {
  /** Left hand landmarks (optional - may not be visible) */
  left?: HandLandmarks;
  /** Right hand landmarks (optional - may not be visible) */
  right?: HandLandmarks;
  /** Unix timestamp in milliseconds when frame was captured */
  timestamp: number;
  /** Unique session identifier for the recognition session */
  sessionId: string;
}
