# Phase 1: Foundation & Authentication - Research

**Researched:** 2025-05-05
**Domain:** Backend Infrastructure, Authentication, STT/TTS, Real-time Notifications, Docker Deployment
**Confidence:** HIGH (core libraries verified), MEDIUM (pricing/region availability)

## Summary

Phase 1 establishes the backend foundation for the VSL Bridge, including user authentication (JWT with email+Google OAuth), Vietnamese STT/TTS services with cloud-primary/fallback strategy, real-time notification infrastructure (Socket.io + FCM/APNs), and Docker Compose deployment on a single $6-10/month VPS. The architecture uses a monolithic Node.js REST API with PostgreSQL, Redis, and self-hosted LiveKit for WebRTC signaling.

**Primary recommendation:** Use Express.js with Prisma ORM, deploy via Docker Compose on a $6/month DigitalOcean droplet (1GB RAM), with Groq Whisper + ElevenLabs as primary cloud providers and Whisper.cpp + Coqui TTS as self-hosted fallbacks. Vietnamese is supported in all selected providers (Whisper large-v3 multilingual, ElevenLabs v3, Coqui XTTS-v2). JWT refresh token rotation should be implemented with a token blacklist in Redis for revocation.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| User Authentication | API / Backend | — | JWT signing, OAuth flows, credential verification belong in backend |
| STT/TTS Processing | API / Backend | Optional: Self-hosted ML containers | Heavy ML inference; can be separate services but orchestrated by API |
| Real-time Notifications | API / Backend | — | Socket.io server runs with API; push notifications sent from same layer |
| Video Signaling | API / Backend | LiveKit Server | Backend generates tokens, LiveKit handles media relay |
| Data Persistence | Database / Storage | — | PostgreSQL stores users, sessions, conversation history |
| Docker Deployment | Infrastructure | — | Orchestration layer above all services |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **Node.js** | 22.x LTS | Backend runtime | Latest LTS, modern ES features, excellent async support for WebSockets |
| **Express.js** | 4.21.1 | REST API framework | Minimal, battle-tested, huge middleware ecosystem |
| **Prisma** | 6.x (latest) | Type-safe ORM | PostgreSQL optimization, migrations, Studio GUI, auto-generated TypeScript types |
| **PostgreSQL** | 16.x or 17.x | Primary database | ACID compliance, JSONB for flexible schemas, full-text search |
| **Redis** | 7.x | Caching + token blacklist | Rate limiting, refresh token revocation, session metadata |
| **jsonwebtoken** | 9.0.2 | JWT signing/verification | Industry standard, supports RS256/ES256, v9 has security fixes [VERIFIED: npm registry] |
| **socket.io** | 4.8.0 | Real-time events | Auto-reconnection, HTTP fallback, rooms for notifications |

### STT/TTS Services

