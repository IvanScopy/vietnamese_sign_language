# Stack Research

**Domain:** Vietnamese Sign Language (VSL) Communication Bridge Application
**Researched:** 2026-05-05
**Confidence:** HIGH

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| **Flutter** | 3.28.0 (stable) | Cross-platform mobile app (iOS/Android) | Superior camera access, Impeller rendering for smooth performance, single codebase for both platforms, excellent performance for real-time ML inference. Flutter's hot reload accelerates development. **Higher confidence than React Native for this use case** due to better camera/Ml pipeline control. |
| **Next.js** | 15.1.8 (latest stable) | Web application framework | Full-stack React framework with App Router, server components for API routes, excellent TypeScript support. Vercel ecosystem for deployment. Handles both frontend and backend API routes seamlessly. |
| **Node.js** | 22.x LTS (or 20.x LTS) | Backend runtime | Latest LTS provides optimal performance and security. Native TypeScript support via ts-node for development. Huge ecosystem of npm packages. |
| **LiveKit** | Self-hosted 1.0+ | Video calling infrastructure | Open-source WebRTC SFU, self-hostable on VPS. Native SDKs for Web, React Native, Flutter, and native mobile. Handles NAT traversal, SFU architecture scales well. **Critical: Use LiveKit over Daily.co for cost control and data sovereignty**. |
| **PostgreSQL** | 16.x or 17.x | Primary database | ACID compliance, excellent for relational data (users, conversations, SOS logs). Full-text search capabilities. JSONB for flexible schema. Mature and reliable. |
| **Prisma** | 6.x | Type-safe ORM | TypeScript-first, generates types from schema. Migration system for schema evolution. Excellent developer experience with Studio GUI. Works well with PostgreSQL. |
| **MediaPipe** | Latest (via flutter_mediapipe or JS) | Hand landmark detection | Google's on-device ML framework. Hand landmark detection extracts 21 3D hand keypoints. **Foundation for sign recognition** - pairs with LSTM classifier. Available for both mobile and web. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **flutter_mediapipe** | latest | MediaPipe integration for Flutter | For on-device hand landmark extraction in mobile app. Wraps MediaPipe Tasks Vision. |
| **@mediapipe/tasks-vision** | 0.10.0+ | Web MediaPipe integration | Browser-based hand landmark detection for web app fallback. |
| **TensorFlow Lite** | 2.16.0+ | On-device ML inference | Deploy LSTM sign recognition model for sub-second inference. GPU delegate for acceleration. |
| **tflite_flutter** | ^0.10.0 | TFLite for Flutter | Flutter plugin for TensorFlow Lite inference. Supports GPU delegation. |
| **socket.io** | 4.8.0 | Real-time bidirectional events | WebSocket with fallback for chat, call notifications, presence indicators. Works with Node.js backend. |
| **socket.io-client** | 4.8.0 | Frontend Socket.io client | For React and Flutter (via socket_io_client package). |
| **@react-three/fiber** | 8.16.0 | React Three.js renderer | Declarative Three.js in React web app. Essential for 3D avatar component. |
| **@react-three/drei** | 9.114.0 | Three.js helpers | Useful hooks and components (useGLTF, Environment, etc.) for avatar scene. |
| **three** | 0.169.0 | 3D graphics engine | Core WebGL library for 3D avatar rendering in browser. |
| **Faster Whisper** | 0.11.0 | Speech-to-text (server-side) | CTranslate2-based Whisper reimplementation, 4x faster than original. Python. Handles Vietnamese with vi Whisper model. |
| **piper-vi** or **espeak-ng** | latest | Text-to-speech (server-side) | Vietnamese TTS. Piper is neural TTS, higher quality. eSpeak NG is simpler, fully open source. |
| **zod** | 3.24.2 | Schema validation | TypeScript-first validation for API inputs. Infers TypeScript types from schemas. |
| **@tanstack/react-query** | 5.60.0 | Server state management | Data fetching, caching, synchronization for web app. Handles API state elegantly. |
| **riverpod** | 2.6.0 | State management (Flutter) | Compile-safe, testable state management. Better than Provider for complex apps. |
| **go_router** | 14.2.0 | Flutter navigation | Declarative routing with deep linking support. Type-safe navigation. |
| **dio** | 5.8.0 | HTTP client (Flutter) | Interceptors, retry logic, better than http package for production. |
| **camera** | ^0.11.0 | Camera access (Flutter) | Flutter's official camera plugin. Supports camera preview, image/video capture. |
| **permission_handler** | ^11.3.0 | Platform permissions | Request camera, microphone, location permissions on mobile. |
| **geolocator** | ^12.0.0 | GPS location | SOS feature - get precise location for emergency alerts. |
| **url_launcher** | ^6.2.0 | Launch external URLs/SMS | SMS fallback for SOS, open map links. |
| **flutter_local_notifications** | 18.0.0 | Push notifications | Local notifications for incoming calls, alerts when app in foreground. |
| **workmanager** | ^0.5.2 | Background tasks (Android) | Handle SOS SMS even when app backgrounded/terminated. |
| **livekit_client** | 2.4.0 | Video calling SDK | LiveKit's Flutter client for video calls. Handles WebRTC signaling, media. |
| **video_player** | ^2.8.0 | Video playback | For 4,000 gesture video dictionary. Hardware accelerated playback. |
| **chewie** | ^1.8.0 | Video player UI wrapper | Customizable video controls UI on top of video_player. |
| **hive** | 2.2.5 | Local cache (Flutter) | Fast NoSQL local storage for caching dictionary videos offline. |
| **shared_preferences** | 2.3.0 | Simple key-value storage | User preferences, auth tokens. |
| **jwt_decoder** | ^2.0.1 | JWT token decoding | Parse auth tokens, check expiration. |
| **connectivity_plus** | ^5.0.0 | Network status | Handle offline/online state transitions gracefully. |
| **lottie** | ^6.4.0 | Animation playback | Loading spinners, success animations for UX polish. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| **Rust** | n/a | Required for Impeller pre-compiled shaders (Flutter). Install via rustup. |
| **Flutter DevTools** | Debugging/Profiling | Performance overlay, memory profiling, widget inspector. |
| **Android Studio** | Android development | AVD emulator, Android SDK management. |
| **Xcode** | iOS development | Required for iOS builds (macOS only). |
| **Vercel CLI** | Deploy/Preview | `vercel --prod` for web app deployment. |
| **Docker & Docker Compose** | Local backend | Spin up PostgreSQL + LiveKit locally. Dev/prod parity. |
| **LiveKit CLI** | LiveKit management | `livekit-server` binary for self-hosting. |
| **Prisma Studio** | Database GUI | `npx prisma studio` for data browsing/editing. |
| **ESLint + Prettier** | Code quality | TypeScript/JavaScript linting and formatting. |
| **Dart Analysis** | Code quality | Built into Flutter. Enable strict mode in analysis_options.yaml. |
| **Jest** | Testing (web) | Unit tests for React components and utilities. |
| **test + mocktail** | Testing (Flutter) | Unit and widget testing framework for Flutter. |
| **Git Hooks** | Pre-commit | Use husky for lint-staged to run linters pre-commit. |

