"""
Pytest configuration and shared fixtures.
"""

import pytest
import asyncio
import os

os.environ.setdefault('RECOGNITION_CLASSIFIER', 'mock')
os.environ.setdefault('JWT_SECRET', 'test-secret')

from app.main import app
from app.services.session_manager import session_manager
from httpx import AsyncClient, ASGITransport


@pytest.fixture(scope='session')
def event_loop():
    loop = asyncio.get_event_loop_policy().new_event_loop()
    yield loop
    loop.close()


@pytest.fixture
def clear_sessions():
    session_manager._sessions.clear()
    session_manager._user_sessions.clear()
    yield
    session_manager._sessions.clear()
    session_manager._user_sessions.clear()


@pytest.fixture
async def client():
    transport = ASGITransport(app=app)
    async with AsyncClient(transport=transport, base_url='http://test') as ac:
        yield ac


@pytest.fixture
def sample_window():
    import numpy as np
    return np.random.rand(30, 225).astype(np.float32)


@pytest.fixture
def mock_landmarks_payload():
    from app.schemas.landmarks import HandLandmarks, PoseLandmarks, Landmark

    def _make_hand_landmarks(handedness='Left'):
        landmarks = []
        for i in range(21):
            landmarks.append(Landmark(
                x=0.5 + (i * 0.001),
                y=0.5 + (i * 0.001),
                z=0.0,
                visibility=1.0
            ))
        return {'handedness': handedness, 'landmarks': landmarks}

    def _make_pose_landmarks():
        landmarks = []
        for i in range(33):
            landmarks.append(Landmark(
                x=0.5 + (i * 0.001),
                y=0.5 + (i * 0.001),
                z=0.0,
                visibility=0.9
            ))
        return {'landmarks': landmarks}

    return {
        'landmarks': {
            'pose': _make_pose_landmarks(),
            'left': _make_hand_landmarks('Left'),
            'right': _make_hand_landmarks('Right'),
        },
        'timestamp': 1234567890,
        'sessionId': 'test-session-123'
    }
