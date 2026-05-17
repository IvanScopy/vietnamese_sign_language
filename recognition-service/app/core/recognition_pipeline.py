"""
Recognition Pipeline: landmarks -> buffer -> classifier.
"""

from typing import Optional, Dict, Any, List
import numpy as np
from app.core.sliding_window import SlidingWindowBuffer
from app.models.classifier import create_classifier


class RecognitionPipeline:
    """End-to-end recognition pipeline."""
    PHRASE_TIMEOUT_MS = 2500

    def __init__(self, window_size: int = 30, classifier=None):
        self.classifier = classifier or create_classifier(window_size=window_size)
        self.window_size = getattr(self.classifier, 'window_size', window_size)
        self.feature_count = getattr(self.classifier, 'feature_count', 225)
        self.buffer = SlidingWindowBuffer(
            window_size=self.window_size,
            feature_size=self.feature_count,
        )
        self._last_sign_time = 0
        self._phrase_buffer: List[Dict[str, Any]] = []

    def process_landmarks(self, payload: Dict[str, Any]) -> Optional[Dict[str, Any]]:
        """
        Process landmarks payload.

        Args:
            payload: Dict with landmarks, timestamp, sessionId

        Returns:
            Recognition result or None if buffer not full
        """
        frame = self._extract_features(payload['landmarks'])
        window = self.buffer.add_landmarks(frame)

        if window is None:
            return None

        result = self.classifier.predict(window)
        self._last_sign_time = payload['timestamp']
        # Accumulate sign for phrase building
        self._phrase_buffer.append(result)

        return {
            'sign': result['sign'],
            'confidence': result['confidence'],
            'timestamp': payload['timestamp']
        }

    def check_phrase_complete(self, current_time: int) -> bool:
        if self._last_sign_time == 0:
            return False
        return (current_time - self._last_sign_time) > self.PHRASE_TIMEOUT_MS

    def get_phrase(self) -> List[Dict[str, Any]]:
        phrase = self._phrase_buffer.copy()
        self._phrase_buffer.clear()
        self.buffer.clear()
        self._last_sign_time = 0
        return phrase

    def _extract_features(self, landmarks: Dict[str, Any]) -> np.ndarray:
        """
        Extract a 225-dim feature vector from holistic landmarks dict.

        Feature vector format:
        - Pose: 33 MediaPipe pose landmarks × 3 (x, y, z) = 99 features
        - Left hand: 21 landmarks × 3 = 63 features
        - Right hand: 21 landmarks × 3 = 63 features
        Total: 225 dimensions

        Missing landmarks are filled with zeros for graceful degradation.
        """
        pose_count = 33
        hand_count = 21
        coords = 3
        pose_size = pose_count * coords
        hand_size = hand_count * coords
        features = np.zeros(pose_size + (2 * hand_size), dtype=np.float32)

        # Pose landmarks (indices 0-98)
        if 'pose' in landmarks and landmarks['pose']:
            pose = landmarks['pose']['landmarks']
            for i, lm in enumerate(pose[:pose_count]):
                base = i * 3
                features[base] = lm['x']
                features[base + 1] = lm['y']
                features[base + 2] = lm['z']

        # Left hand landmarks (indices 99-161)
        if 'left' in landmarks and landmarks['left']:
            left = landmarks['left']['landmarks']
            for i, lm in enumerate(left[:hand_count]):
                base = pose_size + (i * 3)
                features[base] = lm['x']
                features[base + 1] = lm['y']
                features[base + 2] = lm['z']

        # Right hand landmarks (indices 162-224)
        if 'right' in landmarks and landmarks['right']:
            right = landmarks['right']['landmarks']
            for i, lm in enumerate(right[:hand_count]):
                base = pose_size + hand_size + (i * 3)
                features[base] = lm['x']
                features[base + 1] = lm['y']
                features[base + 2] = lm['z']

        return features

    def clear_phrase(self):
        self._phrase_buffer.clear()
        self.buffer.clear()
        self._last_sign_time = 0
