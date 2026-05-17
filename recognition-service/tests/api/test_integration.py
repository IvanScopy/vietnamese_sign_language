"""
Integration tests for complete landmark → recognition flow.
"""

import pytest
from app.core.recognition_pipeline import RecognitionPipeline
from app.services.session_manager import session_manager
from app.models.vocabulary import VOCABULARY


def create_landmarks_dict(timestamp=1000):
    """Create a landmarks dict payload."""
    return {
        'landmarks': {
            'left': {
                'handedness': 'Left',
                'landmarks': [
                    {'x': 0.5 + (i * 0.001), 'y': 0.5 + (i * 0.001), 'z': 0.0, 'visibility': 1.0}
                    for i in range(21)
                ]
            }
        },
        'timestamp': timestamp,
        'sessionId': 'test-session'
    }


class TestPipelineIntegration:
    """Integration tests for pipeline."""
    
    def test_full_pipeline_5_frames(self):
        """5 frames produce recognition result."""
        pipeline = RecognitionPipeline(window_size=5)
        payload = create_landmarks_dict(1000)
        
        result = None
        for i in range(5):
            payload['timestamp'] += 33
            result = pipeline.process_landmarks(payload)
        
        assert result is not None
        assert 'sign' in result
        assert 'confidence' in result
        assert result['sign'] in VOCABULARY
    
    def test_phrase_completion_detection(self):
        """Phrase completion after timeout."""
        pipeline = RecognitionPipeline(window_size=5)
        payload = create_landmarks_dict(1000)
        
        for i in range(5):
            pipeline.process_landmarks(payload)
            payload['timestamp'] += 33
        
        assert not pipeline.check_phrase_complete(payload['timestamp'])
        assert pipeline.check_phrase_complete(payload['timestamp'] + 3000)
    
    def test_pipeline_with_session_manager(self):
        """Pipeline works with session manager."""
        session_manager._sessions.clear()
        session_manager._user_sessions.clear()

        try:
            session = session_manager.create_session('sid-123', 'user-456')
            payload = create_landmarks_dict(1000)

            # Send 30 frames (default window_size)
            for i in range(30):
                payload['timestamp'] += 33
                session.pipeline.process_landmarks(payload)

            assert session.pipeline._last_sign_time > 0
            assert session.user_id == 'user-456'
        finally:
            session_manager.remove_session('sid-123')
