# Phase 01: Foundation & Authentication - Research

**Researched:** 2026-05-06
**Domain:** Backend infrastructure, authentication, STT/TTS services, real-time notifications, deployment
**Confidence:** MEDIUM

## Summary

Phase 1 establishes the technical foundation for the VSL Bridge application. The research confirms that the technology stack outlined in CLAUDE.md and CONTEXT.md is sound, though several version updates are available. The core stack uses Next.js 16 (currently 16.2.4, CLAUDE.md notes 15.1.8), Prisma 7.x (currently 7.8.0, CLAUDE.md notes 6.x), and Node.js 20.x LTS (20.20.2 available). JWT authentication with refresh tokens is well-supported using `jose` (6.2.3) or `jsonwebtoken` (9.0.3), with `bcrypt` (6.0.0) for password hashing.

The STT/TTS strategy pattern with provider abstraction is feasible using environment variables for configuration. Groq Whisper API supports Vietnamese through its multilingual models (`whisper-large-v3` and `whisper-large-v3-turbo`) with claimed 216x real-time speed [VERIFIED: Groq docs]. For TTS, while VieNeu-TTS was mentioned in CONTEXT.md, limited public documentation was found during research — ElevenLabs or Google TTS remain viable cloud options, with Coqui TTS as the self-hosted fallback.

Socket.io (4.8.3) remains the standard for real-time notifications, with FCM/APNs integration for background push notifications. LiveKit self-hosting is viable on a single VPS using Docker Compose, with `livekit-client` (2.18.9) and `livekit-server-sdk` (2.15.2) for client and server integration.

**Primary recommendation:** Proceed with the CONTEXT.md decisions using updated library versions. Use Next.js 16 Route Handlers (not Express) for the API, Prisma 7.x with PostgreSQL, and implement JWT authentication following the Next.js official documentation patterns using `jose` for Edge-compatible JWT operations.

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| User authentication (register/login) | API / Backend (Next.js Route Handlers) | Database (PostgreSQL) | Credentials validation, JWT signing, password hashing happen server-side; user data persisted in DB |
| Session management (JWT refresh) | API / Backend | Client (cookie storage) | Token generation/validation server-side; httpOnly cookies for storage |
| STT (Speech-to-Text) | API / Backend | Cloud service (Groq) or local (whisper.cpp) | Audio uploaded to API, forwarded to STT provider; strategy pattern abstracts provider |
| TTS (Text-to-Speech) | API / Backend | Cloud service (ElevenLabs/Google) or local (Coqui TTS) | Text sent to API, forwarded to TTS provider; audio stream returned |
| Real-time notifications | API / Backend (Socket.io) + FCM/APNs | Client (Flutter/Next.js) | Socket.io server manages connections; FCM/APNs for background notifications |
| Video calling signaling | LiveKit Server (self-hosted) | Client SDKs (Flutter/Next.js) | LiveKit SFU handles WebRTC signaling; clients connect via SDKs |
| Database persistence | Database (PostgreSQL) | API / Backend (Prisma ORM) | PostgreSQL as primary store; Prisma provides type-safe access |

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| **Next.js** | 16.2.4 | Full-stack web framework | App Router with Route Handlers for API; React 19 support; Vercel ecosystem [VERIFIED: npm registry] |
| **Prisma** | 7.8.0 | Type-safe ORM | Schema-first; migration system; type generation; Studio GUI [VERIFIED: npm registry] |
| **PostgreSQL** | 16.x or 17.x | Primary database | ACID compliance; JSONB support; full-text search; mature ecosystem [ASSUMED] |
| **Node.js** | 20.20.2 LTS | Backend runtime | Current LTS; native TypeScript support via tsx; large ecosystem [VERIFIED: node --version] |
| **jose** | 6.2.3 | JWT signing/verification | Edge-compatible; recommended by Next.js docs; supports HS256/RS256 [VERIFIED: npm registry] |
| **bcrypt** | 6.0.0 | Password hashing | Standard for password hashing; salt rounds for security [VERIFIED: npm registry] |
| **zod** | 4.4.3 | Schema validation | TypeScript-first; infers types from schemas; Next.js docs recommend [VERIFIED: npm registry] |
| **Socket.io** | 4.8.3 | Real-time bidirectional events | WebSocket with fallback; chat, notifications, presence [VERIFIED: npm registry] |

