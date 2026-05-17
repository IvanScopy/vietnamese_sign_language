# Architecture Research

**Domain:** Sign Language Bridge System
**Researched:** 2026-05-05
**Confidence:** HIGH

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         CLIENT LAYER (Mobile / Web)                        │
├─────────────────────────────────────────────────────────────────────────────┤
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐   │
│  │   Camera    │  │    UI /     │  │   Video      │  │   Local     │   │
│  │  Capture &  │  │  Learning   │  │  Calling     │  │   Storage   │   │
│  │  Display    │  │  Interface  │  │  Module      │  │   (Indexed  │   │
│  └──────┬──────┘  └──────┬──────┘  └──────┬───────┘  └──────┬──────┘   │
│         │                │                 │                 │           │
├─────────┼────────────────┼─────────────────┼─────────────────┼───────────┤
│         │   SIGN LANGUAGE RECOGNITION PIPELINE (Client or Server)         │
│         │  ┌─────────────────────────────────────────────────────────┐   │
│         │  │ 1. Frame Capture → 2. MediaPipe Holistic →             │   │
│         │  │ 3. Landmark Extraction → 4. LSTM Classification        │   │
│         │  └─────────────────────────────────────────────────────────┘   │
│         │                              │                                   │
├─────────┼──────────────────────────────┼───────────────────────────────────┤
│         │                API GATEWAY / BACKEND SERVICES                  │
│         │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│         │  │    Auth     │  │  Accounts   │  │    WebRTC           │    │
│         │  │   Service   │  │   Service   │  │  Signaling Server  │    │
│         │  └─────────────┘  └─────────────┘  └─────────────────────┘    │
│         │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│         │  │   History   │  │    SOS      │  │   STT/TTS API       │    │
│         │  │   Service   │  │   Service   │  │  (Whisper/Coqui)    │    │
│         │  └─────────────┘  └─────────────┘  └─────────────────────┘    │
│         │                              │                                   │
├─────────┼──────────────────────────────┼───────────────────────────────────┤
│         │                    DATA PERSISTENCE LAYER                       │
│         │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────────┐    │
│         │  │  User DB    │  │Conversation │  │    SOS Logs        │    │
│         │  │(PostgreSQL) │  │   History   │  │   (PostgreSQL)     │    │
│         │  └─────────────┘  └─────────────┘  └─────────────────────┘    │
│         │  ┌─────────────┐                                                │
│         │  │   Cache     │                                                │
│         │  │  (Redis)    │                                                │
│         │  └─────────────┘                                                │
└─────────┴────────────────────────────────────────────────────────────────────┘
                              │
                    ┌─────────┴─────────┐
                    ▼                   ▼
          ┌─────────────────┐  ┌─────────────────┐
          │ 3D Avatar       │ │ External STT/  │
          │ Service         │ │ TTS Services   │
          │ (Three.js/      │ │ (Optional)     │
          │  Unity/WebGL)   │ └─────────────────┘
          └─────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| Camera Capture & Display | Real-time video input/output for sign recognition | MediaPipe Camera Utils / getUserMedia API |
| Sign Recognition Pipeline | Convert hand/body gestures to text | MediaPipe Holistic → Landmark extraction → LSTM/Transformer classifier |
| Speech Recognition (STT) | Convert spoken Vietnamese to text | Whisper (local) or Coqui/API service |
| Text-to-Speech (TTS) | Convert text to spoken Vietnamese | Web Speech API / Coqui TTS / Azure Speech |
| 3D Avatar System | Render animated signing avatar | Three.js with blend shapes / Unity WebGL / VRM models |
| Video Calling Module | P2P video communication | WebRTC with signaling server |
| Learning Interface | Lessons, quizzes, progress tracking | Interactive UI with camera feedback |
| Dictionary/History | Search and storage of signs/conversations | Local storage + sync to backend |
| Auth Service | User authentication & session management | JWT tokens, OAuth optional |
| Accounts Service | Profile management, emergency contacts | RESTful API + PostgreSQL |
| History Service | Store/retrieve conversation text | PostgreSQL with full-text search |
| SOS Service | Emergency alerts with GPS | SMS gateway integration, Twilio/Nexmo |
| WebRTC Signaling | Peer connection coordination | WebSocket server (Socket.io / WS) |
| API Gateway | Request routing, rate limiting | Express.js / Fastify middleware layer |
| STUN/TURN Servers | NAT traversal for P2P connections | Coturn / self-hosted STUN |
| Database Layer | Persistent data storage | PostgreSQL + Redis cache |
| Admin Panel | User/content management dashboards | Web app with RBAC |

## Recommended Project Structure

```
vsl-bridge/
├── mobile/                          # React Native / Flutter app
│   ├── src/
│   │   ├── components/             # Reusable UI components
│   │   │   ├── camera/
│   │   │   ├── avatar/
│   │   │   └── video-call/
│   │   ├── screens/                # App screens/pages
│   │   │   ├── HomeScreen.tsx
│   │   │   ├── CallScreen.tsx
│   │   │   ├── LearnScreen.tsx
│   │   │   └── ProfileScreen.tsx
│   │   ├── services/               # API clients, ML inference
│   │   │   ├── recognition.ts     # Sign recognition wrapper
│   │   │   ├── speech.ts          # STT/TTS wrapper
│   │   │   ├── api.ts             # Backend API client
│   │   │   └── webrtc.ts          # WebRTC manager
│   │   ├── models/                 # Data models/interfaces
│   │   ├── hooks/                  # React hooks
│   │   └── utils/                  # Helper functions
│   ├── android/
│   ├── ios/
│   └── package.json
│
├── web/                            # Web application (React/Vue)
│   ├── public/
│   ├── src/
│   │   ├── components/
│   │   │   ├── CameraFeed.tsx
│   │   │   ├── SignDisplay.tsx
│   │   │   ├── SpeechBubble.tsx
│   │   │   └── AvatarViewer.tsx
│   │   ├── services/
│   │   │   ├── recognition.js     # MediaPipe + LSTM (TF.js)
│   │   │   ├── speech.js          # Web Speech API wrapper
│   │   │   └── webrtc-manager.js  # WebRTC peer management
│   │   ├── pages/
│   │   └── styles/
│   └── package.json
│
├── shared/                         # Shared code between platforms
│   ├── types/                      # TypeScript interfaces
│   │   ├── conversation.ts
│   │   ├── user.ts
│   │   └── gesture.ts
│   ├── config/                     # Configuration
│   │   ├── api-endpoints.ts
│   │   └── ml-models.ts
│   └── utils/
│
├── backend/                        # Server-side services
│   ├── src/
│   │   ├── api/
│   │   │   ├── auth/
│   │   │   ├── accounts/
│   │   │   ├── history/
│   │   │   ├── sos/
│   │   │   ├── dictionary/
│   │   │   └── webrtc/
│   │   ├── services/
│   │   │   ├── auth.service.ts
│   │   │   ├── user.service.ts
│   │   │   ├── history.service.ts
│   │   │   ├── sos.service.ts
│   │   │   └── notification.service.ts
│   │   ├── models/
│   │   │   ├── User.ts
│   │   │   ├── Conversation.ts
│   │   │   └── EmergencyContact.ts
│   │   ├── middleware/
│   │   │   ├── auth.ts
│   │   │   └── rate-limit.ts
│   │   ├── config/
│   │   └── server.ts
│   ├── package.json
│   └── .env.example
│
├── avatar-service/                 # Dedicated 3D avatar service
│   ├── src/
│   │   ├── animation/
│   │   │   ├── VSLGlossary.ts    # Sign language motion definitions
│   │   │   ├── BoneController.ts
│   │   │   └── ExpressionMixer.ts
│   │   ├── models/
│   │   │   └── AvatarModel.ts    # VRM/GLB loader and rig
│   │   ├── api/
│   │   │   └── render.ts         # REST/WebSocket API for rendering
│   │   └── utils/
│   ├── public/
│   └── package.json
│
├── ml-models/                      # ML model training/inference
│   ├── src/
│   │   ├── data/
│   │   │   ├── preprocess/       # Landmark normalization
│   │   │   └── augmentation/     # Data augmentation
│   │   ├── training/
│   │   │   ├── lstm-classifier.ts
│   │   │   ├── transformer.ts
│   │   │   └── train.ts
│   │   ├── inference/
│   │   │   ├── model-loader.ts   # TensorFlow.js / TFLite
│   │   │   ├── predictor.ts      # Real-time prediction
│   │   │   └── landmarks.ts      # MediaPipe wrapper
│   │   └── exported/
│   │       ├── vsl-lstm.tflite
│   │       └── vsl-lstm-js/
│   └── package.json
│
├── infrastructure/
│   ├── docker/
│   │   ├── docker-compose.yml
│   │   ├── backend/
│   │   ├── postgres/
│   │   └── redis/
│   ├── k8s/                       # Kubernetes manifests (optional)
│   └── terraform/                 # Infrastructure as code (optional)
│
├── scripts/
│   ├── setup-db.sql
│   ├── seed-data/
│   └── deploy/
│
├── docs/
│   ├── API.md
│   ├── ML-ARCHITECTURE.md
│   └── DEPLOYMENT.md
│
├── .env.example
├── docker-compose.yml
└── README.md
```

### Structure Rationale

- **mobile/**: Native mobile app codebase (React Native for iOS/Android parity with web)
- **web/**: Browser-based application using same component patterns
- **shared/**: Common TypeScript types and utilities to maintain consistency
- **backend/**: Monolithic API server (appropriate for v1 scale) with modular routes
- **avatar-service/**: Isolated for GPU-intensive 3D rendering; can scale independently
- **ml-models/**: Separate for model training experiments; inference code shared with clients
- **infrastructure/**: Container orchestration and deployment configuration
- **scripts/**: Database setup, seed data, and deployment automation

## Architectural Patterns

### Pattern 1: Edge-Cloud Hybrid Inference

**What:** Split ML inference between client device and server based on model complexity and latency requirements.

**When to use:** Real-time applications where latency is critical but some models are too heavy for mobile.

**Trade-offs:**
- Lightweight models (landmark detection) on device = lower latency, no server cost
- Heavy models (classification, avatar generation) on server = better accuracy, requires internet
- Offline capability partially preserved for basic recognition

**Example:**
```typescript
// Client-side: Landmark extraction
const landmarks = await mediaPipe.process(frame);

// Send to server for classification
const prediction = await api.predictSign(landmarks);

// OR: Full on-device pipeline (if model fits)
const prediction = await localModel.predict(landmarks);
```

### Pattern 2: WebRTC Mesh for Video Calling

**What:** Direct peer-to-peer connections between users with minimal server relay.

**When to use:** 1:1 video calling with low user count; scales poorly for group calls.

**Trade-offs:**
- Pros: Low latency, no media server bandwidth costs
- Cons: Each user uploads to all peers (O(n²) bandwidth), NAT traversal complexity

**Example:**
```javascript
// Signaling via WebSocket
socket.on('offer', async (offer) => {
  await pc.setRemoteDescription(offer);
  const answer = await pc.createAnswer();
  await pc.setLocalDescription(answer);
  socket.emit('answer', answer);
});

// Media flows P2P after ICE negotiation
pc.ontrack = (event) => {
  remoteVideo.srcObject = event.streams[0];
};
```

### Pattern 3: Blob-First Real-Time Pipeline

**What:** Process video frames as discrete blobs rather than streaming for ML inference, enabling parallelism.

**When to use:** When inference can tolerate minor buffering (100-500ms) for better throughput.

**Trade-offs:**
- Allows batch processing on server
- Easier retry and error handling
- Slightly higher latency than pure streaming

**Example:**
```
Camera → Frame Buffer (5-10 frames)
         ↓
   Landmark Extraction (parallel)
         ↓
   Classification (batch)
         ↓
   Result Aggregation → Display
```

### Pattern 4: Progressive Enhancement for Offline/Online

**What:** Design features to degrade gracefully when offline, with sync when reconnected.

**When to use:** Mobile apps where connectivity is intermittent.

**Trade-offs:**
- More complex state management
- Better user experience in poor connectivity

**Example:**
```typescript
const useSync = () => {
  const [isOnline, setIsOnline] = useState(navigator.onLine);

  useEffect(() => {
    const handleOnline = () => {
      syncPendingActions();
      setIsOnline(true);
    };
    window.addEventListener('online', handleOnline);
    return () => window.removeEventListener('online', handleOnline);
  }, []);

  return { isOnline, queueAction, syncPendingActions };
};
```

## Data Flow

### Primary Data Flows

#### 1. Sign Recognition Flow
```
Camera Frame (640x480)
    ↓
MediaPipe Holistic (on device)
    ↓
Landmark Vector (543 points × 3 coordinates)
    ↓
Normalization (relative coordinates, velocity)
    ↓
LSTM Classifier (server or device)
    ↓
Sign Label + Confidence Score
    ↓
Text Display + TTS Output
```

#### 2. Video Call Flow
```
User A clicks "Call"
    ↓
POST /api/calls/initiate (to backend)
    ↓
Backend creates call room, returns room ID
    ↓
Both clients connect to WebSocket signaling
    ↓
Exchange SDP offers/answers via signaling
    ↓
STUN/TURN ICE candidate negotiation
    ↓
Direct P2P media stream established
    ↓
Call ongoing (media bypasses server)
    ↓
Hang up → Backend logs call metadata
```

#### 3. Speech-to-Text Flow
```
Microphone Audio Stream
    ↓
VAD (Voice Activity Detection)
    ↓
Whisper / Web Speech API
    ↓
Vietnamese Text
    ↓
Display subtitles
    ↓
Optional: Send to partner via call signaling
```

#### 4. 3D Avatar Animation Flow
```
Input Text (Vietnamese word/phrase)
    ↓
Lookup: Text → Sign Gloss Sequence
    ↓
Gloss → Animation Timeline (pre-recorded or procedurally generated)
    ↓
Send to Avatar Service (WebSocket or REST)
    ↓
Avatar renders with blend shapes/bone animation
    ↓
Stream or display locally
```

### State Management

For mobile/web apps:
- **Local UI state**: React useState / component state
- **Global app state**: Zustand / Redux Toolkit for user profile, call state, history
- **Persistent state**: AsyncStorage (mobile) / IndexedDB (web) for conversations, settings
- **Server state**: React Query / SWR for cached API data with background refresh

For backend:
- **Request state**: Passed via HTTP context
- **Session state**: JWT tokens in Redis for session validation
- **Connection state**: Socket.io rooms for WebRTC signaling

## Build Order (Dependencies)

This section is research context. The authoritative current phase sequence is `.planning/ROADMAP.md`; avatar work is deferred to v2+.

```
Phase 0: Foundation
├── Backend API skeleton (Express + PostgreSQL)
├── Auth service (JWT)
├── Database schema
└── Docker dev environment

Phase 1: Core Recognition (Independent)
├── MediaPipe integration on mobile
├── Landmark preprocessing module
├── LSTM model inference (server endpoint)
└── Basic UI: camera → text output

Phase 2: Speech I/O (Parallelizable)
├── STT integration (Whisper or API)
├── TTS integration (Web Speech / Coqui)
├── Speech UI components
└── Testing end-to-end: sign → text, speech → text

Phase 3: Face-to-Face Conversation & History (Depends on recognition + speech I/O)
├── Split-screen conversation mode
├── Shared text timeline
├── Local text-only conversation history
├── Search and share/export
└── No v1 avatar dependency

Phase 4: Video Calling (Depends on auth + recognition)
├── WebRTC signaling server
├── STUN/TURN setup
├── Call screens UI
├── Permission handling
└── Call history logging

Phase 5: SOS & Emergency (Depends on accounts)
├── GPS location service
├── SMS notification integration
├── Emergency contact management
├── SOS triggering flow
└── Admin SOS dashboard

Phase 6: App, Dictionary & Admin Readiness
├── Dictionary data model (4000 signs)
├── Video thumbnails / previews
├── Web/mobile parity
├── Admin management screens
└── Production polish

v1.x: Learning System (Depends on dictionary)
├── Lesson builder UI
├── Quiz system with camera feedback
└── Progress tracking

v2+: Avatar System (Deferred)
├── Avatar model loading (VRM/GLB)
├── Animation system (bone/blend shape controller)
├── Sign-to-animation mapping
├── Avatar rendering in Three.js/Unity
└── API for remote rendering (optional)

Later: Polish & Cross-Platform
├── Web app feature parity
├── Performance optimization
├── Accessibility features
├── Admin panel
└── Documentation
```

## Scaling Considerations

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 0-1k users | Monolithic backend is fine; single server deploy; SQLite possible |
| 1k-100k users | Add Redis cache for sessions; separate ML inference service; PostgreSQL with read replicas; CDN for avatar assets |
| 100k+ users | Microservices for auth/history/sos; dedicated WebRTC SFU for group calls; global STUN/TURN network; horizontal scaling of stateless services |

### Scaling Priorities

1. **First bottleneck:** Database connection pool and query performance. Fix with connection pooling (PgBouncer), read replicas, and query optimization.
2. **Second bottleneck:** ML inference throughput. Fix with separate inference service, GPU instances, and request queuing.
3. **Third bottleneck:** WebRTC signaling at scale. Fix with Redis Pub/Sub for multi-instance signaling, then consider SFU for group calls.

## Technology-Specific Considerations

### Sign Recognition (MediaPipe + LSTM)

**On-Device (Recommended for landmarks):**
- MediaPipe Holistic: ~50-100ms per frame on modern phones
- 543 landmarks (pose+face+hands) = ~3KB JSON per frame
- Requires camera permission; battery impact ~5-10%/hour

**Server-Side (Recommended for classification):**
- LSTM input: sequence of 30-60 frames of landmarks
- Model size: ~5-20MB (LSTM weights)
- Inference time: ~50-200ms on CPU, ~20ms on GPU
- Batch multiple sequences for efficiency

**Offline Scenario:** Store landmarks locally; batch upload when online for history sync.

### Real-Time Video (WebRTC)

**Mobile:** React Native WebRTC library or native modules (iOS: WebRTC.framework, Android: webrtc-native)
**Web:** Native WebRTC API in browsers

**STUN/TURN Requirements:**
- STUN server: Simple ICE candidate discovery (coturn, free STUN servers available)
- TURN server: Required if users behind symmetric NATs; bandwidth cost consideration
- Self-host coturn or use service (Twilio, Xirsys)

**Latency Target:** <200ms end-to-end for natural conversation

### 3D Avatar System

**Web:** Three.js with VRM models (popular for signing avatars)
- VRM format supports blend shapes for facial expressions
- Bone-based animation for arm/hand movements

**Mobile:**
- React Native + expo-gl for Three.js rendering
- OR native Unity app with WebGL export
- Avatar rendering is GPU-intensive; consider server-side rendering + streaming for low-end devices

**Sign Animation Approaches:**
1. **Motion capture replay:** Pre-captured VSL sign videos converted to bone animations
2. **Procedural:** IK solvers (FABRIK) to position hands from gloss notation
3. **Hybrid:** Blend shapes for face + keyframed arm motions

**Recommended for v1:** Pre-rendered avatar clips for common signs; gloss-to-clip lookup table. Avoid real-time IK due to complexity.

### Speech Services

**Vietnamese STT Options:**
- Web Speech API (Chrome only, limited Vietnamese support)
- Whisper.cpp (on-device, ~100MB model)
- Coqui STT (open source, requires server)
- VNSpeech (Vietnamese-specific, research-grade)

**Vietnamese TTS Options:**
- Web Speech API (browser TTS, variable quality)
- Coqui TTS (server-side)
- Google Cloud TTS (paid, high quality)
- F5-TTS (open source)

**Recommended:** Start with Web Speech API for prototyping; budget for cloud STT/TTS or self-host Coqui for production.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| STUN/TURN | ICE configuration in WebRTC | Include in app config; rotate if issues |
| SMS Gateway | REST API for SOS | Twilio/Nexmo; need phone number verification |
| Push Notifications | Firebase Cloud Messaging / APNS | For call invites, SOS alerts |
| Cloud STT/TTS | REST or WebSocket API | Fallback if on-device unavailable |
| CDN | Static asset hosting | Avatar models, video dictionary |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| Mobile App ↔ Backend | HTTPS + JWT | RESTful API; version prefix /api/v1/ |
| Web App ↔ Backend | HTTPS + JWT | Same API as mobile; CORS configured |
| Mobile ↔ WebRTC | P2P via WebRTC | Signaling through WebSocket |
| Backend ↔ Avatar Service | gRPC or REST | Internal network; fast serialization |
| ML Inference ↔ Clients | REST (landmark upload) or on-device | Keep payloads small (<10KB) |

## Anti-Patterns

### Anti-Pattern 1: Streaming Raw Video to Server for Recognition

**What people do:** Send camera frames to server for ML processing instead of extracting landmarks on device.

**Why it's wrong:**
- Bandwidth: 640x480 @ 30fps = ~10Mbps upload (prohibitive on mobile)
- Latency: Network round-trip adds 100-500ms
- Privacy: Raw video contains identifiable person data

**Do this instead:** Extract landmarks on device with MediaPipe; send only landmark vectors (1-3KB per frame).

### Anti-Pattern 2: Synchronous Blocking UI During Recognition

**What people do:** Freeze UI while waiting for ML inference; show loading spinner.

**Why it's wrong:** Real-time conversation requires responsive feedback; user doesn't know if recognition is working.

**Do this instead:** Show partial results immediately (landmark visualization); debounce display updates; show confidence scores with timing.

### Anti-Pattern 3: Storing Video/Audio of Conversations

**What people do:** Record video calls for history or review.

**Why it's wrong:**
- Privacy risk: PII in video/audio
- Storage costs explode (1 hour video = ~1GB)
- Legal compliance (GDPR, COPPA for children)

**Do this instead:** Store only text transcript with timestamps. Optionally store anonymous aggregate analytics.

### Anti-Pattern 4: WebRTC Mesh for Group Calls

**What people do:** Connect every participant to every other (full mesh) for 3+ people.

**Why it's wrong:** O(n²) bandwidth; each user uploads once per participant. Quality degrades rapidly.

**Do this instead:** Use Selective Forwarding Unit (SFU) server for 3+ participants; only implement mesh for 1:1 calls.

### Anti-Pattern 5: Hardcoding Model Paths and Configs

**What people do:** Embed model file paths and server URLs directly in code.

**Why it's wrong:** Breaks across environments; requires code changes for config.

**Do this instead:** Use environment variables and config files; inject at build time; have remote config fallback.

## Offline vs Online Scenarios

### Online Mode (Primary)
- Real-time sign recognition via hybrid inference
- Video calls with WebRTC P2P
- SOS with GPS and SMS
- Cloud sync of history and progress
- Dictionary updates and new content

### Offline Mode (Limited)
**Supported:**
- Camera-based sign recognition (if LSTM model downloaded)
- Local history storage (queued for sync)
- Dictionary lookup (cached signs)
- TTS if Web Speech API available

**Not Supported:**
- Video calls (requires signaling server)
- SOS with SMS (requires network)
- STT without browser API
- Avatar rendering (models too large)

**Offline Strategy:**
1. Detect online status on app start
2. Pre-download ML models and dictionary on first launch (WiFi recommended)
3. Queue API calls for background sync using service workers / background tasks
4. Show "offline mode" indicator when disconnected
5. Retry failed syncs with exponential backoff

### Poor Connectivity Mode
- Reduce recognition frame rate (15fps instead of 30fps)
- Disable avatar streaming, show text only
- Lower video call resolution (240p instead of 720p)
- Prioritize SOS functionality with reduced data

## Sources

- [MediaPipe Holistic Documentation](https://google-ai-edge.github.io/mediapipe/solutions/holistic.html) - Landmark extraction for sign language
- [WebRTC Official Documentation](https://webrtc.org/getting-started/peer-connections) - P2P video calling patterns
- [TensorFlow Video Classification](https://www.tensorflow.org/tutorials/video/video_classification) - LSTM for sequence recognition
- [Three.js Documentation](https://threejs.org/docs/) - 3D avatar rendering
- [Web Speech API Specification](https://wicg.github.io/speech-api/) - Browser STT/TTS
- [Sign Language Recognition Survey](https://arxiv.org/abs/2008.00542) - Academic overview of SLR architectures
- [HamNoSys and SiGML](https://www.sign-lang.uni-hamburg.de/meinedfki.html) - Sign notation for avatar animation
- [React Native WebRTC](https://github.com/react-native-webrtc/react-native-webrtc) - Mobile WebRTC implementation

---

*Architecture research for: Sign Language Bridge System*
*Researched: 2026-05-05*
