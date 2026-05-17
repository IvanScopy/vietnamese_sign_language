# Phase 01: Foundation & Authentication - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 15 (inferred from CONTEXT.md and RESEARCH.md)
**Analogs found:** 0 / 15 (greenfield project - no existing codebase)

## File Classification

| New/Modified File | Role | Data Flow | Closest Analog | Match Quality |
|-------------------|------|-----------|----------------|---------------|
| `prisma/schema.prisma` | model | CRUD | None (greenfield) | no-analog |
| `src/app/api/auth/login/route.ts` | controller | request-response | None (greenfield) | no-analog |
| `src/app/api/auth/register/route.ts` | controller | request-response | None (greenfield) | no-analog |
| `src/app/api/auth/refresh/route.ts` | controller | request-response | None (greenfield) | no-analog |
| `src/app/api/stt/transcribe/route.ts` | controller | streaming/file-I/O | None (greenfield) | no-analog |
| `src/app/api/tts/synthesize/route.ts` | controller | streaming/file-I/O | None (greenfield) | no-analog |
| `src/app/api/notifications/register-token/route.ts` | controller | request-response | None (greenfield) | no-analog |
| `src/app/lib/auth.ts` | utility | transform | None (greenfield) | no-analog |
| `src/app/lib/session.ts` | utility | CRUD | None (greenfield) | no-analog |
| `src/app/lib/db.ts` | config | CRUD | None (greenfield) | no-analog |
| `src/app/lib/validators.ts` | utility | transform | None (greenfield) | no-analog |
| `src/lib/providers/stt-provider.ts` | service (interface) | transform | None (greenfield) | no-analog |
| `src/lib/providers/tts-provider.ts` | service (interface) | transform | None (greenfield) | no-analog |
| `src/lib/providers/groq-stt.ts` | service | streaming/file-I/O | None (greenfield) | no-analog |
| `src/lib/providers/whisper-cpp-stt.ts` | service | streaming/file-I/O | None (greenfield) | no-analog |
| `src/lib/providers/elevenlabs-tts.ts` | service | streaming/file-I/O | None (greenfield) | no-analog |
| `src/lib/providers/coqui-tts.ts` | service | streaming/file-I/O | None (greenfield) | no-analog |
| `src/lib/livekit.ts` | utility | request-response | None (greenfield) | no-analog |
| `docker-compose.yml` | config | batch | None (greenfield) | no-analog |
| `src/__tests__/auth/register.test.ts` | test | CRUD | None (greenfield) | no-analog |
| `src/__tests__/auth/login.test.ts` | test | CRUD | None (greenfield) | no-analog |
| `src/__tests__/stt/transcribe.test.ts` | test | streaming | None (greenfield) | no-analog |
| `src/__tests__/tts/synthesize.test.ts` | test | streaming | None (greenfield) | no-analog |
| `src/__tests__/notifications/push.test.ts` | test | event-driven | None (greenfield) | no-analog |
| `src/__tests__/setup.ts` | test utility | transform | None (greenfield) | no-analog |

## Pattern Assignments

### Greenfield Project - No Existing Analogs

This is a greenfield project. According to CONTEXT.md:
> "Reusable Assets: None — this is a greenfield project with no existing codebase."
> "Established Patterns: None — patterns to be established during Phase 1 implementation."

All patterns must be drawn from RESEARCH.md examples and official documentation references.

---

### `prisma/schema.prisma` (model, CRUD)

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (lines 331-373):
```prisma
// Source: RESEARCH.md - Prisma Schema for User Authentication
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

**Notes:**
- Pattern marked `[ASSUMED]` in RESEARCH.md - verify during implementation
- May need adjustments for actual requirements (emergency contacts, etc.)

---

### `src/app/api/auth/login/route.ts` (controller, request-response)

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (lines 304-329) - Next.js Route Handler with Zod Validation:
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

**Additional Pattern from RESEARCH.md** (lines 170-201) - JWT Authentication:
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

**Notes:**
- Use `jose` library (Edge-compatible) as recommended by Next.js docs
- Store JWTs in httpOnly, Secure, SameSite cookies (not localStorage)
- Access token: 15 minutes; Refresh token: 7 days

---

### `src/app/api/auth/register/route.ts` (controller, request-response)

**Analog:** None (greenfield)

**Reference Pattern:** Same as login route above - use Next.js Route Handler with Zod validation.

**Additional Pattern - Password Hashing:**
```typescript
// Use bcrypt for password hashing (RESEARCH.md line 39)
import bcrypt from 'bcrypt'