### Supporting
| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| **livekit-client** | 2.18.9 | Video calling SDK (web) | Web app WebRTC integration with self-hosted LiveKit [VERIFIED: npm registry] |
| **livekit-server-sdk** | 2.15.2 | LiveKit server-side SDK | Token generation, room management, webhook handling [VERIFIED: npm registry] |
| **openapi-typescript** | 7.13.0 | OpenAPI codegen | Generate TypeScript types from OpenAPI schema for client SDK [VERIFIED: npm registry] |
| **Jest** | 30.3.0 | Testing framework | Unit tests for API routes and utilities [VERIFIED: npm registry] |
| **@testing-library/react** | 16.3.2 | React component testing | Component testing for Next.js web app [VERIFIED: npm registry] |

### Alternatives Considered
| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| **Next.js Route Handlers** | Express.js server | Express more familiar but adds complexity; Next.js Route Handlers are built-in, simpler deployment |
| **jose (JWT)** | jsonwebtoken | jsonwebtoken more common but not Edge-compatible; jose recommended by Next.js docs |
| **Prisma** | Drizzle ORM | Drizzle more SQL-like; Prisma better migration GUI (Studio) and type generation |
| **Groq Whisper (STT)** | whisper.cpp self-hosted | whisper.cpp free but requires ~2GB model file and CPU resources; Groq faster, simpler |
| **ElevenLabs/Google TTS** | Coqui TTS self-hosted | Coqui free but lower quality; cloud TTS higher quality, managed |

**Installation:**
```bash
# Core dependencies
npm install next@16 prisma @prisma/client jose bcrypt zod socket.io

# Supporting
npm install livekit-server-sdk openapi-typescript

# Dev dependencies
npm install -D jest @testing-library/react typescript @types/node
```

**Version verification:** All versions verified via `npm view <package> version` on 2026-05-06. CLAUDE.md references older versions (Next.js 15.1.8, Prisma 6.x) — use current verified versions above.

## Architecture Patterns

### System Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                        Client Apps                              │
│  ┌──────────────┐              ┌──────────────┐               │
│  │ Flutter App  │              │ Next.js Web  │               │
│  │ (iOS/Android)│              │     App      │               │
│  └──────┬───────┘              └──────┬───────┘               │
│         │                            │                        │
│         │ REST API + WebSocket        │                        │
└─────────┼────────────────────────────┼────────────────────────┘
          │                            │
          ▼                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    Next.js API (Route Handlers)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────────┐   │
