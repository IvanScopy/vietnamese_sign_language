"""
Pydantic schemas for landmark payloads.
Supporting MediaPipe Holistic output (pose + hands).
"""

from pydantic import BaseModel, field_validator
from typing import Optional, Dict, Any, List


class Landmark(BaseModel):
    """Single 3D landmark point."""
    x: float
    y: float
    z: float
    visibility: float = 1.0


class HandLandmarks(BaseModel):
    """Hand landmarks with handedness."""
    handedness: str
    landmarks: List[Landmark]

    @field_validator('landmarks')
    @classmethod
    def validate_hand_landmarks_count(cls, v):
        """Validate exactly 21 hand landmarks."""
        if len(v) != 21:
            raise ValueError(f'Hand must have exactly 21 landmarks, got {len(v)}')
        return v


class PoseLandmarks(BaseModel):
    """MediaPipe pose landmarks."""
    landmarks: List[Landmark]

    @field_validator('landmarks')
    @classmethod
    def validate_pose_landmarks_count(cls, v):
        """Validate exactly 33 MediaPipe pose landmarks."""
        if len(v) != 33:
            raise ValueError(f'Pose must have exactly 33 landmarks, got {len(v)}')
        return v


class LandmarksPayload(BaseModel):
    """Complete landmarks payload from client."""
    landmarks: Dict[str, Any]
    timestamp: int
    sessionId: str

    @field_validator('landmarks')
    @classmethod
    def validate_landmarks_structure(cls, v):
        """Validate landmarks dict has proper structure."""
        if not isinstance(v, dict):
            raise ValueError('landmarks must be a dictionary')

        # At least one of pose, left, or right must be present
        has_pose = 'pose' in v and v['pose'] is not None
        has_left = 'left' in v and v['left'] is not None
        has_right = 'right' in v and v['right'] is not None

        if not (has_pose or has_left or has_right):
            raise ValueError('At least one of pose, left, or right landmarks required')

        # Validate pose if present
        if has_pose:
            pose_data = v['pose']
            if not isinstance(pose_data, dict):
                raise ValueError('pose must be a dictionary')
            if 'landmarks' not in pose_data:
                raise ValueError('pose missing landmarks')
            if len(pose_data['landmarks']) != 33:
                raise ValueError(f'pose must have exactly 33 landmarks, got {len(pose_data["landmarks"])}')

        # Validate left hand if present
        if has_left:
            hand = v['left']
            if not isinstance(hand, dict):
                raise ValueError('left must be a dictionary')
            if 'handedness' not in hand:
                raise ValueError('left missing handedness')
            if 'landmarks' not in hand:
                raise ValueError('left missing landmarks')
            if len(hand['landmarks']) != 21:
                raise ValueError(f'left must have exactly 21 landmarks, got {len(hand["landmarks"])}')

        # Validate right hand if present
        if has_right:
            hand = v['right']
            if not isinstance(hand, dict):
                raise ValueError('right must be a dictionary')
            if 'handedness' not in hand:
                raise ValueError('right missing handedness')
            if 'landmarks' not in hand:
                raise ValueError('right missing landmarks')
            if len(hand['landmarks']) != 21:
                raise ValueError(f'right must have exactly 21 landmarks, got {len(hand["landmarks"])}')

        return v