const saltRounds = 10
const hashedPassword = await bcrypt.hash(password, saltRounds)
```

**Notes:**
- Email must be unique (enforced by Prisma schema)
- Hash password with bcrypt before storing
- Return user object without password in response

---

### `src/app/api/auth/refresh/route.ts` (controller, request-response)

**Analog:** None (greenfield)

**Reference Pattern:** Use JWT refresh token pattern from RESEARCH.md lines 194-201.

**Notes:**
- Validate incoming refresh token
- Check expiration and token validity in database
- Issue new access token (and optionally new refresh token)
- Implement refresh token rotation for security

---

### `src/app/api/stt/transcribe/route.ts` (controller, streaming/file-I/O)

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (lines 209-237) - STT Provider Strategy:
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

**Notes:**
- Pattern marked `[ASSUMED]` in RESEARCH.md - provider APIs need verification during implementation
- Support audio file upload (multipart/form-data)
- Language parameter default to 'vi' (Vietnamese)
- Implement fallback: Groq → whisper.cpp on failure

---

### `src/app/api/tts/synthesize/route.ts` (controller, streaming/file-I/O)

**Analog:** None (greenfield)

**Reference Pattern:** Similar to STT - use Strategy Pattern with provider abstraction.

**Notes:**
- Accept text input and return audio stream
- Providers: ElevenLabs/Google TTS (cloud), Coqui TTS (self-hosted fallback)
- Environment variable: `TTS_PROVIDER=elevenlabs|local|vieneu`
- Latency target: <500ms

---

### `src/app/api/notifications/register-token/route.ts` (controller, request-response)

**Analog:** None (greenfield)

**Reference Pattern:** Use Next.js Route Handler with Zod validation (same as auth routes).

**Notes:**
- Accept FCM/APNs device tokens from client
- Store tokens in database associated with user
- Used for push notifications when app is background/closed

---

### `src/app/lib/auth.ts` (utility, transform)

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (lines 170-201) - JWT utilities using `jose`.

**Notes:**
- Export `encrypt`, `decrypt`, `generateRefreshToken` functions
- Use HS256 algorithm with `jose` library
- Keep secret keys in environment variables

---

### `src/app/lib/session.ts` (utility, CRUD)

**Analog:** None (greenfield)

**Reference Pattern:** Session management using JWT refresh tokens.

**Notes:**
- Handle refresh token storage and validation
- Clean up expired tokens from database
- Support multiple concurrent sessions (per CONTEXT.md decision)

---

### `src/app/lib/db.ts` (config, CRUD)

**Analog:** None (greenfield)

**Reference Pattern - Prisma Client Singleton:**
```typescript
// Standard Next.js pattern to prevent multiple Prisma Client instances in development
import { PrismaClient } from '@prisma/client'

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined
}

export const prisma = globalForPrisma.prisma ?? new PrismaClient()

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma
```

**Notes:**
- RESEARCH.md Pitfall 4: Avoid multiple Prisma Client instances in development
- Use singleton pattern for Prisma Client

---

### `src/app/lib/validators.ts` (utility, transform)

**Analog:** None (greenfield)

**Reference Pattern - Zod Schemas:**
```typescript
import { z } from 'zod'

export const LoginSchema = z.object({
  email: z.email(),
  password: z.string().min(8),
})