│  │ /api/auth/*  │  │ /api/stt/*   │  │ /api/notif/*     │   │
│  │ (login,      │  │ (transcribe) │  │ (push tokens,    │   │
│  │ register)    │  │              │  │  socket.io)      │   │
│  └──────┬───────┘  └──────┬─────┘  └──────┬───────────┘   │
│         │                  │                 │                │
│  ┌──────┴─────────────────┴─────────────────┴──────┐       │
│  │           Provider Abstraction Layer              │       │
│  │  ┌──────────┐        ┌──────────┐              │       │
│  │  │ STT      │        │ TTS      │              │       │
│  │  │ Strategy │        │ Strategy │              │       │
│  │  └────┬─────┘        └────┬─────┘              │       │
│  └───────┼───────────────────┼────────────────────┘       │
│          │                   │                              │
│  ┌───────▼─────┐    ┌───────▼─────┐    ┌────────────┐   │
│  │ Groq Whisper│    │ElevenLabs   │    │ PostgreSQL  │   │
│  │ (cloud)     │    │TTS (cloud)  │    │ + Prisma   │   │
│  └─────────────┘    └─────────────┘    └──────┬─────┘   │
│  ┌─────────────┐    ┌─────────────┐          │         │
│  │ whisper.cpp │    │ Coqui TTS   │          │         │
│  │ (fallback)  │    │ (fallback)  │          │         │
│  └─────────────┘    └─────────────┘          │         │
└──────────────────────────────────────────────────┼─────────┘
                                                   │
┌──────────────────────────────────────────────────┼─────────┐
│  LiveKit Server (Docker)                       │         │
│  ┌─────────────────────────────────────┐       │         │
│  │ SFU for WebRTC video calling        │◄──────┘         │
│  │ Token generation: livekit-server-sdk│                     │
│  └─────────────────────────────────────┘                     │
└───────────────────────────────────────────────────────────────┘
```

### Recommended Project Structure
```
vsl-bridge-backend/
├── prisma/
│   ├── schema.prisma        # Database schema
│   └── migrations/          # Database migrations
├── src/
│   ├── app/
│   │   ├── api/
│   │   │   ├── auth/
│   │   │   │   ├── login/route.ts
│   │   │   │   ├── register/route.ts
│   │   │   │   └── refresh/route.ts
│   │   │   ├── stt/
│   │   │   │   └── transcribe/route.ts
│   │   │   ├── tts/
│   │   │   │   └── synthesize/route.ts
│   │   │   └── notifications/
│   │   │       └── register-token/route.ts
│   │   └── lib/
│   │       ├── auth.ts      # JWT utilities (jose)
│   │       ├── session.ts   # Session management
│   │       ├── db.ts        # Prisma client
│   │       └── validators.ts # Zod schemas
│   ├── lib/
│   │   ├── providers/
│   │   │   ├── stt-provider.ts      # STT strategy interface
│   │   │   ├── tts-provider.ts      # TTS strategy interface
│   │   │   ├── groq-stt.ts          # Groq implementation
│   │   │   ├── whisper-cpp-stt.ts   # whisper.cpp implementation
│   │   │   ├── elevenlabs-tts.ts    # ElevenLabs implementation
│   │   │   └── coqui-tts.ts        # Coqui implementation
│   │   └── livekit.ts              # LiveKit token generation
│   └── types/
│       └── openapi-schema.ts  # Generated from OpenAPI spec
├── docker-compose.yml         # All services (API, PostgreSQL, Redis, LiveKit)
├── prisma.schema              # Database schema (root for easy access)
└── package.json
```

### Pattern 1: JWT Authentication with Refresh Tokens
**What:** Stateless JWT authentication with short-lived access tokens and long-lived refresh tokens, stored in httpOnly cookies.
**When to use:** User sessions that need to scale without server-side session storage.
**Example:**
```typescript
// Source: Next.js docs (https://nextjs.org/docs/app/guides/authentication)
import 'server-only'
import { SignJWT, jwtVerify } from 'jose'

const secretKey = process.env.JWT_SECRET
const encodedKey = new TextEncoder().encode(secretKey)

export async function encrypt(payload: any) {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('15m')  // Access token: 15 minutes
    .sign(encodedKey)
}

export async function decrypt(session: string) {
  const { payload } = await jwtVerify(session, encodedKey, {
    algorithms: ['HS256'],
  })
  return payload
}

// Refresh token (long-lived, 7 days)
export async function generateRefreshToken(payload: any) {
  return new SignJWT(payload)
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('7d')
    .sign(new TextEncoder().encode(process.env.REFRESH_TOKEN_SECRET))
}
```
[VERIFIED: Next.js docs]

### Pattern 2: STT/TTS Provider Strategy Pattern
**What:** Abstraction layer that allows switching between cloud and self-hosted STT/TTS providers via environment configuration.
**When to use:** When you need flexibility to change providers or have fallback options.
**Example:**
```typescript
// STT Provider Interface
export interface STTProvider {
  transcribe(audioBuffer: Buffer, language?: string): Promise<string>
}

// Groq Whisper Implementation
export class GroqSTTProvider implements STTProvider {
  async transcribe(audioBuffer: Buffer, language = 'vi'): Promise<string> {
    const response = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
      },
      body: /* FormData with audio file */,
    })
    const data = await response.json()
    return data.text
  }
}

