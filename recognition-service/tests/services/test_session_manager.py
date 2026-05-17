"""
Tests for SessionManager.

Tests session creation, lookup, cleanup, and user isolation.
"""

import pytest
from app.services.session_manager import SessionManager, Session


@pytest.fixture
def manager():
    """Create fresh SessionManager."""
    return SessionManager()


class TestSessionManager:
    """Tests for SessionManager."""
    
    def test_create_session(self, manager):
        """create_session creates and stores session."""
        session = manager.create_session('sid-123', 'user-456')
        
        assert session.user_id == 'user-456'
        assert session.session_id is not None
        assert manager.get_session('sid-123') is session
    
    def test_get_session_returns_none_for_unknown(self, manager):
        """get_session returns None for unknown SID."""
        assert manager.get_session('unknown') is None
    
    def test_remove_session(self, manager):
        """remove_session cleans up session."""
        session = manager.create_session('sid-123', 'user-456')
        assert manager.get_session('sid-123') is not None
        
        manager.remove_session('sid-123')
        assert manager.get_session('sid-123') is None
    
    def test_remove_session_cleans_user_mapping(self, manager):
        """remove_session removes user_id mapping."""
        session = manager.create_session('sid-123', 'user-456')
        assert 'user-456' in manager._user_sessions
        
        manager.remove_session('sid-123')
        assert 'user-456' not in manager._user_sessions
    
    def test_create_session_replaces_old_for_same_user(self, manager):
        """Creating session for existing user replaces old session."""
        old_session = manager.create_session('sid-old', 'user-1')
        new_session = manager.create_session('sid-new', 'user-1')
        
        assert old_session is not new_session
        assert manager.get_session('sid-old') is None
        assert manager.get_session('sid-new') is new_session
        assert manager._user_sessions['user-1'] == 'sid-new'
    
    def test_get_session_by_user(self, manager):
        """get_session_by_user finds session by user_id."""
        session = manager.create_session('sid-123', 'user-456')
        found = manager.get_session_by_user('user-456')
        assert found is session
        
        # Unknown user returns None
        assert manager.get_session_by_user('unknown') is None
    
    def test_session_unique_ids(self, manager):
        """Each session gets unique session_id."""
        sessions = [
            manager.create_session(f'sid-{i}', f'user-{i}')
            for i in range(10)
        ]
        ids = [s.session_id for s in sessions]
        assert len(set(ids)) == len(sessions)  # All unique


class TestSession:
    """Tests for Session class."""
    
    def test_session_initialization(self):
        """Session initializes with correct defaults."""
        from app.services.session_manager import Session
        session = Session('test-user')
        
        assert session.user_id == 'test-user'
        assert session.session_id is not None
        assert session.phrase_buffer == []
        assert session.last_activity == 0
        assert hasattr(session, 'pipeline')
    
    def test_clear_phrase(self):
        """clear_phrase resets phrase buffer."""
        from app.services.session_manager import Session
        session = Session('test-user')
        session.phrase_buffer.append({'sign': 'test', 'confidence': 0.9})
        
        session.clear_phrase()
        assert session.phrase_buffer == []
