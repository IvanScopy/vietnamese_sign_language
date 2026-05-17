"""
VSL Recognition Service

FastAPI application with Socket.io for real-time sign language recognition.
"""
from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from app.api.socket_handlers import sio
from app.models.vocabulary import VOCABULARY
import socketio
import logging

logger = logging.getLogger(__name__)

app = FastAPI(
    title='VSL Recognition Service',
    version='0.1.0',
    description='Real-time Vietnamese Sign Language recognition with TTS'
)

# Mount Socket.io
app.mount('/socket.io', socketio.ASGIApp(sio))


@app.get('/health')
async def health():
    """Health check endpoint."""
    return {
        'status': 'healthy',
        'service': 'recognition',
        'version': '0.1.0',
        'vocabulary_size': len(VOCABULARY),
        'model_loaded': True
    }


@app.get('/vocabulary')
async def get_vocabulary():
    """Return available sign vocabulary."""
    return {
        'vocabulary': VOCABULARY,
        'count': len(VOCABULARY)
    }


@app.get('/ready')
async def readiness():
    """Readiness probe for Kubernetes."""
    if len(VOCABULARY) < 50:
        return JSONResponse(
            {'status': 'not_ready', 'reason': 'vocabulary_not_loaded'},
            status_code=503
        )
    return {'status': 'ready'}


@app.on_event('startup')
async def startup():
    """Application startup events."""
    logger.info(f'Recognition service starting with {len(VOCABULARY)} signs')


@app.on_event('shutdown')
async def shutdown():
    """Application shutdown events."""
    logger.info('Recognition service shutting down')


@app.exception_handler(Exception)
async def generic_exception_handler(request: Request, exc: Exception):
    """Handle unexpected exceptions gracefully."""
    logger.error(f'Unhandled exception: {exc}', exc_info=True)
    return JSONResponse(
        status_code=500,
        content={'error': 'internal_server_error', 'message': str(exc)}
    )