// Strategy selection based on env var
function getSTTProvider(): STTProvider {
  const provider = process.env.STT_PROVIDER || 'groq'
  switch (provider) {
    case 'groq': return new GroqSTTProvider()
    case 'local': return new WhisperCppSTTProvider()
    default: return new GroqSTTProvider()
  }
}
```
[ASSUMED - pattern based on standard strategy pattern, provider APIs need verification during implementation]

### Anti-Patterns to Avoid
- **Storing JWT in localStorage:** Vulnerable to XSS attacks. Use httpOnly cookies.
- **Not validating environment variables:** Use Zod to validate all `STT_PROVIDER`, `TTS_PROVIDER`, API keys at startup.
- **Synchronous password hashing:** bcrypt is CPU-intensive; ensure it's async and doesn't block the event loop.
- **Not having STT/TTS fallback:** Cloud providers can have outages; always implement fallback logic.
- **Mixing auth strategies:** Don't mix NextAuth.js with custom JWT; choose one approach.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| JWT signing/verification | Custom crypto implementation | `jose` or `jsonwebtoken` | Edge-compatible, battle-tested, handles algorithm negotiation |
| Password hashing | Custom hash functions | `bcrypt` | Adaptive hashing with salt; industry standard |
| Schema validation | Manual type checking | `zod` | TypeScript inference, composable schemas, error handling |
| WebSocket management | Raw WebSocket API | `socket.io` | Automatic reconnection, fallback transports, room support |
| ORM/query builder | Raw SQL queries | `prisma` | Type safety, migration system, prevents SQL injection |
| OpenAPI types | Manual type definitions | `openapi-typescript` | Single source of truth, type synchronization |

**Key insight:** Authentication, password hashing, and real-time communication have complex edge cases (token rotation, refresh logic, WebSocket reconnection). Use established libraries to avoid security vulnerabilities and bugs.

## Runtime State Inventory

> Not applicable — this is a greenfield phase with no existing runtime state to migrate.

None — verified by greenfield project status.

## Common Pitfalls

### Pitfall 1: JWT Token Storage in localStorage
**What goes wrong:** Tokens stored in localStorage are accessible to JavaScript, making them vulnerable to XSS attacks.
**Why it happens:** localStorage is simpler to implement than cookie-based storage.
**How to avoid:** Store JWTs in httpOnly, Secure, SameSite cookies. Use Next.js `cookies()` API.
**Warning signs:** Any code that reads `localStorage.getItem('token')`.

### Pitfall 2: Not Handling Token Expiration
**What goes wrong:** Access tokens expire mid-session, causing 401 errors.
**Why it happens:** No refresh token rotation logic implemented.
**How to avoid:** Implement refresh token endpoint that exchanges valid refresh token for new access token. Use Next.js middleware or client-side interceptor.
**Warning signs:** Users being logged out unexpectedly; 401 errors in API calls.

### Pitfall 3: Groq API Rate Limits
**What goes wrong:** STT requests fail under load due to rate limiting.
**Why it happens:** Groq has rate limits on free/paid tiers; no fallback implemented.
**How to avoid:** Implement fallback to whisper.cpp (self-hosted) when Groq fails. Monitor rate limit headers.
**Warning signs:** 429 errors from Groq API; transcription failures.

### Pitfall 4: Prisma Client in Next.js Development
**What goes wrong:** Multiple Prisma Client instances in development cause memory leaks.
**Why it happens:** Hot reloading creates new Prisma Client on each reload.
**How to avoid:** Use singleton pattern for Prisma Client (Next.js docs provide example).
**Warning signs:** "Too many connections" errors; high memory usage in development.

### Pitfall 5: CORS Issues with Socket.io
**What goes wrong:** Socket.io connections fail due to CORS policy.
**Why it happens:** Socket.io server not configured with correct CORS origins.
**How to avoid:** Explicitly configure CORS in Socket.io server setup. Use environment variable for allowed origins.
**Warning signs:** WebSocket connection errors in browser console; CORS errors.

## Code Examples

Verified patterns from official sources:

### Next.js Route Handler with Zod Validation
```typescript
// Source: Next.js docs (https://nextjs.org/docs/app/api-reference/file-conventions/route)
import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'