## Installation

```bash
# Flutter mobile app setup
flutter channel stable
flutter upgrade
flutter config --enable-web  # Enable web support too
flutter doctor  # Verify all components

# Create Flutter project
flutter create vsl_bridge --platforms ios,android,web
cd vsl_bridge
flutter pub add riverpod go_router dio camera permission_handler
flutter pub add geolocator url_launcher flutter_local_notifications
flutter pub add workmanager livekit_client video_player chewie
flutter pub add hive shared_preferences jwt_decoder connectivity_plus lottie
flutter pub add tflite_flutter  # For on-device ML

# Web app setup (in separate directory or monorepo)
npx create-next-app@latest vsl-bridge-web --typescript --tailwind --app
cd vsl-bridge-web
npm install @tanstack/react-query @react-three/fiber @react-three/drei three
npm install socket.io-client zod livekit-client

# Backend setup
mkdir backend && cd backend
npm init -y
npm install @livekit/server-sdk @fastify/websocket socket.io @prisma/client
npm install faster-whisper  # or openai-whisper
npm install piper-tts  # or espeak-ng bindings
npm install zod bcrypt jsonwebtoken
npm install -D typescript ts-node @types/node prisma

# Initialize Prisma
npx prisma init
# Configure datasource in prisma/schema.prisma for PostgreSQL

# Local development with Docker
docker compose up -d postgres livekit

# LiveKit self-hosting (alternative to Docker)
livekit-server --dev --bind-address 0.0.0.0:7880 --ws-bind-address 0.0.0.0:7881 --rtc-bind-address 0.0.0.0:7882 --api-key devkey --api-secret secret
```

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| **Flutter (Mobile)** | React Native | If team has strong React expertise. React Native Vision Camera + ML Kit for landmarks. But Flutter's Impeller + native performance edge better for real-time ML pipeline. |
| **LiveKit (Video)** | Daily.co | If you prefer managed service over self-hosting. Daily reduces ops burden but adds recurring costs (~$0.003/min). LiveKit on $5/mo VPS can handle 10+ concurrent calls. |
| **PostgreSQL** | MongoDB | If schema flexibility is critical for evolving VSL gesture metadata. PostgreSQL JSONB provides flexibility while maintaining ACID guarantees. |
| **Prisma** | Drizzle | Drizzle offers more SQL-like query style. Prisma has better migrations GUI (Studio) and type generation. Choose Drizzle if you want full SQL control. |
| **Faster Whisper (STT)** | Vosk | Vosk is fully offline, no GPU required. Slower and Vietnamese models less mature. Use Vosk only if privacy/offline-first is non-negotiable. |
| **Faster Whisper** | Whisper.cpp | Whisper.cpp excellent for server-side deployment. Faster Whisper easier Python integration. Choose Whisper.cpp if deploying Go service. |
| **piper-tts (TTS)** | Festival/Festival-VN | Older but runs on CPU. Piper neural TTS much higher quality. Use Festival only on extremely resource-constrained hardware. |
| **Three.js (Web 3D)** | Babylon.js | Babylon.js more feature-complete for character animation. Three.js smaller bundle, larger ecosystem. Choose Babylon if 3D is core differentiator. |
| **TensorFlow Lite** | ONNX Runtime Mobile | ONNX Runtime supports more model formats. TFLite better tooling for Flutter, smaller binary. Use ONNX if you need PyTorch model export workflow. |
| **MediaPipe** | OpenPose | OpenPose older, less maintained. MediaPipe is Google-backed, optimized for mobile. OpenPose only if you need specific pose formats. |
| **Socket.io** | Supabase Realtime | Supabase adds database realtime sync "for free". But you're self-hosting Postgres, Supabase Realtime adds complexity. Socket.io simpler for chat/notifications. |
| **Riverpod (Flutter)** | Bloc | Bloc more structured, testable. Riverpod simpler, less boilerplate for state management. Use Bloc if you need strict unidirectional data flow. |

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| **Firebase** | Vendor lock-in, costs scale with usage. Vietnamese regulations may require data sovereignty. | Self-hosted PostgreSQL + LiveKit on VPS. |
| **React Native for mobile** | New architecture (Fabric) still maturing. Camera + ML pipeline more complex to set up than Flutter. | Flutter 3.28 with Impeller. |
| **WebRTC raw (without SFU)** | P2P mesh doesn't scale beyond 2-3 participants. NAT traversal issues. | LiveKit SFU architecture. |
| **Cloud-managed video APIs** (Twilio, Agora) | Expensive for scale (~$0.004/min). Vendor dependency. | Self-hosted LiveKit (~$5/mo VPS). |
| **Pure Python backend without ASGI** | Sync Python can't handle WebSocket concurrency well. | Fastify (Node.js) or FastAPI with async/uvicorn. |
| **MySQL 5.x** | No JSONB, weaker full-text search than PostgreSQL. | PostgreSQL 16/17. |
| **In-house sign recognition model training** | Requires thousands of labeled VSL videos, ML expertise. Too complex for v1. | Pre-trained MediaPipe + LSTM on your labeled dataset (transfer learning). |
| **Custom WebRTC implementation** | Extremely complex, security-critical. STUN/TURN/ICE/SDP are difficult to get right. | LiveKit (battle-tested WebRTC stack). |
| **Mongoose/MongoDB ORMs** | Less type-safe than Prisma. Schema drift in NoSQL can cause runtime bugs. | Prisma with PostgreSQL (type-safe, explicit schema). |
| **Legacy TensorFlow.js** | Slower than native TFLite, larger bundle size. | TensorFlow Lite for mobile, server-side PyTorch/TensorFlow. |
| **getUserMedia raw WebRTC** | Too low-level for video calling UI. Handles reconnection poorly. | LiveKit SDK with prebuilt components. |
| **Push notification services without fallback** | iOS/Android push unreliable. No fallback for foreground notifications. | Socket.io + local notifications hybrid approach. |

