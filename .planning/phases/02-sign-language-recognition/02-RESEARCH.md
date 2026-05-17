## Common Pitfalls

### Pitfall 1: End-to-End Latency Exceeding 500ms Target
**What goes wrong:** Recognized text arrives >1 second after hand movement, making conversation feel laggy and unnatural.

**Why it happens:** Multiple factors compound: MediaPipe inference (15-30ms on GPU, slower on CPU), network transit to backend (50-100ms), LSTM inference (50-200ms depending on model size), TTS synthesis (100-200ms). Each stage adds delay.

**How to avoid:** 
- Profile each stage independently with benchmarks. Use MediaPipe GPU delegate on mobile; measure actual latency on target devices.
- Keep LSTM model small (<500k parameters) for fast inference; consider 1D CNN as faster alternative.
- Pre-warm TTS synthesis or stream audio chunks incrementally.
- Optimize Socket.io payload: send only essential landmark data (21×3 floats ≈ 252 bytes) not full objects.

**Warning signs:** 
- Client-side timestamps show >300ms from frame capture to result display
- Users report "the system feels slow to respond"

### Pitfall 2: Two-Hand Detection Inconsistent
**What goes wrong:** MediaPipe fails to detect both hands when signs involve both hands interacting, causing missing landmarks and failed recognition.

**Why it happens:** MediaPipe's `max_num_hands=2` is configured but detection can still miss a hand if hands overlap or are near body. The model is optimized for single-hand gestures.

**How to avoid:**
- Set `max_num_hands=2` explicitly; verify with `model_complexity=1` (higher accuracy, slightly slower)
- Add client-side logic to retain previous frame's second hand position if temporarily lost (interpolation)
- Design VSL vocabulary to minimize truly simultaneous two-hand signs, or use temporal separation (one hand moves after other)

**Warning signs:**
- Logs show `multi_hand_landmarks` with only 1 hand when user is clearly using two hands
- Recognition accuracy drops specifically on two-handed signs

### Pitfall 3: Socket.IO Room State Lost on Server Restart/Scale
**What goes wrong:** Users lose recognition continuity when server restarts or scales to multiple instances; phrases accumulate incorrectly or sessions orphaned.

**Why it happens:** Socket.io rooms are in-memory by default. Multi-process deployment without Redis adapter loses room membership across processes. Server restart clears all session buffers.

**How to avoid:**
- Use Redis adapter for Socket.io: `io.adapter(createAdapter(redis_pub, redis_sub))`
- Store session state in Redis with TTL, not in-memory dict. Rehydrate session on reconnection using user_id.
- Implement client-side reconnection logic with session recovery token; on reconnect, send last known phrase state to rebuild server buffer.

**Warning signs:**
- After server deploy, users report "recognition stopped working until I refreshed"
- Scaling to 2+ workers causes inconsistent behavior per user

### Pitfall 4: Coordinate Normalization Mismatch
**What goes wrong:** Model trained on normalized [0,1] coordinates but client sends pixel coordinates (or vice versa), causing recognition to fail completely or produce garbage predictions.

**Why it happens:** MediaPipe outputs normalized coordinates (relative to image dimensions), but some examples show raw pixels. Confusion during model training vs. inference setup.

**How to avoid:**
- Standardize on normalized coordinates [0,1] for all communication. Document this in API schema.
- On client: `x = landmark.x` (already normalized in MediaPipe Tasks Vision output)
- On server: Don't multiply by image width/height before feeding to model.
- Add sanity check: reject landmarks with coordinates outside [0,1] with warning log.

**Warning signs:**
- Model outputs are random/uniform across all inputs regardless of actual sign
- Debug prints show coordinates like (512, 384) instead of (0.4, 0.6)

### Pitfall 5: Vocabulary Size Mismatch Between Training and Deployment
**What goes wrong:** Model trained with N classes but vocabulary.json lists different M classes; classification head size mismatch causes runtime errors or silent mislabeling.

**Why it happens:** Vocabulary changes after model training (added/removed signs) without retraining. Or multiple model checkpoints with different class sets.