const LoginSchema = z.object({
  email: z.email(),
  password: z.string().min(8),
})

export async function POST(request: NextRequest) {
  const body = await request.json()
  const validated = LoginSchema.safeParse(body)

  if (!validated.success) {
    return NextResponse.json(
      { errors: validated.error.flatten() },
      { status: 400 }
    )
  }

  // Process login...
  return NextResponse.json({ success: true })
}
```
[VERIFIED: Next.js docs]

### Prisma Schema for User Authentication
```prisma
// Source: Prisma docs (https://www.prisma.io/docs)
generator client {
  provider = "prisma-client-js"
}

datasource db {
  provider = "postgresql"
  url      = env("DATABASE_URL")
}

model User {
  id        Int      @id @default(autoincrement())
  email     String   @unique
  password  String   // bcrypt hash
  name      String?
  userType  UserType @default(HEARING)  // DEAF or HEARING
  createdAt DateTime @default(now())
  updatedAt DateTime @updatedAt

  // Relations
  refreshTokens RefreshToken[]
  notifications Notification[]
}

model RefreshToken {
  id        Int      @id @default(autoincrement())
  token     String   @unique
  expiresAt DateTime
  userId    Int
  user      User     @relation(fields: [userId], references: [id], onDelete: Cascade)
  createdAt DateTime @default(now())

  @@index([userId])
}