export const RegisterSchema = z.object({
  email: z.email(),
  password: z.string().min(8),
  name: z.string().optional(),
  userType: z.enum(['DEAF', 'HEARING']).default('HEARING'),
})

// Add more schemas as needed for STT, TTS, notifications
```

**Notes:**
- Use `zod` v4.4.3 (verified in RESEARCH.md)
- Infer TypeScript types from schemas
- Validate all API inputs

---

### `src/lib/providers/stt-provider.ts` (service interface, transform)

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (lines 210-212):
```typescript
export interface STTProvider {
  transcribe(audioBuffer: Buffer, language?: string): Promise<string>
}
```

**Notes:**
- Define interface for STT provider abstraction
- All STT implementations must implement this interface

---

### `src/lib/providers/tts-provider.ts` (service interface, transform)

**Analog:** None (greenfield)

**Reference Pattern:**
```typescript
export interface TTSProvider {
  synthesize(text: string, language?: string): Promise<Buffer> // or audio stream
}
```

**Notes:**
- Define interface for TTS provider abstraction
- All TTS implementations must implement this interface

---

### `src/lib/providers/groq-stt.ts` (service, streaming/file-I/O)

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (lines 215-227).

**Notes:**
- Implement `STTProvider` interface
- Use Groq Whisper API (`whisper-large-v3` or `whisper-large-v3-turbo`)
- API key from `GROQ_API_KEY` environment variable
- Vietnamese supported via multilingual models

---

### `src/lib/providers/whisper-cpp-stt.ts` (service, streaming/file-I/O)

**Analog:** None (greenfield)

**Reference Pattern:**
- Implement `STTProvider` interface
- Use whisper.cpp server (Docker container)
- Communicate via HTTP API to whisper-server
- Fallback for when Groq is unavailable

**Notes:**
- Requires ~2GB model file for large-v3
- CPU-based inference (slower than Groq but free)
- Deploy as Docker container on same VPS

---

### `src/lib/providers/elevenlabs-tts.ts` (service, streaming/file-I/O)

**Analog:** None (greenfield)

**Reference Pattern:**
- Implement `TTSProvider` interface
- Use ElevenLabs API for high-quality neural TTS
- API key from `ELEVENLABS_API_KEY` environment variable

**Notes:**
- Cloud primary TTS provider
- Vietnamese language support - verify during implementation
- Fallback to Coqui TTS if unavailable

---

### `src/lib/providers/coqui-tts.ts` (service, streaming/file-I/O)

**Analog:** None (greenfield)

**Reference Pattern:**
- Implement `TTSProvider` interface
- Self-hosted Coqui TTS server
- Deploy as Docker container on same VPS

**Notes:**
- Fallback TTS provider
- Lower quality than ElevenLabs but free and self-hosted
- Vietnamese language support - verify during implementation

---

### `src/lib/livekit.ts` (utility, request-response)

**Analog:** None (greenfield)

**Reference Pattern:**
```typescript
// Use livekit-server-sdk to generate tokens
import { AccessToken } from 'livekit-server-sdk'

export function generateLiveKitToken(roomName: string, participantName: string) {
  const token = new AccessToken(
    process.env.LIVEKIT_API_KEY!,
    process.env.LIVEKIT_API_SECRET!,
    {
      identity: participantName,
    }
  )
  token.addGrant({ roomJoin: true, room: roomName })
  return token.toJwt()
}
```

**Notes:**
- Use `livekit-server-sdk` v2.15.2 (verified in RESEARCH.md)
- Generate tokens for clients to join LiveKit rooms
- API key and secret from environment variables

---

### `docker-compose.yml` (config, batch)

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (inferred from Architecture section):
```yaml
version: '3.8'

