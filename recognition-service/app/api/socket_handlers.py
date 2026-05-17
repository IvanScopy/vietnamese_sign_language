"""
Socket.io Event Handlers

Real-time WebSocket handlers for sign language recognition.
"""
from socketio import AsyncServer
from app.services.session_manager import session_manager
from app.middleware.auth import verify_token
from app.models.tts_provider import TTSError
from app.schemas.landmarks import LandmarksPayload
from app.services.tts_service import tts_service
from pydantic import ValidationError
import logging

logger = logging.getLogger(__name__)

sio = AsyncServer(async_mode='asgi', cors_allowed_origins='*')


@sio.event
async def connect(sid: str, environ: dict, auth: dict):
    token = _extract_token(auth, environ)
    user_id = await verify_token(token)
    if not user_id:
        logger.warning(f'Unauthenticated: {sid}')
        await sio.disconnect(sid)
        return
    session = session_manager.create_session(sid, user_id)
    await sio.emit('connected', {'sessionId': session.session_id, 'userId': user_id}, to=sid)
    logger.info(f'User {user_id} connected: {sid}')


@sio.event
async def disconnect(sid: str):
    session = session_manager.get_session(sid)
    if session:
        logger.info(f'User {session.user_id} disconnected: {sid}')
    session_manager.remove_session(sid)


@sio.event
async def landmarks(sid: str, data: dict):
    session = session_manager.get_session(sid)
    if not session:
        await sio.emit('error', {'message': 'no_session', 'code': 1001}, to=sid)
        return
    if 'landmarks' not in data or 'timestamp' not in data:
        await sio.emit('error', {'message': 'missing_fields', 'code': 1002}, to=sid)
        return
    try:
        payload = LandmarksPayload(**data).model_dump()
    except ValidationError as exc:
        await sio.emit(
            'error',
            {'message': 'invalid_landmarks', 'code': 1003, 'details': exc.errors()},
            to=sid,
        )
        return

    result = session.pipeline.process_landmarks(payload)
    if result:
        # Sign already accumulated in pipeline
        await sio.emit('sign_recognized', result, room=sid)

    if session.pipeline.check_phrase_complete(payload['timestamp']):
        await _emit_phrase_complete(sid, session)


@sio.event
async def complete_phrase(sid: str, data: dict = None):
    session = session_manager.get_session(sid)
    if not session:
        await sio.emit('error', {'message': 'no_session', 'code': 1001}, to=sid)
        return
    await _emit_phrase_complete(sid, session)


@sio.event
async def clear_phrase(sid: str, data: dict = None):
    session = session_manager.get_session(sid)
    if session:
        session.clear_phrase()
        await sio.emit('phrase_cleared', {}, to=sid)
    else:
        await sio.emit('error', {'message': 'no_session'}, to=sid)


async def _emit_phrase_complete(sid: str, session):
    phrase = session.pipeline.get_phrase()
    if not phrase:
        return

    text = ' '.join(s['sign'] for s in phrase)
    phrase_payload = {
        'text': text,
        'signs': phrase,
    }
    try:
        phrase_payload['audio'] = tts_service.synthesize_to_base64(text)
    except TTSError:
        logger.warning('TTS failed for phrase_complete; emitting text only', exc_info=True)
    await sio.emit('phrase_complete', phrase_payload, room=sid)


def _extract_token(auth: dict = None, environ: dict = None) -> str:
    if auth and auth.get('token'):
        return auth.get('token', '')

    environ = environ or {}
    header = environ.get('HTTP_AUTHORIZATION') or environ.get('authorization') or ''
    if header.lower().startswith('bearer '):
        return header[7:].strip()
    return header.strip()