**How to avoid:**
- Store vocabulary alongside model checkpoint; load both together at service startup.
- Validate vocabulary size matches model output layer on boot; fail fast with clear error.
- Version vocabulary with model: `vocabulary_v1.json`, `model_v1.pth`. Never mutate in-place.

**Warning signs:**
- Startup logs show "Expected 100 classes but got 120 labels in vocabulary"
- Recognized signs show as "unknown_label_17" instead of proper Vietnamese text

### Pitfall 6: Phrase Boundary Detection Too Aggressive/Passive
**What goes wrong:** Phrases split mid-sign (false pause) or merge multiple signs together (no pause detection), producing incorrect text output.

**Why it happens:** Time-based threshold (2-3 seconds) is heuristic; users may pause briefly between signs in same phrase, or hold a sign for >3 seconds while thinking.

**How to avoid:**
- Make timeout configurable (2.5s default, adjustable in settings)
- Add explicit "phrase complete" gesture or button as optional override (user can tap to commit phrase early)
- Consider motion-based detection: if hand velocity near zero for N frames, treat as sign completion, not time-based.

**Warning signs:**
- User testing: "It cuts off my signs" or "It won't recognize when I finished"
- Phrase fragments appear in conversation history

## Code Examples

Verified patterns from official sources:

### Flutter Camera Streaming with Socket.io
```dart
// Source: socket_io_client pub.dev docs + camera streaming patterns
// Sends MediaPipe landmarks over Socket.io as they become available

import 'package:camera/camera.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SignRecognitionService {
  late IO.Socket socket;
  final SlidingWindowBuffer _displayBuffer = SlidingWindowBuffer();
  
  Future<void> initializeSocket(String token) async {
    socket = IO.io(
      'http://${ApiConfig.recognitionHost}:${ApiConfig.recognitionPort}',
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .setExtraHeaders({'Authorization': 'Bearer $token'})
          .disableAutoConnect()
          .build(),
    );
    socket.connect();
    
    socket.on('sign_recognized', (data) {
      _displayBuffer.addSign(data['sign'], data['confidence']);
      _updateUI();
    });
    
    socket.on('phrase_complete', (data) {
      _onPhraseComplete(data['text'], data['audio']);
    });
  }
  
  void onCameraFrame(CameraImage image) async {
    // 1. Run MediaPipe on frame (via platform channel or JS bridge)
    final landmarks = await mediaPipe.process(image);
    
    // 2. Send to backend
    socket.emit('landmarks', {
      'landmarks': landmarks,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }
}
```

### Python FastAPI + Socket.io Integration Pattern
```python
# Source: FastAPI WebSocket docs + python-socketio integration
# (https://fastapi.tiangolo.com/advanced/websockets/ + python-socketio docs)

import socketio
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from contextlib import asynccontextmanager

sio = socketio.AsyncServer(
    async_mode='asgi',
    cors_allowed_origins='*',
    ping_timeout=60,
    ping_interval=25,
)

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print('Starting recognition service...')
    classifier.load_model()
    tts.initialize()
    yield
    # Shutdown
    print('Shutting down...')
    classifier.cleanup()

fastapi_app = FastAPI(lifespan=lifespan)

# Mount Socket.io
app = socketio.ASGIApp(sio, fastapi_app)

# HTTP health check
@fastapi_app.get('/health')
async def health():
    return {'status': 'ok', 'model_loaded': classifier.is_loaded()}

@sio.event
async def connect(sid: str, environ: dict, auth: dict):
    user_id = verify_jwt(auth.get('token', ''))
    if not user_id:
        await sio.disconnect(sid, reason='unauthenticated')
        return
    await sio.enter_room(sid, room=user_id)
    sessions[sid] = UserSession(user_id)
    print(f'Connected: {user_id}')

@sio.event
async def landmarks(sid: str, data: dict):
    session = sessions.get(sid)
    if not session:
        return
    
    # Validate payload with Pydantic
    try:
        payload = LandmarkPayload(**data)
    except ValidationError as e:
        await sio.emit('error', {'message': 'invalid payload'}, to=sid)
        return
    
    # Process recognition
    result = await process_landmarks(session, payload.landmarks)
    if result:
        await sio.emit('sign_recognized', result.dict(), room=session.user_id)
```