services:
  postgres:
    image: postgres:16
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: password
      POSTGRES_DB: vsl_bridge
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"

  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"

  livekit:
    image: livekit/livekit-server:latest
    environment:
      LIVEKIT_KEYS: "api-key:api-secret"
    ports:
      - "7880:7880"   # HTTP
      - "7881:7881"   # WebSocket
      - "7882:7882/udp" # RTC
    volumes:
      - livekit_data:/data

  # API service (Next.js or Node.js backend)
  # Uncomment when ready to deploy
  # api:
  #   build: .
  #   ports:
  #     - "3000:3000"
  #   environment:
  #     DATABASE_URL: postgresql://user:password@postgres:5432/vsl_bridge
  #     REDIS_URL: redis://redis:6379
  #   depends_on:
  #     - postgres
  #     - redis

volumes:
  postgres_data:
  livekit_data:
```

**Notes:**
- All services on one VPS via Docker Compose (per CONTEXT.md)
- Cost target: $6-10/month
- LiveKit self-hosted for video calling infrastructure
- PostgreSQL + Redis on same VPS (no managed services)

---

### Test Files

**Analog:** None (greenfield)

**Reference Pattern from RESEARCH.md** (lines 457-490) - Jest Configuration:

**jest.config.ts:**
```typescript
import type { Config } from 'jest'

const config: Config = {
  preset: 'ts-jest',
  testEnvironment: 'node',
  roots: ['<rootDir>/src/__tests__'],
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
}

export default config
```

**Test File Pattern (example from RESEARCH.md lines 482-487):**
```typescript
// src/__tests__/auth/register.test.ts
import { POST } from '@/app/api/auth/register/route'
import { prisma } from '@/app/lib/db'

// Mock Prisma client
jest.mock('@/app/lib/db', () => ({
  prisma: {
    user: {
      findUnique: jest.fn(),
      create: jest.fn(),
    },
    refreshToken: {
      create: jest.fn(),
    },
  },
}))

describe('POST /api/auth/register', () => {
  it('should register a new user', async () => {
    // Test implementation
  })

  it('should return 400 for invalid input', async () => {
    // Test implementation
  })
})
```

**Notes:**
- Use Jest 30.3.0 (verified in RESEARCH.md)
- Create shared test setup file: `src/__tests__/setup.ts`
- Mock Prisma client and external services (Groq, ElevenLabs, etc.)
- Cover requirements: ACC-01, ACC-02, ACC-03, NOTIF-01, NOTIF-02, COMM-02, COMM-03

---

## Shared Patterns

### Authentication Pattern
**Source:** RESEARCH.md (lines 166-201) - JWT Authentication with Refresh Tokens
**Apply to:** All API routes requiring authentication
```typescript
// Use jose for Edge-compatible JWT operations
import { SignJWT, jwtVerify } from 'jose'

// Access token: 15 minutes (short-lived)
// Refresh token: 7 days (long-lived)
// Store in httpOnly, Secure, SameSite cookies
```
**Key Points:**
- Stateless JWT (no Redis needed for sessions per CONTEXT.md)
- Multiple concurrent sessions allowed
- Token rotation for security

---

### Input Validation Pattern
**Source:** RESEARCH.md (lines 303-329) - Zod Validation
**Apply to:** All POST/PUT API route handlers
```typescript
import { z } from 'zod'

const Schema = z.object({...})
const validated = Schema.safeParse(body)

if (!validated.success) {
  return NextResponse.json(
    { errors: validated.error.flatten() },
    { status: 400 }
  )
}
```
**Key Points:**
- Use `zod` v4.4.3 for schema validation
- Validate environment variables at startup
- Infer TypeScript types from schemas

---

### Error Handling Pattern
**Source:** Standard Next.js Route Handler pattern
**Apply to:** All API route handlers
```typescript
try {
  // Route logic
  return NextResponse.json({ data: result })
} catch (error) {
  console.error(error)
  return NextResponse.json(
    { error: 'Internal server error' },
    { status: 500 }
  )
}
```
**Key Points:**
- Use try/catch in all route handlers
- Log errors server-side
- Return appropriate HTTP status codes
- Don't expose internal error details to client

---

### Provider Strategy Pattern
**Source:** RESEARCH.md (lines 204-239) - STT/TTS Provider Strategy
**Apply to:** STT and TTS service implementations
```typescript
export interface Provider {
  method(params): Promise<result>
}