## Stack Patterns by Variant

**If budget is extremely constrained (nonprofit):**
- Use Free Tier: Vercel Hobby (web), Fly.io free tier (LiveKit + backend), Neon Free Tier (PostgreSQL)
- Total monthly cost: ~$0-5
- Trade-offs: Limited concurrent users, occasional cold starts on serverless

**If faster MVP is priority (funding available):**
- Use managed services: Daily.co (video), Supabase (DB + auth + realtime), Railway/Render (backend)
- Skip self-hosting LiveKit complexity
- Total monthly cost: ~$50-200 depending on usage

**If learning is primary, not calling:**
- Defer LiveKit entirely - focus on dictionary/learning features first
- Add video calling in phase 2 after validating core recognition
- Reduces initial complexity significantly

**If device-side inference preferred (privacy/offline):**
- Full LSTM + MediaPipe pipeline in Flutter via tflite_flutter
- Backend only for auth, dictionary storage, SOS SMS
- STT/TTS can use device APIs or smaller offline models
- Reduces server costs but increases app size (~50MB for TFLite models)

## Version Compatibility

| Package A | Compatible With | Notes |
|-----------|-----------------|-------|
| Flutter 3.28.0 | Dart 3.6+ | Requires Dart 3.6. All Flutter plugins must support null safety. |
| LiveKit Flutter SDK 2.4.0 | LiveKit server 1.0+ | Client/server API compatibility. Pin server version. |
| Next.js 15.1.8 | React 19 | Uses React 19 features. Ensure all React packages aligned. |
| Prisma 6.x | PostgreSQL 12-17 | Works with all modern PostgreSQL versions. Tested on 16/17. |
| socket.io 4.8.0 | socket.io-client 4.8.0 | Client and server must match major version. |
| @react-three/fiber 8.16.0 | Three.js 0.169.0 | R1fiber version must match Three.js major version. |
| MediaPipe Tasks Vision | Flutter camera plugin | MediaPipe processes camera frames via platform channels. Ensure image format compatibility (NV21/YUV). |
| TensorFlow Lite 2.16.0 | tflite_flutter 0.10.0 | TFLite interpreter version compatibility matters for opset. |
| Faster Whisper 0.11.0 | Python 3.10-3.13 | CTranslate2 binary wheels available for these Python versions. |
| Riverpod 2.6.0 | Flutter 3.19+ | Riverpod 3.0 will have breaking changes. Pin to 2.x until ready. |