### LSTM Model Definition (PyTorch)
```python
# Source: PyTorch LSTM patterns + TensorFlow RNN guide
# Input shape: (batch, timesteps, features)
# Features: 21 landmarks × 3 coords × 2 hands = 126 (or only dominant hand = 63)

import torch
import torch.nn as nn

class SignLSTM(nn.Module):
    def __init__(
        self,
        input_dim: int = 126,      # Feature dimension per timestep
        hidden_dim: int = 128,     # LSTM hidden units
        num_layers: int = 2,       # Stacked LSTM layers
        num_classes: int = 100,    # Number of signs in vocabulary
        dropout: float = 0.3,
    ):
        super().__init__()
        self.lstm = nn.LSTM(
            input_size=input_dim,
            hidden_size=hidden_dim,
            num_layers=num_layers,
            batch_first=True,
            dropout=dropout if num_layers > 1 else 0,
        )
        self.classifier = nn.Sequential(
            nn.Linear(hidden_dim, 64),
            nn.ReLU(),
            nn.Dropout(dropout),
            nn.Linear(64, num_classes),
        )
    
    def forward(self, x: torch.Tensor) -> torch.Tensor:
        """
        Args:
            x: Tensor of shape (batch, timesteps, input_dim)
        Returns:
            logits: Tensor of shape (batch, num_classes)
        """
        lstm_out, (hidden, cell) = self.lstm(x)
        # Use final timestep output for classification
        final_hidden = lstm_out[:, -1, :]
        return self.classifier(final_hidden)

# Training pattern
model = SignLSTM(input_dim=126, hidden_dim=128, num_layers=2, num_classes=100)
criterion = nn.CrossEntropyLoss()
optimizer = torch.optim.Adam(model.parameters(), lr=0.001)

# Inference pattern
def predict(sequence: np.ndarray) -> dict:
    """
    Args:
        sequence: numpy array of shape (timesteps, features), already normalized
    Returns:
        dict with 'label' (str) and 'confidence' (float)
    """
    with torch.no_grad():
        x = torch.from_numpy(sequence).unsqueeze(0)  # Add batch dim
        logits = model(x)
        probs = torch.softmax(logits, dim=-1)
        confidence, predicted = torch.max(probs, dim=-1)
        return {
            'label': vocabulary[predicted.item()],
            'confidence': confidence.item(),
        }
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Raw WebRTC getUserMedia | MediaPipe Hands SDK | 2019-2021 | 21-point landmarks simplify recognition pipeline; device-optimized inference |
| Custom CNN keypoint detection | MediaPipe (pre-trained) | 2020+ | No training data needed for landmarks; production-ready on mobile |
| Full video frame LSTM | Landmark-based LSTM | 2020+ | Reduces input dimensions from 1000s of pixels to 126 features; faster training/inference |
| Local only (device) ML | Hybrid (cloud + device landmarks) | 2023+ | Balances latency (landmarks local) with model capacity (server-side) |
| Rule-based DTW matching | Deep learning LSTM | 2018+ | Better generalization across signers; handles temporal variations |

**Deprecated/outdated:**
- **TensorFlow.js for mobile recognition:** Slower than native TFLite; bundle size larger. Use TFLite on-device or server-side.
- **Whisper.cpp for STT (without GPU):** On CPU, slower than Groq cloud API. Prefer Groq primary with local fallback.
- **eSpeak (not eSpeak-ng):** eSpeak-ng is actively maintained fork with better language support.
- **Socket.io v2:** Use v4 for TypeScript support and improved reconnection.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | MediaPipe Hands GPU delegate available on target mobile devices (Android/iOS) | Standard Stack | CPU-only inference ~2-3× slower; may impact 500ms target |
| A2 | LSTM model can achieve >70% accuracy on 100-200 VSL signs with reasonable training data | Summary | Requires dataset of thousands of labeled VSL videos; if unavailable, accuracy lower |
| A3 | Piper TTS Vietnamese voices (vivos, vais1000) are intelligible for children | Vietnamese TTS | Quality may be inadequate; need to test with target users; may require ElevenLabs cloud |
| A4 | 15 FPS landmark extraction sufficient for sign recognition (not missing key movements) | Common Pitfalls | May need 30 FPS for fast signs; 15 FPS could miss brief hand positions |
| A5 | Socket.io compatible between Node.js (Phase 1 API) and Python (this phase) without version mismatch | Architecture Patterns | Major version mismatch (v3 vs v4) would break compatibility |
| A6 | Python FastAPI + Socket.io can handle 10-20 concurrent users on $5-10 VPS | Summary | Resource constraints; may need separate VPS or optimize model |
| A7 | No pre-trained VSL model exists; will need custom training | Summary | If a pre-trained VSL model exists, this assumption wrong but doesn't break plan |
| A8 | Embedding-based approach (nearest-neighbor) not needed for MVP; classification sufficient | D-09 | If user specifically wants embedding flexibility, architecture may need adjustment |

## Open Questions

1. **VSL Training Data Availability**
   - What we know: Project needs labeled VSL videos for training; unclear if dataset exists or must be created
   - What's unclear: Number of examples per sign needed for >70% accuracy; annotator availability
   - Recommendation: Plan for dataset collection concurrent with MVP development; start with 50-100 signs as pilot

2. **Embedding vs Classification Model Output**
   - What we know: D-09 says architecture should support both; research shows classification simpler for fixed vocabulary
   - What's unclear: Does user want ability to add custom signs via embeddings without retraining?
   - Recommendation: Implement classification first; embedding support as future enhancement (requires FAISS or similar vector store)

3. **On-Device Fallback Classifier**
   - What we know: D-03 says graceful degradation (show "unclear") not on-device fallback
   - What's unclear: Is offline partial functionality explicitly deferred?
   - Recommendation: No on-device LSTM for MVP; server-only classification. Offline dictionary-only mode could be future phase.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Python 3.9+ | Recognition service | ✓ | 3.9.25 | — |
| FastAPI | API framework | ✓ (pip) | 0.128.8 | — |
| PyTorch | LSTM model | ✗ | — | Install via pip |
| MediaPipe (Python) | Landmark processing (server validation) | ✗ | — | Optional - server doesn't process images |
| Piper TTS | Vietnamese speech | ✗ | — | eSpeak-ng (installed via apt) |
| Redis | Socket.io scaling | ✗ | — | In-memory adapter for single process (MVP scale) |
| Docker | Containerization | ✗ | — | Install on VPS required |
| Node.js | Phase 1 API | ✓ | 20.20.2 | — |

**Missing dependencies with no fallback:**
- PyTorch — required for LSTM inference; must install in Docker image
- Piper TTS — primary TTS; eSpeak-ng available as fallback but quality lower

**Missing dependencies with fallback:**
- Redis — not needed for single-process MVP (10-20 users); add later when scaling
- Docker — required for deployment but can run services directly on VPS for debugging

## Validation Architecture

> nyquist_validation is enabled in config.json.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | pytest + httpx (async) + pytest-asyncio |
| Config file | pytest.ini or pyproject.toml [tool.pytest] |
| Quick run command | `pytest tests/recognition/test_classifier.py -v` |
| Full suite command | `pytest --cov=recognition --cov-report=html` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| COMM-01 | Landmark sequence → sign classification (100-200 vocab) | unit + integration | `pytest tests/recognition/test_classifier.py::test_predict_known_sign -v` | ❌ Wave 0 |
| COMM-01 | End-to-end latency <500ms | performance | `pytest tests/recognition/test_latency.py -v --durations=0` | ❌ Wave 0 |
| COMM-06 | Confidence scoring for feedback | unit | `pytest tests/recognition/test_scoring.py -v` | ❌ Wave 0 |
| SIGN-02 | Vietnamese text output (UTF-8) | integration | `pytest tests/recognition/test_output_format.py -v` | ❌ Wave 0 |
| SIGN-03 | TTS synthesis <200ms | performance | `pytest tests/tts/test_latency.py -v` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `pytest tests/recognition/ -v --tb=short`
- **Per wave merge:** `pytest --cov=recognition`
- **Phase gate:** All tests green; latency benchmarks within target (<500ms recognition, <200ms TTS)

### Wave 0 Gaps
- [ ] `tests/recognition/test_classifier.py` — unit tests for LSTM prediction with mock model
- [ ] `tests/recognition/test_latency.py` — end-to-end timing tests (landmarks → result)
- [ ] `tests/recognition/test_sliding_window.py` — buffer management tests
- [ ] `tests/tts/test_synthesis.py` — Piper/eSpeak integration tests
- [ ] `tests/conftest.py` — shared fixtures (mock model, sample landmarks)
- [ ] `pyproject.toml` — pytest configuration, coverage settings
- [ ] Dockerfile.recognition — builds Python service with dependencies

## Security Domain

> Required when `security_enforcement` is enabled (absent = enabled). This phase adds a new microservice.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | JWT token validation via shared secret with Node.js API |
| V3 Session Management | Partial | Socket.io sessions authenticated on connect; no persistence needed |
| V4 Access Control | Yes | Socket.io room isolation (user_id rooms); reject unauthorized joins |
| V5 Input Validation | Yes | Pydantic schemas for all Socket.io payloads and HTTP endpoints |
| V6 Cryptography | No | — (no sensitive storage; transit encryption handled by reverse proxy) |

### Known Threat Patterns for Python Socket.io + FastAPI

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized Socket.io connection | Spoofing | Verify JWT on connect; reject unauthenticated; use same secret as Node.js API |
| Malicious landmark payload ( oversized ) | Denial of Service | Validate payload size (<10KB); rate limit per user_id |
| Model poisoning via crafted landmarks | Tampering | Landmarks are read-only ML input; no persistence; model file read-only mount |
| Eavesdropping on recognition stream | Information Disclosure | Use HTTPS/WSS in production; reverse proxy handles TLS termination |
| Session hijacking via SID prediction | Spoofing | Socket.io generates cryptographically random SIDs; don't use sequential |

## Sources

### Primary (HIGH confidence)
- MediaPipe Hands documentation (https://google.github.io/mediapipe/solutions/hands.html) - Landmark output format, 21 keypoints, GPU performance benchmarks
- FastAPI WebSocket docs (https://fastapi.tiangolo.com/advanced/websockets/) - WebSocket endpoint patterns
- python-socketio docs (https://python-socketio.readthedocs.io/) - ASGI integration, room management, async server
- TensorFlow RNN guide (https://www.tensorflow.org/guide/keras/working_with_rnns) - LSTM input shape (batch, timesteps, features)
- Piper TTS documentation (https://github.com/rhasspy/piper) - Vietnamese voices, ONNX inference, sample rate 22050 Hz
- eSpeak-ng documentation (https://github.com/espeak-ng/espeak-ng) - Vietnamese language support, SSML, CLI usage

### Secondary (MEDIUM confidence)
- Camera Flutter plugin docs (https://pub.dev/packages/camera) - ResolutionPreset, streaming buffers, FPS configuration
- Socket.io Redis adapter docs (https://socket.io/docs/v4/redis-adapter) - Multi-server scaling pattern
- MediaPipe Tasks Vision (https://ai.google.dev/edge/mediapipe/solutions/vision/hand_landmarker) - HandLandmarker options, VIDEO vs LIVE_STREAM modes

### Tertiary (LOW confidence)
- Web search results for sign language LSTM implementations (no specific models found) - Assumes LSTM architecture suitable; needs validation on actual VSL data
- Piper Vietnamese voice quality (vivos, vais1000) - Based on VOICES.md listing; audio quality unlistened in research
- MediaPipe GPU latency (12.27ms Pixel 6) - From docs; actual performance on diverse Android devices varies

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - Library versions verified via Context7/npm/pip; patterns from official docs
- Architecture: MEDIUM - LSTM sliding window pattern is standard for gesture recognition but unproven on VSL specifically
- Pitfalls: HIGH - Identified from real-time streaming experience and documentation
- Vietnamese TTS quality: LOW - Piper voices listed but not auditioned; quality assumption needs validation

**Research date:** 2026-05-09
**Valid until:** 2026-06-08 (30 days; TTS models and ML frameworks change slowly, but verify PyTorch/TFLite versions)