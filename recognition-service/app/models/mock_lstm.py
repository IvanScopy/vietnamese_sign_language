"""
Mock LSTM classifier for development.
"""

import random
import numpy as np
from typing import Dict, Any, List
from app.models.vocabulary import VOCABULARY


class MockLSTM:
    """Mock LSTM classifier for development."""

    def __init__(self, expected_window_size: int = 30):
        self.vocabulary = VOCABULARY
        self.expected_window_size = expected_window_size
        self.window_size = expected_window_size
        self.feature_count = 225
        self.model_name = 'mock_lstm'
        self.loaded = True
        self._weights = self._build_weights()
    
    def _build_weights(self) -> List[float]:
        weights = []
        common_signs = ['xin_chào', 'cảm_ơn', 'tôi', 'bạn', 'ạ']
        for sign in self.vocabulary:
            weights.append(2.0 if sign in common_signs else 1.0)
        return weights
    
    def predict(self, window: Any) -> Dict[str, Any]:
        """Predict sign from window."""
        # Validate numpy array
        if not isinstance(window, np.ndarray):
            raise ValueError(f"Expected numpy array, got {type(window)}")

        # Validate shape
        if len(window.shape) != 2:
            raise ValueError(f"Expected 2D array, got {len(window.shape)}D")
        if window.shape[1] != self.feature_count:
            raise ValueError(
                f"Expected {self.feature_count} features "
                f"(Holistic: pose33+hands42), got {window.shape[1]}"
            )
        if window.shape[0] != self.expected_window_size:
            raise ValueError(f"Expected {self.expected_window_size} timesteps, got {window.shape[0]}")

        sign = random.choices(self.vocabulary, weights=self._weights)[0]
        confidence = random.uniform(0.5, 0.95)

        return {'sign': sign, 'confidence': round(confidence, 4)}
