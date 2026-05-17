"""Tests for RecognitionPipeline."""
import pytest
import numpy as np
from app.core.recognition_pipeline import RecognitionPipeline


@pytest.fixture
def pipeline():
    return RecognitionPipeline(window_size=5)


def create_landmarks_dict(handedness='Left', include_pose=False):
    """Create a landmarks dict for a single hand, optionally with pose."""
    landmarks = []
    for i in range(21):
        landmarks.append({
            'x': 0.5 + (i * 0.001),
            'y': 0.5 + (i * 0.001),
            'z': 0.0,
            'visibility': 1.0
        })
    result = {'handedness': handedness, 'landmarks': landmarks}
    if include_pose:
        pose_landmarks = []
        for i in range(33):
            pose_landmarks.append({
                'x': 0.4 + (i * 0.001),
                'y': 0.4 + (i * 0.001),
                'z': 0.0,
                'visibility': 0.9
            })
        result['pose'] = {'landmarks': pose_landmarks}
    return result


def create_payload_dict(timestamp=1000):
    """Create a raw landmarks payload dict."""
    return {
        'landmarks': {
            'left': create_landmarks_dict('Left')
        },
        'timestamp': timestamp,
        'sessionId': 'test-session'
    }


class TestRecognitionPipeline:
    """Tests for RecognitionPipeline."""

    def test_pipeline_initialization(self, pipeline):
        assert pipeline.window_size == 5
        assert pipeline.buffer is not None
        assert pipeline.classifier is not None
        assert pipeline._last_sign_time == 0

    def test_process_returns_none_until_buffer_full(self, pipeline):
        payload = create_payload_dict(1000)
        result = pipeline.process_landmarks(payload)
        assert result is None
        
        for i in range(4):
            payload['timestamp'] += 33
            pipeline.process_landmarks(payload)
        payload['timestamp'] += 33
        result = pipeline.process_landmarks(payload)
        assert result is not None

    def test_process_returns_result_with_keys(self, pipeline):
        payload = create_payload_dict(1000)
        for _ in range(5):
            pipeline.process_landmarks(payload)
            payload['timestamp'] += 33
        payload['timestamp'] += 33
        result = pipeline.process_landmarks(payload)
        assert result is not None
        assert 'sign' in result
        assert 'confidence' in result
        assert 'timestamp' in result

    def test_result_sign_in_vocabulary(self, pipeline):
        from app.models.vocabulary import VOCABULARY
        payload = create_payload_dict(1000)
        for _ in range(5):
            pipeline.process_landmarks(payload)
            payload['timestamp'] += 33
        payload['timestamp'] += 33
        result = pipeline.process_landmarks(payload)
        assert result['sign'] in VOCABULARY

    def test_check_phrase_complete_before_timeout(self, pipeline):
        payload = create_payload_dict(1000)
        for _ in range(5):
            pipeline.process_landmarks(payload)
            payload['timestamp'] += 33
        pipeline.process_landmarks(payload)
        last_time = pipeline._last_sign_time
        assert not pipeline.check_phrase_complete(last_time + 1000)

    def test_check_phrase_complete_after_timeout(self, pipeline):
        payload = create_payload_dict(1000)
        for _ in range(5):
            pipeline.process_landmarks(payload)
            payload['timestamp'] += 33
        pipeline.process_landmarks(payload)
        last_time = pipeline._last_sign_time
        assert pipeline.check_phrase_complete(last_time + 3000)

    def test_get_phrase_returns_accumulated_signs(self, pipeline):
        payload = create_payload_dict(1000)
        for _ in range(5):
            result = pipeline.process_landmarks(payload)
            if result:
                pipeline._phrase_buffer.append(result)
            payload['timestamp'] += 33
        phrase = pipeline.get_phrase()
        assert isinstance(phrase, list)

    def test_get_phrase_clears_buffer(self, pipeline):
        payload = create_payload_dict(1000)
        for _ in range(5):
            pipeline.process_landmarks(payload)
            payload['timestamp'] += 33
        pipeline.process_landmarks(payload)
        pipeline.get_phrase()
        assert pipeline._last_sign_time == 0
        assert pipeline.buffer.get_buffer_size() == 0

    def test_extract_features_left_hand(self, pipeline):
        landmarks = {
            'left': {
                'handedness': 'Left',
                'landmarks': [
                    {'x': 0.5, 'y': 0.501, 'z': 0.0, 'visibility': 1.0}
                ] * 21
            }
        }
        features = pipeline._extract_features(landmarks)
        assert features.shape == (225,)  # Holistic: 99 pose + 63 left + 63 right = 225
        assert features.dtype == np.float32
        # Left hand starts at index 99 (33 pose landmarks * 3)
        assert features[99] == 0.5  # x of first left landmark
        assert features[100] == 0.501  # y of first left landmark

    def test_extract_features_right_hand(self, pipeline):
        landmarks = {
            'right': {
                'handedness': 'Right',
                'landmarks': [
                    {'x': 0.6, 'y': 0.601, 'z': 0.0, 'visibility': 1.0}
                ] * 21
            }
        }
        features = pipeline._extract_features(landmarks)
        # Right hand starts at index 162 (99 + 63 = 162)
        assert features[162] == 0.6
        assert not features[:162].any()

    def test_extract_features_pose(self, pipeline):
        landmarks = {
            'pose': {
                'landmarks': [
                    {'x': 0.4, 'y': 0.401, 'z': -0.1, 'visibility': 0.9}
                ] * 33
            }
        }
        features = pipeline._extract_features(landmarks)
        assert features.shape == (225,)
        # Pose occupies first 99 features (33 * 3)
        assert features[0] == 0.4  # x of nose
        assert features[1] == 0.401  # y of nose
        assert features[2] == -0.1  # z of nose
        # Rest of features (hands) should be zeros
        assert not features[99:].any()

    def test_extract_features_both_hands(self, pipeline):
        landmarks = {
            'left': {
                'handedness': 'Left',
                'landmarks': [{'x': 0.5, 'y': 0.5, 'z': 0.0, 'visibility': 1.0}] * 21
            },
            'right': {
                'handedness': 'Right',
                'landmarks': [{'x': 0.6, 'y': 0.6, 'z': 0.0, 'visibility': 1.0}] * 21
            }
        }
        features = pipeline._extract_features(landmarks)
        # Left hand at index 99, right at index 162
        assert features[99] == 0.5  # First left landmark x
        assert features[162] == 0.6  # First right landmark x

    def test_extract_features_holistic(self, pipeline):
        """Test extraction with full holistic landmarks (pose + both hands)."""
        landmarks = {
            'pose': {
                'landmarks': [{'x': 0.4, 'y': 0.4, 'z': 0.0, 'visibility': 0.9}] * 33
            },
            'left': {
                'handedness': 'Left',
                'landmarks': [{'x': 0.5, 'y': 0.5, 'z': 0.0, 'visibility': 1.0}] * 21
            },
            'right': {
                'handedness': 'Right',
                'landmarks': [{'x': 0.6, 'y': 0.6, 'z': 0.0, 'visibility': 1.0}] * 21
            }
        }
        features = pipeline._extract_features(landmarks)
        assert features.shape == (225,)
        # Verify each section
        assert features[0] == 0.4  # Pose x
        assert features[99] == 0.5  # Left x
        assert features[162] == 0.6  # Right x

    def test_extract_features_empty_hands(self, pipeline):
        landmarks = {}
        features = pipeline._extract_features(landmarks)
        assert not features.any()

    def test_clear_phrase(self, pipeline):
        payload = create_payload_dict(1000)
        for _ in range(5):
            pipeline.process_landmarks(payload)
            payload['timestamp'] += 33
        pipeline.process_landmarks(payload)
        pipeline.clear_phrase()
        assert pipeline._last_sign_time == 0
        assert pipeline.buffer.get_buffer_size() == 0
