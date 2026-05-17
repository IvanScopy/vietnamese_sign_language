"""
Sliding window buffer for LSTM sequence aggregation.
"""

import numpy as np
from typing import Optional, List, Union, Dict


class SlidingWindowBuffer:
    """Sliding window buffer for feature vectors."""
    
    def __init__(self, window_size: int = 30, stride: int = 1, feature_size: int = 225):
        self.window_size = window_size
        self.stride = stride
        self.feature_size = feature_size
        self._buffer: List[np.ndarray] = []
        self._signs_buffer: List[Dict] = []

    def add_landmarks(self, frame: Union[np.ndarray, List[float]]) -> Optional[np.ndarray]:
        """Add feature vector and return window if full."""
        # Convert to numpy
        if not isinstance(frame, np.ndarray):
            frame = np.array(frame, dtype=np.float32)

        # Validate shape - expecting MediaPipe pose + both hands.
        if frame.shape != (self.feature_size,):
            raise ValueError(
                f"Expected feature vector shape ({self.feature_size},), got {frame.shape}"
            )

        self._buffer.append(frame)

        if len(self._buffer) >= self.window_size:
            window = np.array(self._buffer[-self.window_size:], dtype=np.float32)
            return window
        return None

    def is_ready(self) -> bool:
        return len(self._buffer) >= self.window_size

    def clear(self):
        """Reset buffers."""
        self._buffer.clear()
        self._signs_buffer.clear()

    def get_buffer_size(self) -> int:
        return len(self._buffer)

    def get_accumulated_signs(self) -> List[Dict]:
        return self._signs_buffer.copy()

    def add_sign(self, sign_result: Dict):
        """Add a recognized sign to the phrase buffer."""
        self._signs_buffer.append(sign_result)