// Select provider based on environment variable
function getProvider(): Provider {
  const provider = process.env.PROVIDER_VAR || 'default'
  switch (provider) {
    case 'cloud': return new CloudProvider()
    case 'local': return new LocalProvider()
    default: return new CloudProvider()
  }
}
```
**Key Points:**
- Abstraction layer for flexibility
- Environment variable configuration: `STT_PROVIDER`, `TTS_PROVIDER`
- Fallback mechanism: Cloud primary → self-hosted on failure
- Latency targets: <500ms for both STT and TTS

---

### Database Access Pattern
**Source:** Prisma ORM standard pattern
**Apply to:** All database operations
```typescript
import { prisma } from '@/app/lib/db'

// Use Prisma Client for type-safe database access
const user = await prisma.user.findUnique({
  where: { email },
  include: { refreshTokens: true },
})
```
**Key Points:**
- Use Prisma 7.8.0 (verified in RESEARCH.md)
- Type-safe queries with auto-generated types
- Prevent SQL injection (parameterized queries)
- Use migrations for schema evolution

---

### Real-time Communication Pattern
**Source:** Socket.io standard pattern
**Apply to:** Real-time notifications (in-app)
```typescript
import { Server as SocketIOServer } from 'socket.io'

const io = new SocketIOServer(httpServer, {
  cors: { origin: process.env.CLIENT_URL },
})

io.on('connection', (socket) => {
  // Handle notification events
  socket.on('register', (userId) => {
    // Associate socket with user
  })
})
```
**Key Points:**
- Use Socket.io 4.8.3 for WebSocket communication
- FCM/APNs for background/closed app notifications
- Hybrid approach: Socket.io (active) + FCM/APNs (background)
- Custom vibration/haptic patterns for deaf users

---

## No Analog Found

All files have no close match in the codebase (greenfield project).

| File | Role | Data Flow | Reason |
|------|------|-----------|--------|
| All files listed above | Various | Various | Greenfield project - no existing codebase to draw patterns from |

**Recommendation for Planner:**
Use the reference patterns from RESEARCH.md and official documentation links provided in the Pattern Assignments section above. All patterns are marked with their source (Next.js docs, Prisma docs, etc.) and verification status (`[VERIFIED]` or `[ASSUMED]`).

---

## Documentation References

These official documentation sources should be used during implementation:

| Library | Documentation URL | Purpose |
|---------|-------------------|---------|
| **Next.js** | https://nextjs.org/docs/app/guides/authentication | JWT authentication patterns, Route Handlers |
| **Next.js** | https://nextjs.org/docs/app/api-reference/file-conventions/route | Route Handler API |
| **Prisma** | https://www.prisma.io/docs | Schema setup, migration commands |
| **jose** | https://github.com/panva/jose | JWT signing/verification (Edge-compatible) |
| **zod** | https://zod.dev/ | Schema validation |
| **Socket.io** | https://socket.io/docs/v4/ | Real-time bidirectional events |
| **LiveKit** | https://docs.livekit.io/ | Self-hosted WebRTC SFU |
| **Groq** | https://console.groq.com/docs/speech-to-text | Whisper API for STT |

---

## Metadata

**Analog search scope:** Entire project `/home/ivan/vsl-final-5days`
**Files scanned:** 1 (only `.planning/config.json` exists; no source code)
**Pattern extraction date:** 2026-05-06
**Project status:** Greenfield (no existing codebase)
**Primary pattern sources:**
- RESEARCH.md (01-RESEARCH.md) - Verified patterns and code examples
- Next.js official documentation - Route Handlers, Authentication
- Prisma official documentation - Schema, migrations, client usage
- Socket.io documentation - Real-time communication patterns

**Confidence:** HIGH for library versions (verified via npm registry), MEDIUM for STT/TTS provider APIs (marked `[ASSUMED]` in RESEARCH.md)