## Technology Stack Summary

```
┌─────────────────────────────────────────────────────────────────────┐
│                         VSL Bridge Stack                           │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌────────────┐     ┌────────────┐     ┌────────────┐            │
│  │   Flutter  │     │  Next.js   │     │   Node.js  │            │
│  │  3.28.0    │     │  15.1.8    │     │  22.x LTS  │            │
│  │ (Mobile +  │     │   (Web)    │     │ (Backend)  │            │
│  │   Web)     │     │            │     │            │            │
│  └─────┬──────┘     └─────┬──────┘     └─────┬──────┘            │
│        │                  │                  │                   │
│        └──────────────────┼──────────────────┘                   │
│                           │                                       │
│                    ┌──────▼─────────────────────┐                │
│                    │    PostgreSQL 16/17        │                │
│                    │    + Prisma ORM            │                │
│                    └───────────────────────────┘                │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                     AI/ML Stack                          │    │
│  │  MediaPipe (landmarks) → LSTM/TFLite (sign classifier) │    │
│  │  Faster Whisper (STT) / Piper-tts (TTS)                │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                  Real-time Stack                         │    │
│  │  LiveKit SFU (self-hosted) + Socket.io (chat/notify)    │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                     │
│  ┌──────────────────────────────────────────────────────────┐    │
│  │                    3D Avatar Stack                       │    │
│  │  Three.js + @react-three/fiber (Web)                     │    │
│  │  Flutter 3D (future: consider flutter_3d_obj or Unity)  │    │
│  └──────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Sources

- `/google-ai-edge/mediapipe` — Hand landmark detection, on-device ML pipelines
- `/websites/flutter_dev` — Flutter 3.28, Impeller rendering, camera plugin
- `/websites/webrtc` — WebRTC protocol, media constraints, RTCPeerConnection
- `/websites/livekit_io` — LiveKit SDKs, self-hosting guide, React Native/Flutter support
- `/pmndrs/react-three-fiber` — React Three.js integration, useFrame hook, animation patterns
- `/mrdoob/three.js` — 3D graphics, GLTF loading, AnimationMixer, character rigging
- `/websites/nextjs` — Next.js 15 App Router, server components, edge runtime deprecation
- `/prisma/web` — Prisma ORM, migrations, TypeScript integration
- `/websites/postgresql` — PostgreSQL 16/17 features, JSONB, full-text search
- `/websites/socket_io_v4` — Socket.io v4, reconnection, fallback transports
- `/websites/tanstack_query_v5` — TanStack Query v5, server state management
- `/alphacep/vosk-api` — Vosk offline STT, Vietnamese language support
- `/openai/whisper` — Whisper model architecture, multilingual transcription
- `/websites/daily_co` — Daily video API as managed alternative comparison
- Web search — Vietnamese STT/TTS ecosystem (Faster Whisper, Piper), React Native vs Flutter performance

---
*Stack research for: Vietnamese Sign Language (VSL) Bridge Application*
*Researched: 2026-05-05*
*Confidence: HIGH (researched 20+ libraries, verified current versions)*
