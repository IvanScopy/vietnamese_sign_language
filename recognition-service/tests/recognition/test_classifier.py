"""Unit tests for MockLSTM classifier."""
import pytest
import numpy as np
from app.models.mock_lstm import MockLSTM
from app.models.vocabulary import VOCABULARY


class TestMockLSTM:
    """Test suite for mock LSTM classifier."""

    def test_predict_returns_dict_with_keys(self):
        """predict() returns dict with 'sign' and 'confidence' keys."""
        classifier = MockLSTM()
        window = np.random.rand(30, classifier.feature_count).astype(np.float32)
        result = classifier.predict(window)
        assert 'sign' in result
        assert 'confidence' in result

    def test_predict_sign_in_vocabulary(self):
        """Returned sign is always from vocabulary."""
        classifier = MockLSTM()
        window = np.random.rand(30, classifier.feature_count).astype(np.float32)
        for _ in range(20):
            result = classifier.predict(window)
            assert result['sign'] in VOCABULARY

    def test_predict_confidence_range(self):
        """Confidence is between 0.5 and 0.95."""
        classifier = MockLSTM()
        window = np.random.rand(30, classifier.feature_count).astype(np.float32)
        for _ in range(20):
            result = classifier.predict(window)
            conf = result['confidence']
            assert 0.5 <= conf <= 0.95, f"Confidence {conf} out of range"

    def test_predict_invalid_shape_raises(self):
        """predict() raises ValueError for wrong input shape."""
        classifier = MockLSTM()
        with pytest.raises(ValueError):
            classifier.predict(np.random.rand(10, classifier.feature_count))  # Too few timesteps
        with pytest.raises(ValueError):
            classifier.predict(np.random.rand(30, 100))  # Wrong features

    def test_predict_non_numpy_raises(self):
        """predict() raises ValueError for non-numpy input."""
        classifier = MockLSTM()
        with pytest.raises(ValueError):
            classifier.predict([[0.0] * classifier.feature_count] * 30)
