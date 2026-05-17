"""Unit tests for SlidingWindowBuffer."""
import pytest
import numpy as np
from app.core.sliding_window import SlidingWindowBuffer


class TestSlidingWindowBuffer:
    """Test suite for sliding window buffer."""

    def test_window_fills_after_n_frames(self):
        """Buffer returns complete window after window_size frames."""
        buffer = SlidingWindowBuffer(window_size=3)
        frame = np.random.rand(225).astype(np.float32)

        result1 = buffer.add_landmarks(frame)
        assert result1 is None

        result2 = buffer.add_landmarks(frame)
        assert result2 is None

        result3 = buffer.add_landmarks(frame)
        assert result3 is not None
        assert result3.shape == (3, 225)

    def test_incomplete_window_returns_none(self):
        """Buffer returns None until full."""
        buffer = SlidingWindowBuffer(window_size=5)
        frame = np.random.rand(225).astype(np.float32)

        for i in range(4):
            assert buffer.add_landmarks(frame) is None
        assert buffer.add_landmarks(frame) is not None

    def test_clear_resets_buffer(self):
        """clear() resets buffer to empty state."""
        buffer = SlidingWindowBuffer(window_size=3)
        frame = np.random.rand(225).astype(np.float32)

        buffer.add_landmarks(frame)
        buffer.add_landmarks(frame)
        buffer.add_landmarks(frame)

        assert buffer.get_buffer_size() == 3
        buffer.clear()
        assert buffer.get_buffer_size() == 0

    def test_stride_parameter_reserved(self):
        """Stride parameter is stored but not yet used."""
        buffer = SlidingWindowBuffer(window_size=3, stride=2)
        assert buffer.stride == 2
        frame = np.random.rand(225).astype(np.float32)
        buffer.add_landmarks(frame)
        buffer.add_landmarks(frame)
        result = buffer.add_landmarks(frame)
        assert result is not None

    def test_is_ready(self):
        """is_ready() returns True only when buffer has enough frames."""
        buffer = SlidingWindowBuffer(window_size=5)
        frame = np.random.rand(225).astype(np.float32)
        assert not buffer.is_ready()
        for _ in range(4):
            buffer.add_landmarks(frame)
            assert not buffer.is_ready()
        buffer.add_landmarks(frame)
        assert buffer.is_ready()

    def test_get_accumulated_signs(self):
        """get_accumulated_signs returns sign buffer."""
        buffer = SlidingWindowBuffer()
        assert buffer.get_accumulated_signs() == []
        buffer.add_sign({'sign': 'test', 'confidence': 0.9})
        signs = buffer.get_accumulated_signs()
        assert len(signs) == 1
        assert signs[0]['sign'] == 'test'

    def test_add_sign(self):
        """add_sign adds to signs buffer."""
        buffer = SlidingWindowBuffer()
        buffer.add_sign({'sign': 'xin_chào', 'confidence': 0.9})
        buffer.add_sign({'sign': 'cảm_ơn', 'confidence': 0.85})
        signs = buffer.get_accumulated_signs()
        assert len(signs) == 2

    def test_clear_also_clears_signs(self):
        """clear() resets both buffer and signs."""
        buffer = SlidingWindowBuffer()
        buffer.add_sign({'sign': 'test'})
        buffer.add_landmarks(np.random.rand(225).astype(np.float32))
        buffer.clear()
        assert buffer.get_buffer_size() == 0
        assert len(buffer.get_accumulated_signs()) == 0

    def test_invalid_feature_shape_raises(self):
        """Invalid feature vector shape raises ValueError."""
        buffer = SlidingWindowBuffer()
        with pytest.raises(ValueError, match="Expected feature vector shape"):
            buffer.add_landmarks(np.random.rand(100).astype(np.float32))
