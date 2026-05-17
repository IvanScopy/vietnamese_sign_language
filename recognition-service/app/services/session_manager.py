"""
Session Manager
Manages per-user connection sessions and state.
"""
from typing import Dict, Optional
from uuid import uuid4
from app.core.recognition_pipeline import RecognitionPipeline


class Session:
    """Represents a single user's recognition session."""
    def __init__(self, user_id: str):
        self.session_id = str(uuid4())
        self.user_id = user_id
        self.pipeline = RecognitionPipeline()
        self.last_activity = 0
        self.phrase_buffer = []

    def clear_phrase(self):
        """Clear the accumulated phrase buffer."""
        self.phrase_buffer.clear()
        self.pipeline.clear_phrase()


class SessionManager:
    """Manages sessions for connected users."""
    def __init__(self):
        self._sessions: Dict[str, Session] = {}
        self._user_sessions: Dict[str, str] = {}

    def create_session(self, sid: str, user_id: str) -> Session:
        """Create a new session for a connected user."""
        if user_id in self._user_sessions:
            old_sid = self._user_sessions[user_id]
            self.remove_session(old_sid, cleanup_user=False)

        session = Session(user_id)
        self._sessions[sid] = session
        self._user_sessions[user_id] = sid
        return session

    def get_session(self, sid: str) -> Optional[Session]:
        return self._sessions.get(sid)

    def get_session_by_user(self, user_id: str) -> Optional[Session]:
        sid = self._user_sessions.get(user_id)
        if sid:
            return self._sessions.get(sid)
        return None

    def remove_session(self, sid: str, cleanup_user: bool = True):
        session = self._sessions.pop(sid, None)
        if session and cleanup_user:
            self._user_sessions.pop(session.user_id, None)

    def clear_phrase(self, sid: str):
        session = self.get_session(sid)
        if session:
            session.clear_phrase()


session_manager = SessionManager()