| Library/Service | Version/Pricing | Purpose | Vietnamese Support |
|-----------------|-----------------|---------|-------------------|
| **Groq Whisper** | $0.14/min (large-v3) [ASSUMED] | Cloud STT primary | Whisper large-v3 multilingual supports 99+ languages including Vietnamese [VERIFIED: Context7] |
| **Whisper.cpp** | Free (self-hosted) | STT fallback | Multilingual models support Vietnamese via language code `vi` [VERIFIED: Context7] |
| **ElevenLabs** | $5/mo for 100k chars | Cloud TTS primary | v3 multilingual models support Vietnamese [VERIFIED: Context7] |
| **Coqui TTS** | Free (self-hosted) | TTS fallback | XTTS-v2 supports Vietnamese (language code: `vi`) [VERIFIED: Context7] |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **socket.io-client** | 4.8.0 | Frontend Socket.io client | Web and Flutter mobile |
| **bcrypt** | 5.1.1 | Password hashing | Email/password auth |
| **passport.js** | 0.7.0 (optional) | OAuth middleware | Google OAuth integration |
| **cors** | 2.8.5 | CORS headers | Cross-origin API access |
| **helmet** | 7.5.0 | Security headers | Production security |
| **express-rate-limit** | 7.5.0 | Rate limiting | API protection |
| **@firebase/* (fcm)** | latest | Push notifications | Web FCM via service workers |
| **node-apn** | latest | APNs push | iOS push notifications |
| **@livekit/server** | 2.x | LiveKit server | Video call signaling |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| **Prisma** | Drizzle ORM | Drizzle more SQL-like, Prisma has better migration GUI and type generation |
| **Socket.io** | Supabase Realtime | Supabase adds DB realtime but adds complexity; Socket.io simpler for chat/notifications |
| **Express** | Fastify | Fastify slightly faster, but Express has larger middleware ecosystem |
| **Groq Whisper** | OpenAI Whisper API | OpenAI costs ~2x more; Groq offers same model at lower cost |
| **ElevenLabs** | Google Cloud TTS | Google Vietnamese voices available [ASSUMED], but ElevenLabs quality generally superior |
| **Whisper.cpp** | Vosk | Vosk fully offline but slower, Vietnamese models less mature |
| **Redis** | In-memory store | Redis provides persistence, clustering, production-ready |
| **DigitalOcean** | Hetzner Cloud | Hetzner cheaper but fewer regions; DO has better global coverage |

## Installation

\`\`\`bash
# Backend setup
mkdir vsl-backend && cd vsl-backend
npm init -y

# Core dependencies
npm install express@4.21.1 prisma@latest @prisma/client jsonwebtoken@9.0.2
npm install socket.io@4.8.0 bcrypt@5.1.1 cors@2.8.5 helmet@7.5.0
npm install express-rate-limit@7.5.0 dotenv@16.4.5

# OAuth dependencies
npm install passport@0.7.0 passport-google-oauth20@2.0.0
npm install express-session@1.18.0 connect-pg-simple@8.0.0

# STT/TTS clients (Node.js bindings)
npm install @groq/sdk@latest
npm install elevenlabs@latest

# FCM/APNs
npm install firebase-admin@latest
npm install node-apn@latest

# LiveKit server SDK
npm install livekit-server-sdk@latest
npm install livekit-client@latest

# Development tools
npm install -D typescript@latest ts-node@latest @types/node@latest
npm install -D @types/express @types/jsonwebtoken @types/bcrypt @types/cors
npm install -D jest@latest supertest@latest

# Initialize Prisma
npx prisma init

# Install Docker services (outside Node)
docker pull postgres:17-alpine
docker pull redis:7-alpine
docker pull livekit/livekit-server:latest
docker pull ghcr.io/coqui-tts/tts-cpu:latest
docker pull ghcr.io/ggerganov/whisper.cpp:latest
\`\`\`

## Architecture Patterns

### System Architecture Diagram

\`\`\`
┌─────────────────────────────────────────────────────────────────────┐
│                            Clients                                 │
│  ┌─────────────┐               ┌─────────────┐                    │
│  │ Flutter App │               │   Web App    │                    │
│  │  (Mobile)   │               │  (Next.js)   │                    │
│  └──────┬──────┘               └──────┬──────┘                    │
│         │  HTTP/WebSocket            │ HTTP/WebSocket              │
│         │  (api.vslbridge.com)       │ (api.vslbridge.com)         │
└─────────┼────────────────────────────┼─────────────────────────────┘
          │                            │
          │                            │
    ┌─────▼────────────────────────────▼─────┐
    │        Node.js API Server              │
    │    ┌─────────────────────────────┐    │
    │    │  REST API (/api/v1/*)       │    │
    │    │  Socket.io (real-time)      │    │
    │    │  Auth middleware (JWT)      │    │
    │    │  STT/TTS strategy layer     │    │
    │    └─────────────┬───────────────┘    │
    │                  │                      │
    │    ┌─────────────┴───────────────┐    │
    │    │   Prisma ORM                │    │
    │    └─────────────┬───────────────┘    │
    │                  │                      │
    └──────────────────┼──────────────────────┘
                       │
           ┌───────────┼───────────┐
           │           │           │
    ┌──────▼───┐ ┌────▼─────┐ ┌──▼─────────┐
    │PostgreSQL│ │  Redis    │ │LiveKit     │
    │   DB     │ │  Cache    │ │ Server     │
    └──────────┘ └───────────┘ └────────────┘
           │                     │
    ┌──────▼─────────────────────▼─────┐
    │      ML Services (optional)      │
    │  ┌────────────┐  ┌────────────┐ │
    │  │Whisper.cpp │  │ Coqui TTS  │ │
    │  │  Server    │  │  Server    │ │
    │  └────────────┘  └────────────┘ │
    └──────────────────────────────────┘
           │
    ┌──────▼────────────────────────────┐
    │   Cloud STT/TTS (fallback)        │
    │  ┌────────────┐  ┌─────────────┐ │
    │  │  Groq API  │  │ ElevenLabs  │ │
    │  └────────────┘  └─────────────┘ │
    └───────────────────────────────────┘
\`\`\`

### Recommended Project Structure

\`\`\`
src/
├── config/
│   ├── database.ts          # Prisma config, DATABASE_URL
│   ├── redis.ts             # Redis client setup
│   ├── socket.ts            # Socket.io server setup
│   ├── stt.ts               # STT provider abstraction + implementations
│   ├── tts.ts               # TTS provider abstraction + implementations
│   └── livekit.ts           # LiveKit server config
├── middleware/
│   ├── auth.ts              # JWT verification middleware
│   ├── rateLimit.ts         # Rate limiting
│   └── errorHandler.ts      # Centralized error handling
├── routes/
│   ├── auth.routes.ts       # /api/v1/auth/*
│   ├── stt.routes.ts        # /api/v1/stt/*
│   ├── tts.routes.ts        # /api/v1/tts/*
│   ├── notifications.routes.ts  # /api/v1/notifications/*
│   └── livekit.routes.ts    # /api/v1/livekit/*
├── services/
│   ├── auth.service.ts      # Registration, login, token rotation
│   ├── user.service.ts      # User profile management
│   ├── notification.service.ts  # Socket + FCM/APNs push
│   └── token.service.ts     # Refresh token storage/revocation
├── models/                  # Generated by Prisma (prisma generate)
├── types/
│   └── api.ts               # Shared type definitions
├── utils/
│   ├── logger.ts            # Winston/Pino logger
│   └── validator.ts         # Zod validation schemas
├── server.ts                # Express + Socket.io bootstrap
└── docker-compose.yaml      # Local dev compose file
\`\`\`

### Pattern 1: STT/TTS Strategy Pattern with Fallback

**What:** Abstract STT/TTS providers behind a common interface with automatic failover.

**When to use:** When you need cloud primary with self-hosted fallback for cost control, offline capability, or resilience.

**Example:**
\`\`\`typescript
// src/config/stt.ts
export interface STTProvider {
  transcribe(audio: Buffer, language?: string): Promise<string>;
  healthCheck(): Promise<boolean>;
}

export class GroqSTT implements STTProvider {
  constructor(private groq: Groq) {}
  
  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    const result = await this.groq.audio.transcriptions.create({
      file: audio,
      model: 'whisper-large-v3',
      language: language,
      response_format: 'json',
      temperature: 0.0,
    });
    return result.text;
  }
  
  async healthCheck(): Promise<boolean> {
    try {
      await this.groq.audio.transcriptions.create({
        file: Buffer.from('test'), // minimal test
        model: 'whisper-large-v3',
      });
      return true;
    } catch {
      return false;
    }
  }
}

export class WhisperCppSTT implements STTProvider {
  constructor(private endpoint: string) {}
  
  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    const response = await fetch(`${this.endpoint}/transcribe`, {
      method: 'POST',
      body: audio,
      headers: { 'Content-Type': 'audio/wav' },
    });
    const { text } = await response.json();
    return text;
  }
}

export class STTManager {
  private providers: STTProvider[] = [];
  
  constructor(primary: STTProvider, fallback?: STTProvider) {
    this.providers = [primary];
    if (fallback) this.providers.push(fallback);
  }
  
  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    for (const provider of this.providers) {
      try {
        if (await provider.healthCheck()) {
          return await provider.transcribe(audio, language);
        }
      } catch (error) {
        console.warn(`STT provider failed: ${error.constructor.name}`);
        continue;
      }
    }
    throw new Error('All STT providers failed');
  }
}
\`\`\`

### Pattern 2: JWT Refresh Token Rotation

**What:** On refresh, issue new access token + new refresh token, invalidate old refresh token in Redis blacklist.

**When to use:** All production JWT auth with refresh tokens.

**Example:**
\`\`\`typescript
// src/services/token.service.ts
import jwt from 'jsonwebtoken';
import { RedisClient } from './redis.client';

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = 7 * 24 * 60 * 60; // 7 days in seconds

export class TokenService {
  constructor(private redis: RedisClient, private jwtSecret: string) {}
  
  async generateTokens(userId: string): Promise<{access: string, refresh: string}> {
    const accessToken = jwt.sign(
      { sub: userId, type: 'access' },
      this.jwtSecret,
      { expiresIn: ACCESS_TOKEN_TTL, algorithm: 'HS256' }
    );
    
    const refreshToken = jwt.sign(
      { sub: userId, type: 'refresh', jti: crypto.randomUUID() },
      this.jwtSecret,
      { expiresIn: REFRESH_TOKEN_TTL, algorithm: 'HS256' }
    );
    
    // Store refresh token jti in Redis with TTL
    await this.redis.setEx(
      `refresh:${userId}:${jwt.decode(refreshToken).jti}`,
      REFRESH_TOKEN_TTL,
      'valid'
    );
    
    return { access: accessToken, refresh: refreshToken };
  }
  
  async rotateRefreshToken(
    oldRefreshToken: string
  ): Promise<{access: string, refresh: string}> {
    const decoded = jwt.decode(oldRefreshToken) as any;
    
    // Verify old refresh token hasn't been revoked
    const exists = await this.redis.get(`refresh:${decoded.sub}:${decoded.jti}`);
    if (!exists) {
      throw new Error('Refresh token revoked');
    }
    
    // Revoke old refresh token
    await this.redis.del(`refresh:${decoded.sub}:${decoded.jti}`);
    
    // Issue new tokens
    return this.generateTokens(decoded.sub);
  }
  
  async revokeAllTokens(userId: string): Promise<void> {
    // Scan and delete all refresh tokens for user
    const pattern = `refresh:${userId}:*`;
    const keys = await this.redis.keys(pattern);
    if (keys.length) await this.redis.del(keys);
  }
}
\`\`\`

### Pattern 3: Socket.io + Push Notification Hybrid

**What:** Use Socket.io for in-app notifications, FCM/APNs for background/closed app.

**When to use:** Real-time messaging with reliable delivery when app not active.

**Example:**
\`\`\`typescript
// src/config/socket.ts
import { Server as SocketIOServer } from 'socket.io';
import { createServer } from 'http';

export function setupSocket(server: any, notificationService: NotificationService) {
  const io = new SocketIOServer(server, {
    cors: { origin: process.env.CLIENT_ORIGIN, credentials: true },
    transports: ['websocket', 'polling'],
  });
  
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token;
    try {
      const decoded = verifyJWT(token);
      socket.data.userId = decoded.sub;
      next();
    } catch (err) {
      next(new Error('Unauthorized'));
    }
  });
  
  io.on('connection', (socket) => {
    const userId = socket.data.userId;
    socket.join(`user:${userId}`);
    
    socket.on('disconnect', () => {
      socket.leave(`user:${userId}`);
    });
  });
  
  return io;
}

// src/services/notification.service.ts
export class NotificationService {
  constructor(
    private io: SocketIOServer,
    private fcm: admin.messaging.MessagingService,
    private apn: APN
  ) {}
  
  async sendToUser(
    userId: string,
    payload: { title: string; body: string; type: string; data?: any }
  ): Promise<void> {
    // In-app via Socket.io
    this.io.to(`user:${userId}`).emit('notification', payload);
    
    // Push via FCM/APNs
    const tokens = await this.getUserPushTokens(userId);
    if (tokens.fcm) {
      await this.sendFCM(tokens.fcm, payload);
    }
    if (tokens.apn) {
      await this.sendAPNs(tokens.apn, payload);
    }
  }
  
  private async sendFCM(token: string, payload: any): Promise<void> {
    const message: admin.messaging.Message = {
      token,
      notification: { title: payload.title, body: payload.body },
      data: { type: payload.type, ...payload.data },
      priority: 'high', // for SOS
      android: { priority: 'high' },
      apns: { headers: { 'apns-priority': '10' } },
    };
    await this.fcm.send(message);
  }
  
  private async sendAPNs(token: string, payload: any): Promise<void> {
    const note = new apn.Notification();
    note.alert = { title: payload.title, body: payload.body };
    note.payload = { type: payload.type, ...payload.data };
    note.pushType = 'alert';
    note.priority = 10; // immediate delivery
    note.topic = process.env.APNS_TOPIC;
    await this.apn.send(note, token);
  }
}
\`\`\`

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Password hashing | Custom bcrypt wrapper | bcrypt with 12+ rounds | bcrypt handles salting, work factor, timing attacks |
| JWT token generation | Manual crypto | jsonwebtoken library | HS256/RS256 implementation complexity, algorithm confusion attacks |
| OAuth flow | Custom OAuth2 | passport-google-oauth20 | OAuth2 has many edge cases (state, PKCE, token exchange) |
| Real-time messaging | Raw WebSockets | Socket.io | Fallback transports, reconnection, rooms, ACKs |
| Database schema migrations | Manual SQL | Prisma migrate | Schema drift, rollbacks, team sync |
| Rate limiting | Manual counters | express-rate-limit with Redis store | Distributed rate limiting needs atomic Redis ops |
| Token revocation | Custom DB table | Redis blacklist with TTL | Fast lookup, automatic expiry, distributed-safe |
| Docker orchestration | Manual scripts | Docker Compose | Service dependencies, networks, volume management |
| Video call signaling | Custom WebRTC | LiveKit SFU | NAT traversal, SFU architecture, TURN server management |

**Key insight:** This domain has complex security and reliability requirements. Custom implementations introduce subtle vulnerabilities (JWT algorithm confusion, timing attacks on bcrypt, WebRTC ICE failure modes). Use battle-tested libraries for auth, real-time, and media infrastructure.

## Common Pitfalls

### Pitfall 1: JWT Refresh Token Storage on Mobile

**What goes wrong:** Storing refresh tokens in `SharedPreferences` (Android) or `UserDefaults` (iOS) leaves them exposed to backup extraction and device compromise.

**Why it happens:** Developers default to simple key-value storage without understanding platform-specific secure storage.

**How to avoid:** Use `flutter_secure_storage` which leverages Android Keystore (RSA OAEP + AES-GCM) and iOS Keychain (hardware-backed on devices with Secure Enclave).

**Warning signs:** Token visible in device backup exports, accessible without biometrics when it shouldn't be.

**Implementation:**
\`\`\`dart
// Use flutter_secure_storage with appropriate options
final storage = FlutterSecureStorage(
  aOptions: AndroidOptions(
    keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
    storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
  ),
  iOptions: IOSOptions(
    accessibility: KeychainAccessibility.first_unlock,
    synchronizable: false, // Don't sync across devices for refresh tokens
  ),
);
await storage.write(key: 'refresh_token', value: refreshToken);
\`\`\`

---

### Pitfall 2: Socket.io Battery Drain on Mobile

**What goes wrong:** Keeping a persistent WebSocket connection when the app is backgrounded drains battery significantly on mobile.

**Why it happens:** Socket.io documentation explicitly warns against using it in background services; mobile OSes restrict background network activity anyway.

**How to avoid:** Disconnect Socket.io when app goes to background, rely on FCM/APNs for notifications. Reconnect when app returns to foreground.

**Warning signs:** Users reporting rapid battery drain, app killed by OS for background network use.

---

### Pitfall 3: Missing TURN Server in LiveKit

**What goes wrong:** WebRTC connections fail for users behind symmetric NATs or restrictive firewalls without a TURN relay.

**Why it happens:** LiveKit's TURN server is disabled by default; developers assume STUN is sufficient.

**How to avoid:** Enable TURN in LiveKit configuration with TLS on port 5349 or UDP on 443 for better firewall traversal.

\`\`\`yaml
# livekit.yaml
turn:
  enabled: true
  tls_port: 5349
  domain: turn.yourdomain.com
  cert_file: /path/to/turn.crt
  key_file: /path/to/turn.key
\`\`\`

**Warning signs:** Users on corporate networks or certain ISPs can't establish video calls (ICE failed).

---

### Pitfall 4: Refresh Token Not Rotating

**What goes wrong:** Re-issuing the same refresh token on login creates an undetectable stolen token attack vector.

**Why it happens:** Token rotation adds implementation complexity (Redis blacklist management).

**How to avoid:** Always issue a new refresh token on refresh. Store the old token's `jti` in a Redis blacklist with TTL matching the old token's expiry.

---

### Pitfall 5: Hardcoding Database Credentials

**What goes wrong:** Database passwords in source code or unencrypted `.env` files committed to Git.

**Why it happens:** Convenience during development; forgetting to use secret management.

**How to avoid:** Use Docker secrets, environment variables from CI/CD secret store, or Vercel/Railway environment config. Never commit `.env` (add to `.gitignore`).

---

### Pitfall 6: Insufficient Rate Limiting

**What goes wrong:** Unauthenticated endpoints (login, STT/TTS) left unprotected, enabling DoS or API cost exhaustion.

**Why it happens:** Rate limiting is often added only to authenticated endpoints.

**How to avoid:** Apply `express-rate-limit` to all public endpoints, use Redis store for distributed rate limiting, implement different limits per endpoint (stricter for auth).

---

### Pitfall 7: Vietnamese Language Not Specified

**What goes wrong:** Whisper auto-detects language but accuracy suffers; Vietnamese-specific TTS uses wrong voice/language code.

**Why it happens:** Not passing explicit `language='vi'` parameter to STT/TTS APIs.

**How to avoid:** Always specify Vietnamese language code:
- Whisper: `language: 'vi'`
- Coqui XTTS: `language='vi'`
- ElevenLabs: `language_code='vi'` or `language='vi'` depending on model

---

### Pitfall 8: Docker Compose Without Health Checks

**What goes wrong:** API starts before PostgreSQL is ready, causing startup failures and container restarts.

**Why it happens:** `depends_on` without `healthcheck` only waits for container start, not service readiness.

**How to avoid:** Define health checks for all services, use `condition: service_healthy`:

\`\`\`yaml
services:
  api:
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_healthy
  
  db:
    image: postgres:17-alpine
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]
      interval: 10s
      timeout: 5s
      retries: 5
\`\`\`

---

### Pitfall 9: Using HS256 with Multiple Services

**What goes wrong:** Using symmetric HS256 means all services (API, workers) share the secret; compromise of one service compromises all tokens.

**Why it happens:** HS256 is simpler to set up than RS256 (public-key crypto).

**How to avoid:** Use RS256 or ES256 for production. The API signs with private key; all other services verify with public key. This allows secure token verification without exposing signing capability.

---

### Pitfall 10: Blocking Main Thread on ML Inference

**What goes wrong:** Running Whisper.cpp or Coqui TTS synchronously in the Node.js event loop blocks all other requests.

**Why it happens:** ML inference is CPU-intensive; developers call it directly in request handlers.

**How to avoid:** Run ML services as separate containers with their own HTTP APIs. The Node.js API makes non-blocking HTTP calls to these services. Alternatively, use worker threads or a message queue.

## Runtime State Inventory

*This section is not applicable for a greenfield project with no existing runtime state to inventory.*

## Open Questions

1. **VieNeu-TTS Vietnamese Quality Verification**
   - What we know: Mentioned as a potential Vietnamese TTS option in project context; specific quality metrics and integration details not found in research.
   - What's unclear: Whether VieNeu-TTS is production-ready, model availability, API integration complexity.
   - Recommendation: Test ElevenLabs + Coqui XTTS first; research VieNeu-TTS as future optimization if budget constraints require fully self-hosted solution.

2. **Google Cloud TTS Vietnamese Pricing**
   - What we know: Google offers Vietnamese voices (Neural2 and Standard) [ASSUMED based on typical GCP language coverage].
   - What's unclear: Exact per-million-character pricing for Vietnamese voices, quality comparison to ElevenLabs.
   - Recommendation: Evaluate ElevenLabs quality first; if cost is prohibitive, query GCP pricing API for `vi-VN` voices.

3. **VPS Region for Vietnamese Users**
   - What we know: Project context mentions Singapore or EU for cost reasons; no Vietnam residency requirement.
   - What's unclear: Latency impact for Vietnam users from Singapore vs local VPS providers.
   - Recommendation: Choose Singapore region (DigitalOcean SGP1 or Hetzner Helsinki with good Asian connectivity) for $6-10/month tier. Test latency; if unacceptable, investigate Vietnam-based providers (cost may increase).

4. **Whisper.cpp Server Architecture**
   - What we know: whisper.cpp provides CLI and server examples.
   - What's unclear: Optimal concurrency model for simultaneous requests on a $6 VPS (1-2 CPU cores).
   - Recommendation: Use `whisper-server` with thread pool (`--threads`, `--processors`); limit concurrent requests to avoid memory exhaustion.

5. **LiveKit TURN Certificate Management**
   - What we know: TURN requires TLS certificates for secure relay.
   - What's unclear: Whether to use self-signed (with client override) or Let's Encrypt for TURN domain.
   - Recommendation: Use same Let's Encrypt certificate as main domain; TURN domain should be subdomain of main domain for certificate simplicity.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Backend API | ✗ (needs install) | 22.x LTS required | nvm install 22 |
| Docker | PostgreSQL/Redis/LiveKit | ✗ (needs install) | 24.x+ required | Manual install or upgrade |
| PostgreSQL | Data persistence | ✗ (Docker container) | 17.x (Docker) | — |
| Redis | Caching/revocation | ✗ (Docker container) | 7.x (Docker) | — |
| FFmpeg | Audio preprocessing | ? (check system) | any | apt install ffmpeg |

**Missing dependencies with no fallback:**
- **Docker Compose v2** — Required for orchestration; install via Docker Desktop or standalone

**Missing dependencies with fallback:**
- **Node.js** — Install via nvm (recommended) or system package manager
- **FFmpeg** — Required for audio format conversion before STT; install via package manager if not present

**Note:** ML services (Whisper.cpp, Coqui TTS) run as Docker containers, so no local ML dependencies needed beyond Docker.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | Jest (TypeScript via ts-jest) |
| Config file | `jest.config.ts` |
| Quick run command | `npm test -- --passWithNoTests` |
| Full suite command | `npm test -- --coverage --verbose` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| ACC-01 | User registration creates hashed password | unit | `npm test -- auth.service.test.ts` | ❌ Wave 0 |
| ACC-02 | JWT access token expires in 15min | unit | `npm test -- token.service.test.ts` | ❌ Wave 0 |
| ACC-03 | Refresh token rotation invalidates old token | unit | `npm test -- token.service.test.ts` | ❌ Wave 0 |
| NOTIF-01 | Socket.io emits to user room | integration | `npm test -- socket.test.ts` | ❌ Wave 0 |
| NOTIF-02 | SOS uses high-priority FCM/APNs | unit | `npm test -- notification.service.test.ts` | ❌ Wave 0 |
| COMM-02 | STT returns Vietnamese text | integration | `npm test -- stt.test.ts` (mocked) | ❌ Wave 0 |
| COMM-03 | TTS returns audio buffer | integration | `npm test -- tts.test.ts` (mocked) | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** `npm test -- --passWithNoTests --watch`
- **Per wave merge:** `npm test -- --coverage --coverageThreshold='{"global":{"branches":80}}'`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps

- [x] `jest.config.ts` — configure ts-jest preset
- [ ] `tests/auth.service.test.ts` — covers ACC-01
- [ ] `tests/token.service.test.ts` — covers ACC-02, ACC-03
- [ ] `tests/socket.test.ts` — covers NOTIF-01 basic connectivity
- [ ] `tests/notification.service.test.ts` — covers NOTIF-02 SOS priority
- [ ] `tests/stt.test.ts` — covers COMM-02 strategy pattern
- [ ] `tests/tts.test.ts` — covers COMM-03 strategy pattern
- [ ] `tests/setup.ts` — Jest setup with test database
- [ ] `tests/fixtures/` — shared test fixtures

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | JWT with HS256 fallback to RS256, bcrypt 12+, OAuth2 state validation |
| V3 Session Management | Yes | Refresh token rotation, Redis blacklist, 15min access TTL |
| V4 Access Control | Yes | Middleware-based route guards, userId-scoped queries |
| V5 Input Validation | Yes | Zod schemas for all API inputs |
| V6 Cryptography | Yes | Bcrypt for passwords, JWT for tokens, TLS 1.3 for transport |

### Known Threat Patterns for Stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| JWT algorithm confusion | Spoofing | Validate `alg` header matches expected; use RS256 for production |
| Refresh token theft | Information disclosure | Rotate tokens, store in secure mobile storage, revoke on logout |
| Brute force login | DoS | Rate limiting on auth endpoints (5 attempts/15min per IP) |
| XSS stealing tokens | Information disclosure | HttpOnly cookies for web, secure storage for mobile; short access TTL |
| SQL injection | Tampering | Prisma parameterized queries (automatic) |
| Replay attacks | Repudiation | JWT `jti` blacklist on logout, short access token TTL |
| TURN server abuse | Elevation of privilege | TURN auth with time-limited credentials, rate limit allocations |

## Code Examples

### Express App with Socket.io and Health Checks

\`\`\`typescript
// src/server.ts
import express from 'express';
import { createServer } from 'http';
import { setupSocket } from './config/socket.js';
import authRoutes from './routes/auth.routes.js';
import sttRoutes from './routes/stt.routes.js';
import { PrismaClient } from '@prisma/client';

const app = express();
const server = createServer(app);
const io = setupSocket(server, notificationService);

// Middleware
app.use(express.json({ limit: '10mb' })); // audio uploads
app.use(cors({ origin: process.env.CLIENT_ORIGIN, credentials: true }));
app.use(helmet());

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/stt', sttRoutes);

// Health check
app.get('/health', async (req, res) => {
  const db = prisma.$queryRaw`SELECT 1`;
  const redis = await redisClient.ping();
  res.json({ db: 'ok', redis, timestamp: new Date().toISOString() });
});

const port = process.env.PORT || 3000;
server.listen(port, () => {
  console.log(`Server listening on :${port}`);
});
\`\`\`

### Prisma Schema for Users and Sessions

\`\`\`prisma
// prisma/schema.prisma
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  emailVerified DateTime?
  passwordHash  String?   // null for OAuth-only users
  googleId      String?   @unique
  name          String?
  avatarUrl     String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  
  refreshTokens RefreshToken[]
  conversations Conversation[]
}

model RefreshToken {
  id        String   @id @default(cuid())
  userId    String
  jti       String   @unique  // JWT ID for revocation
  expiresAt DateTime
  user      User     @relation(fields: [userId], references: [id])
  
  @@index([userId])
}

model Conversation {
  id          String   @id @default(cuid())
  userId      String
  messages    Message[]
  createdAt   DateTime @default(now())
  
  @@index([userId])
}

model Message {
  id          String   @id @default(cuid())
  conversationId String
  role        String   // 'user' | 'assistant'
  content     String   // text content
  audioUrl    String?  // optional audio recording
  createdAt   DateTime @default(now())
  
  @@index([conversationId])
}
\`\`\`

### Docker Compose for Full Stack

\`\`\`yaml
# docker-compose.yaml
version: '3.8'

services:
  postgres:
    image: postgres:17-alpine
    restart: unless-stopped
    environment:
      POSTGRES_USER: ${POSTGRES_USER:-vsl}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: ${POSTGRES_DB:-vsl_bridge}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER:-vsl}"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - vsl-network

  redis:
    image: redis:7-alpine
    restart: unless-stopped
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5
    networks:
      - vsl-network

  livekit:
    image: livekit/livekit-server:latest
    restart: unless-stopped
    depends_on:
      - redis
    environment:
      LIVEKIT_KEYS: ${LIVEKIT_API_KEY}:${LIVEKIT_API_SECRET}
      LIVEKIT_REDIS: redis://redis:6379
      LIVEKIT_WS_URL: ${LIVEKIT_WS_URL:-ws://localhost:7880}
      LIVEKIT_RTC_URL: ${LIVEKIT_RTC_URL:-http://localhost:7880}
      LIVEKIT_TURN_ENABLED: "true"
      LIVEKIT_TURN_TLS_PORT: "5349"
    ports:
      - "7880:7880"
      - "7881:7881"
      - "5349:5349"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:7880/.well-known/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - vsl-network

  whisper-server:
    image: ghcr.io/ggerganov/whisper.cpp:latest
    restart: unless-stopped
    command: >
      /whisper-server
      --model /models/ggml-large-v3.bin
      --host 0.0.0.0
      --port 8081
      --threads 4
      --language auto
    volumes:
      - ./models:/models
    ports:
      - "8081:8081"
    networks:
      - vsl-network
    deploy:
      resources:
        limits:
          memory: 2G

  coqui-tts:
    image: ghcr.io/coqui-tts/tts-cpu:latest
    restart: unless-stopped
    command: >
      python3 TTS/server/server.py
      --model_name tts_models/multilingual/multi-dataset/xtts_v2
      --port 5002
    ports:
      - "5002:5002"
    networks:
      - vsl-network
    deploy:
      resources:
        limits:
          memory: 3G

  api:
    build:
      context: .
      dockerfile: Dockerfile
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
      livekit:
        condition: service_healthy
      whisper-server:
        condition: service_healthy
    environment:
      NODE_ENV: production
      DATABASE_URL: postgresql://${POSTGRES_USER:-vsl}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB:-vsl_bridge}
      REDIS_URL: redis://redis:6379
      JWT_SECRET: ${JWT_SECRET}
      GROQ_API_KEY: ${GROQ_API_KEY}
      ELEVENLABS_API_KEY: ${ELEVENLABS_API_KEY}
      STT_PROVIDER: ${STT_PROVIDER:-groq}
      STT_FALLBACK_URL: http://whisper-server:8081/transcribe
      TTS_PROVIDER: ${TTS_PROVIDER:-elevenlabs}
      TTS_FALLBACK_URL: http://coqui-tts:5002/api/tts
      FIREBASE_SERVICE_ACCOUNT: /run/secrets/firebase
      APNS_CERT: /run/secrets/apns
      LIVEKIT_URL: ${LIVEKIT_URL}
      LIVEKIT_API_KEY: ${LIVEKIT_API_KEY}
      LIVEKIT_API_SECRET: ${LIVEKIT_API_SECRET}
    ports:
      - "3000:3000"
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/health"]
      interval: 30s
      timeout: 10s
      retries: 3
    networks:
      - vsl-network

volumes:
  postgres_data:
  redis_data:

networks:
  vsl-network:
    driver: bridge
\`\`\`

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Long-lived JWT (days) | Short-lived access (15min) + refresh rotation | 2023-2024 (industry standard) | Reduced blast radius of token theft |
| Self-signed JWT with HS256 | RS256 asymmetric for multi-service | 2024 (OWASP recommendation) | Signing key compromise limited to auth service |
| Raw WebSockets | Socket.io with fallbacks | 2020+ | Better mobile support, automatic reconnection |
| Manual DB backups | Point-in-time recovery (PITR) | 2022+ | Faster recovery, granular restores |
| Manual Docker scripts | Docker Compose v2 | 2023+ | Declarative, multi-service orchestration |
| Device tokens push | Topic-based FCM + APNs | 2023+ | Better delivery for SOS critical alerts |
| Single provider STT/TTS | Hybrid strategy pattern | 2024 (emerging) | Cost control + reliability fallback |

**Deprecated/outdated:**
- **Firebase Auth + Firestore:** Vendor lock-in, costs scale; use self-hosted PostgreSQL + JWT instead
- **Twilio/Agora video:** Expensive per-minute; use LiveKit self-hosted (~$5 VPS)
- **getUserMedia raw WebRTC:** Too low-level; use LiveKit SDK with SFU

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Groq Whisper costs ~$0.14/min for large-v3 [ASSUMED] | Standard Stack / Groq pricing | Budget planning may be off; actual cost could differ by 2-3x |
| A2 | Whisper.cpp multilingual models include Vietnamese (`vi` language code) | Standard Stack / Whisper.cpp | Vietnamese support may require fine-tuned model; fallback could fail |
| A3 | ElevenLabs v3 supports Vietnamese [VERIFIED via Context7 "over 70 languages"] | Standard Stack / ElevenLabs | Voice quality may be suboptimal; need fallback testing |
| A4 | Coqui XTTS-v2 supports Vietnamese (language code `vi`) | Standard Stack / Coqui TTS | If not supported, fallback fails; need to verify model download |
| A5 | Google Cloud TTS offers Vietnamese voices at ~$4-10/1M chars [ASSUMED] | Alternatives Considered | Actual pricing could be higher; may need to research alternatives |
| A6 | $6/month DigitalOcean droplet (1GB RAM) sufficient for PostgreSQL + Redis + LiveKit + API | Environment Availability / VPS | Memory pressure under load; may need $12 plan |
| A7 | Hetzner pricing ~€5-7/month for comparable VPS [ASSUMED] | VPS Provider Comparison | Hetzner regions may not include Singapore; EU latency to Vietnam may be high |
| A8 | VieNeu-TTS is not production-ready or hard to integrate [ASSUMED based on lack of info] | Open Questions | Could be viable option; recommendation to skip may miss opportunity |
| A9 | FCM VAPID keys generated via Firebase console work for web push | Socket.io + FCM/APNs | Web push requires service worker; browser compatibility varies |
| A10 | APNs critical alerts (`priority: 10`) work without special entitlements [ASSUMED] | APNs Configuration | SOS notifications may require Apple "Critical Alerts" entitlement (app review) |

**If this table is empty:** All claims in this research were verified or cited — no user confirmation needed.

## Sources

### Primary (HIGH confidence)
- `/ggml-org/whisper.cpp` - Whisper.cpp models, quantization, language detection, server configuration
- `/websites/console_groq` - Groq API reference, Whisper large-v3 specs, performance metrics
- `/auth0/node-jsonwebtoken` - JWT API, security best practices, algorithm selection
- `/websites/socket_io_v4` - Socket.io server setup, limitations (battery on mobile)
- `/websites/livekit_io` - LiveKit self-hosting, TURN configuration, Docker deployment
- `/docker/compose` - Docker Compose file format, health checks, volumes, networks
- `/prisma/web` - Prisma ORM configuration, PostgreSQL connection patterns
- `/websites/coqui_ai_en` - Coqui TTS XTTS-v2, multilingual support, Docker deployment
- `/coqui-ai/tts` - Coqui TTS API, streaming inference, language codes
- `/parse-community/node-apn` - APNs notification payload, priority levels, critical alerts
- `/firebase/firebase-js-sdk` - FCM web push, VAPID keys, service worker registration

### Secondary (MEDIUM confidence)
- `/websites/elevenlabs_io` - ElevenLabs pricing (1 char = 1 credit), Vietnamese language support in v3 [Context7]
- `/juliansteenbakker/flutter_secure_storage` - Flutter secure storage options, Keychain/Keystore details
- `/hey-api/openapi-ts` - OpenAPI TypeScript generation, Next.js client plugin
- `WebFetch: DigitalOcean pricing` - Droplet specs and monthly costs (specific numbers)
- `WebFetch: Hetzner cloud` - VPS plan categories (cost-optimized $5-10, regular $10-15)

### Tertiary (LOW confidence)
- Groq Whisper pricing estimate ($0.14/min) [ASSUMED - exact price not found]
- Google Cloud TTS Vietnamese voice availability and pricing [ASSUMED based on typical GCP coverage]
- VieNeu-TTS existence and quality [ASSUMED not production-ready due to lack of documentation]

## Metadata

**Confidence breakdown:**
- Standard stack: **HIGH** - Core library versions and purposes verified via Context7/npm
- Architecture: **HIGH** - Patterns validated against official docs (Socket.io, LiveKit, Prisma)
- Pitfalls: **MEDIUM** - Based on industry experience; some specific to stack need testing
- Pricing: **MEDIUM** - Groq/ElevenLabs pricing inferred; ElevenLabs char-based model confirmed
- VPS selection: **MEDIUM** - DigitalOcean pricing verified; Hetzner details sparse

**Research date:** 2026-05-05
**Valid until:** 2026-06-04 (30 days for stable stack)

---

## Phase Requirements Support

| ID | Description | Research Support |
|----|-------------|------------------|
| ACC-01 | User registration/login | JWT implementation, bcrypt, Google OAuth via passport, Redis token blacklist |
| ACC-02 | Profile management | Prisma schema design, user service patterns |
| ACC-03 | Session management | Refresh token rotation, multi-device concurrent sessions |
| NOTIF-01 | Push notifications | Socket.io + FCM/APNs hybrid, service worker setup, critical alerts |
| NOTIF-02 | SOS high-priority | APNs priority=10, FCM high priority, haptic feedback patterns |
| COMM-02 | Speech-to-text | Groq Whisper cloud + Whisper.cpp fallback strategy pattern |
| COMM-03 | Text-to-speech | ElevenLabs cloud + Coqui TTS fallback strategy pattern |