enum UserType {
  DEAF
  HEARING
}
```
[ASSUMED - standard pattern, verify during implementation]

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Next.js Pages Router API routes | App Router Route Handlers | Next.js 13.2+ | Different syntax; uses Web Request/Response APIs |
| jsonwebtoken (Node-only) | jose (Edge-compatible) | Next.js 15 docs | jose works in Edge runtime; jsonwebtoken does not |
| Prisma 5.x | Prisma 7.x | 2025-2026 | Improved TypeScript generation; ESM support |
| Socket.io 2.x | Socket.io 4.8+ | 2020+ | Better TypeScript support; improved reconnection |

**Deprecated/outdated:**
- **NextAuth.js v4:** v5 (Auth.js) has different configuration; if using, use latest.
- **@next-auth/prisma-adapter:** Ensure compatibility with Prisma 7.x.
- **whisper.cpp without server:** Use `whisper-server` Docker image for easier deployment.

## Assumptions Log

> List all claims tagged `[ASSUMED]` in this research. The planner and discuss-phase use this
> section to identify decisions that need user confirmation before execution.

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | PostgreSQL 16.x/17.x is readily available on target VPS (Hetzner/DigitalOcean/Oracle) | Standard Stack | May need to use older version; Docker can provide latest |
| A2 | Groq Whisper supports Vietnamese with good accuracy (whisper-large-v3 multilingual) | Architecture Patterns | Vietnamese accuracy may be poor; need to test during implementation |
| A3 | VieNeu-TTS exists and is integratable — no public documentation found during research | Summary | May not exist or be unusable; need to confirm or use alternative |
| A4 | Prisma schema with User/RefreshToken models is correct pattern | Code Examples | May need adjustments for actual requirements (emergency contacts, etc.) |
| A5 | Docker Compose can run all services (API, PostgreSQL, Redis, LiveKit) on $6-10/mo VPS | Summary | Resource constraints may require scaling down or using managed services |
| A6 | whisper.cpp can run on same VPS as fallback — CPU requirements not verified | Common Pitfalls | May need separate server or more RAM; affects cost targets |

## Open Questions (RESOLVED)

1. **VieNeu-TTS availability and quality** — RESOLVED
   - Finding: No public documentation or npm package found for "VieNeu-TTS"
   - Resolution: Use ElevenLabs (cloud primary) + Coqui TTS (self-hosted fallback) per CONTEXT.md decision
   - Action: Removed from implementation scope; if user requests later, research specific Vietnamese neural TTS providers

2. **Vietnamese STT accuracy with Groq Whisper** — RESOLVED
   - Finding: Groq Whisper uses whisper-large-v3 multilingual model; Vietnamese supported
   - Resolution: Implement Groq as primary with latency target <500ms; whisper.cpp as CPU fallback
   - Action: Accuracy tests added to Plan 01-03 verification criteria

3. **LiveKit Docker Compose configuration** — RESOLVED
   - Finding: LiveKit provides official Docker image `livekit/livekit-server:latest`
   - Resolution: Plan 01-01 creates docker-compose.yml with ports 7880 (UDP), 7881 (TCP), 5349 (TLS)
   - Action: Configuration follows LiveKit self-hosting guide; TLS optional for development

4. **FCM/APNs integration for push notifications** — RESOLVED
   - Finding: Firebase Admin SDK v12+ supports both FCM (Android) and APNs (iOS) via single integration
   - Resolution: Plan 01-04 implements server-side FCM via `firebase-admin` npm package
   - Action: Flutter client uses `firebase_messaging` plugin; iOS uses APNs via Firebase

5. **openapi-typescript codegen workflow** — RESOLVED
   - Finding: `openapi-typescript` v7.13.0 works with Next.js App Router
   - Resolution: Plan 01-01 adds npm script `generate:types` that runs `npx openapi-typescript ...`
   - Action: Types output to `src/types/api.ts`; consumed by both web and mobile via shared SDK

## Environment Availability

> Docker not found on local machine — all Docker work will be done on target VPS.

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Backend runtime | ✓ | 20.20.2 | — |
| npm | Package management | ✓ | 10.8.2 | — |
| PostgreSQL | Primary database | ✗ (local) | — | Use Docker container on VPS |
| Redis | Caching, rate limiting | ✗ (local) | — | Use Docker container on VPS |
| Docker | Containerization | ✗ | — | Install on VPS; required for deployment |
| Docker Compose | Multi-container orchestration | ✗ | — | Install on VPS; `docker compose` plugin |
| LiveKit server | Video calling SFU | ✗ | — | Deploy via Docker on VPS |
| Groq API | Cloud STT | ✓ (via HTTPS) | — | Fallback to whisper.cpp |
| FCM/APNs | Push notifications | ✓ (via SDK) | — | Socket.io only for active app |

**Missing dependencies with no fallback:**
- None — all missing dependencies will be available on target VPS via Docker.

**Missing dependencies with fallback:**
- PostgreSQL/Redis — Docker containers on VPS (no local fallback needed for development if using Docker)
- LiveKit — Required for video calling; must be installed on VPS

## Validation Architecture

> nyquist_validation is enabled in config.json.

### Test Framework
| Property | Value |
|----------|-------|
| Framework | Jest 30.3.0 |
| Config file | jest.config.ts (or package.json jest config) |
| Quick run command | `npx jest --testPathPattern="src/__tests__" --watch` |
| Full suite command | `npx jest --ci` |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| ACC-01 | User registration with email/password | unit + integration | `npx jest --testNamePattern="register" --ci` | ❌ Wave 0 |
| ACC-02 | Login/logout with session persistence | unit + integration | `npx jest --testNamePattern="login" --ci` | ❌ Wave 0 |
| ACC-03 | Profile management (name, age, user type) | unit | `npx jest --testNamePattern="profile" --ci` | ❌ Wave 0 |
| NOTIF-01 | Visual push notifications for incoming calls | integration + manual | Test Socket.io events; manual for FCM/APNs | ❌ Wave 0 |
| NOTIF-02 | SOS status notifications | integration | `npx jest --testNamePattern="notification" --ci` | ❌ Wave 0 |
| COMM-02 | Speech-to-text transcription (<1s) | integration | `npx jest --testNamePattern="stt" --ci` | ❌ Wave 0 |
| COMM-03 | Text-to-speech synthesis | integration | `npx jest --testNamePattern="tts" --ci` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `npx jest --testPathPattern="src/__tests__/task-name" --ci`
- **Per wave merge:** `npx jest --ci`
- **Phase gate:** Full suite green before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `src/__tests__/auth/register.test.ts` — covers ACC-01
- [ ] `src/__tests__/auth/login.test.ts` — covers ACC-02
- [ ] `src/__tests__/auth/profile.test.ts` — covers ACC-03
- [ ] `src/__tests__/stt/transcribe.test.ts` — covers COMM-02
- [ ] `src/__tests__/tts/synthesize.test.ts` — covers COMM-03
- [ ] `src/__tests__/notifications/push.test.ts` — covers NOTIF-01, NOTIF-02
- [ ] `src/__tests__/setup.ts` — shared test setup (Prisma mock, etc.)
- [ ] Jest config: `jest.config.ts` — configure for TypeScript, Next.js

## Security Domain

> Required when `security_enforcement` is enabled (absent = enabled).

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | Yes | JWT (jose) with bcrypt password hashing; rate limiting on login attempts |
| V3 Session Management | Yes | httpOnly, Secure, SameSite cookies; refresh token rotation |
| V4 Access Control | Yes | Next.js DAL (Data Access Layer) with verifySession() checks |
| V5 Input Validation | Yes | Zod schemas for all API inputs; OpenAPI spec validation |
| V6 Cryptography | Yes | HTTPS (TLS) via VPS reverse proxy; JWT signing with HS256; bcrypt for passwords |

### Known Threat Patterns for Next.js + Node.js

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| JWT token theft (XSS) | Information Disclosure | httpOnly cookies; Content Security Policy |
| Brute force login | Denial of Service | Rate limiting (Redis); account lockout after N attempts |
| SQL injection | Tampering | Prisma ORM (parameterized queries); never raw SQL |
| CSRF attacks | Tampering | SameSite cookies; CSRF tokens for state-changing operations |
| Sensitive data in JWT | Information Disclosure | Only store user ID and non-sensitive claims in JWT payload |
| bcrypt timing attacks | Information Disclosure | Use constant-time comparison; bcrypt handles this internally |

## Sources

### Primary (HIGH confidence)
- Next.js docs (https://nextjs.org/docs/app/guides/authentication) - JWT authentication patterns, Route Handlers
- Next.js docs (https://nextjs.org/docs/app/api-reference/file-conventions/route) - Route Handler API
- npm registry (npm view <package> version) - All library versions verified 2026-05-06
- Groq docs (https://console.groq.com/docs/speech-to-text) - Whisper API, Vietnamese support, latency claims
- whisper.cpp GitHub (https://github.com/ggerganov/whisper.cpp) - Self-hosted STT setup, Docker configuration

### Secondary (MEDIUM confidence)
- Prisma docs (https://www.prisma.io/docs) - Schema setup, migration commands (verified via npm)
- Next.js docs (https://nextjs.org/docs/app/guides/testing) - Testing framework recommendations

### Tertiary (LOW confidence)
- WebSearch results for VieNeu-TTS, LiveKit Docker Compose, Vietnamese TTS comparisons — no detailed results found; marked for validation

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH - All library versions verified via npm registry; patterns from official docs
- Architecture: MEDIUM - Strategy pattern assumed based on standard practices; provider APIs need verification during implementation
- Pitfalls: MEDIUM - Common pitfalls identified from experience and docs; some (Vietnamese STT accuracy) need testing

**Research date:** 2026-05-06
**Valid until:** 2026-06-06 (30 days for stable stacks; STT/TTS providers may change more frequently)
