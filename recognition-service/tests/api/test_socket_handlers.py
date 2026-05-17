"""
Tests for Socket.io event handlers (direct function calls).
"""

import pytest
from unittest.mock import AsyncMock, patch
from app.api.socket_handlers import sio, connect, disconnect, landmarks, clear_phrase
from app.services.session_manager import session_manager


@pytest.fixture(autouse=True)
def set_jwt_secret():
    import os
    os.environ['JWT_SECRET'] = 'test-secret'


@pytest.fixture(autouse=True)
def clear_sessions():
    """Clear all sessions before/after each test."""
    session_manager._sessions.clear()
    session_manager._user_sessions.clear()
    yield
    session_manager._sessions.clear()
    session_manager._user_sessions.clear()


class TestSocketHandlers:
    """Tests for Socket.io handlers."""

    @pytest.mark.asyncio
    async def test_connect_with_valid_token(self, clear_sessions):
        """Valid JWT creates session."""
        with patch('app.api.socket_handlers.verify_token', return_value='user-123'):
            mock_emit = AsyncMock()
            sio.emit = mock_emit

            await connect('sid-123', {}, {'token': 'valid-token'})

            # Check session created
            session = session_manager.get_session('sid-123')
            assert session is not None
            assert session.user_id == 'user-123'

            # Check 'connected' event emitted
            mock_emit.assert_called_once()
            args, kwargs = mock_emit.call_args
            assert args[0] == 'connected'
            assert 'sessionId' in args[1]

    @pytest.mark.asyncio
    async def test_connect_with_invalid_token(self, clear_sessions):
        """Invalid JWT disconnects."""
        with patch('app.api.socket_handlers.verify_token', return_value=None):
            mock_disconnect = AsyncMock()
            sio.disconnect = mock_disconnect

            await connect('sid-123', {}, {'token': 'bad-token'})

            mock_disconnect.assert_called_once_with('sid-123')

    @pytest.mark.asyncio
    async def test_landmarks_valid_payload(self, clear_sessions):
        """Valid landmarks are processed."""
        with patch('app.api.socket_handlers.verify_token', return_value='user-123'):
            session = session_manager.create_session('sid-123', 'user-123')
            mock_emit = AsyncMock()
            sio.emit = mock_emit

            payload = {
                'landmarks': {
                    'left': {
                        'handedness': 'Left',
                        'landmarks': [
                            {'x': 0.5, 'y': 0.5, 'z': 0.0, 'visibility': 1.0}
                        ] * 21
                    }
                },
                'timestamp': 1000,
                'sessionId': 'any'
            }

            # First frame - buffer not full, no recognition
            result = await landmarks('sid-123', payload)
            assert mock_emit.call_count == 0

            # Fill buffer with 30 frames
            for i in range(30):
                payload['timestamp'] = 1000 + i * 33
                await landmarks('sid-123', payload)

            # After 30 frames, should emit sign_recognized
            sign_emits = [call for call in mock_emit.call_args_list if call[0][0] == 'sign_recognized']
            assert len(sign_emits) > 0

    @pytest.mark.asyncio
    async def test_landmarks_invalid_payload(self, clear_sessions):
        """Invalid landmarks emit error."""
        with patch('app.api.socket_handlers.verify_token', return_value='user-123'):
            session = session_manager.create_session('sid-123', 'user-123')
            mock_emit = AsyncMock()
            sio.emit = mock_emit

            payload = {'timestamp': 1000, 'sessionId': 'any'}
            await landmarks('sid-123', payload)

            # Should emit error
            error_emits = [call for call in mock_emit.call_args_list if call[0][0] == 'error']
            assert len(error_emits) > 0

    @pytest.mark.asyncio
    async def test_disconnect_cleans_session(self, clear_sessions):
        """Disconnect removes session."""
        with patch('app.api.socket_handlers.verify_token', return_value='user-123'):
            session = session_manager.create_session('sid-123', 'user-123')
            assert session_manager.get_session('sid-123') is not None

            await disconnect('sid-123')

            assert session_manager.get_session('sid-123') is None

    @pytest.mark.asyncio
    async def test_clear_phrase_event(self, clear_sessions):
        """clear_phrase resets buffer."""
        with patch('app.api.socket_handlers.verify_token', return_value='user-123'):
            session = session_manager.create_session('sid-123', 'user-123')
            session.phrase_buffer.append({'test': 'data'})

            mock_emit = AsyncMock()
            sio.emit = mock_emit

            await clear_phrase('sid-123', {})

            assert len(session.phrase_buffer) == 0
            mock_emit.assert_called_with('phrase_cleared', {}, to='sid-123')
