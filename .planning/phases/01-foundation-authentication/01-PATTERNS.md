# Phase 1: Foundation & Authentication - Pattern Map

**Mapped:** 2026-05-06
**Files analyzed:** 22
**Analogs found:** N/A (greenfield project - patterns sourced from RESEARCH.md)

---

## Overview

Phase 1 establishes the backend foundation for the VSL Bridge. This document codifies the architectural patterns, coding conventions, and implementation standards that all subsequent planners and implementers must follow.

**Technology Stack:**
- **Runtime:** Node.js 22.x LTS
- **Framework:** Express.js 4.21.1
- **ORM:** Prisma 6.x with PostgreSQL 16/17
- **Cache:** Redis 7.x
- **Real-time:** Socket.io 4.8.0
- **Auth:** JWT (jsonwebtoken 9.0.2) + bcrypt 5.1.1
- **STT/TTS:** Strategy pattern with Groq/Whisper.cpp and ElevenLabs/Coqui fallbacks
- **Video:** LiveKit server 2.x
- **Testing:** Jest with TypeScript

---

## File Classification

| New/Modified File | Role | Data Flow | Source Pattern | Match Quality |
|-------------------|------|-----------|-----------------|---------------|
| `prisma/schema.prisma` | model | N/A (schema) | RESEARCH.md: Prisma Schema | exact |
| `src/config/database.ts` | config | connection-pool | RESEARCH.md: config patterns | exact |
| `src/config/redis.ts` | config | connection-pool | RESEARCH.md: config patterns | exact |
| `src/config/socket.ts` | config | event-driven | RESEARCH.md: Socket.io setup | exact |
| `src/config/stt.ts` | config | request-response | RESEARCH.md: STT Strategy Pattern | exact |
| `src/config/tts.ts` | config | request-response | RESEARCH.md: TTS Strategy Pattern | exact |
| `src/config/livekit.ts` | config | request-response | RESEARCH.md: LiveKit config | exact |
| `src/middleware/auth.ts` | middleware | request-response | RESEARCH.md: JWT pattern | exact |
| `src/middleware/rateLimit.ts` | middleware | request-response | RESEARCH.md: Rate limiting | exact |
| `src/middleware/errorHandler.ts` | middleware | request-response | RESEARCH.md: Error handling | exact |
| `src/routes/auth.routes.ts` | route | request-response | RESEARCH.md: Routes structure | exact |
| `src/routes/stt.routes.ts` | route | request-response | RESEARCH.md: Routes structure | exact |
| `src/routes/tts.routes.ts` | route | request-response | RESEARCH.md: Routes structure | exact |
| `src/routes/notifications.routes.ts` | route | request-response | RESEARCH.md: Routes structure | exact |
| `src/routes/livekit.routes.ts` | route | request-response | RESEARCH.md: Routes structure | exact |
| `src/services/auth.service.ts` | service | request-response | RESEARCH.md: Auth service pattern | exact |
| `src/services/user.service.ts` | service | CRUD | RESEARCH.md: User service pattern | exact |
| `src/services/notification.service.ts` | service | event-driven | RESEARCH.md: Notification service | exact |
| `src/services/token.service.ts` | service | request-response | RESEARCH.md: Token rotation | exact |
| `src/utils/logger.ts` | utility | N/A | RESEARCH.md: Logging convention | exact |
| `src/utils/validator.ts` | utility | N/A | RESEARCH.md: Zod validation | exact |
| `src/server.ts` | controller | N/A (bootstrap) | RESEARCH.md: Server bootstrap | exact |
| `docker-compose.yaml` | config | N/A | RESEARCH.md: Docker Compose | exact |
| `Dockerfile` | config | N/A | RESEARCH.md: Docker best practices | exact |
| `.env.example` | config | N/A | RESEARCH.md: Environment vars | exact |
| `jest.config.ts` | test | N/A | RESEARCH.md: Test framework | exact |

---

## Pattern Assignments

### `prisma/schema.prisma` (model)

**Source:** RESEARCH.md: Prisma Schema for Users and Sessions

**Complete Schema Pattern:**
```prisma
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
  id             String   @id @default(cuid())
  conversationId String
  role           String   // 'user' | 'assistant'
  content        String   // text content
  audioUrl       String?  // optional audio recording
  createdAt      DateTime @default(now())
  
  @@index([conversationId])
}
```

**Conventions:**
- Use `cuid()` for all ID fields (distributed-safe)
- `@updatedAt` auto-updates timestamp on record changes
- Index foreign keys and frequently queried fields
- Nullable `passwordHash` for OAuth-only users
- `jti` field for JWT token revocation lookup

---

### `src/config/database.ts` (config)

**Source:** RESEARCH.md + Prisma patterns

**Database Configuration Pattern:**
```typescript
// src/config/database.ts
import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as {
  prisma: PrismaClient | undefined;
};

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

// Log all Prisma queries in development
if (process.env.NODE_ENV === 'development') {
  prisma.$on('query', (e) => {
    console.log('Query:', e.query);
    console.log('Duration:', e.duration, 'ms');
  });
}
```

**Conventions:**
- Singleton PrismaClient to prevent connection pool exhaustion
- Development query logging for debugging
- Use environment DATABASE_URL from Docker

---

### `src/config/redis.ts` (config)

**Source:** RESEARCH.md: Redis for caching and token blacklist

**Redis Configuration Pattern:**
```typescript
// src/config/redis.ts
import { createClient, RedisClientType } from 'redis';

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

export const redisClient: RedisClientType = createClient({
  url: redisUrl,
});

redisClient.on('error', (err) => {
  console.error('Redis Client Error:', err);
});

redisClient.on('connect', () => {
  console.log('Redis client connected');
});

// Connect on module load
redisClient.connect().catch(console.error);

// Utility: Health check
export async function redisHealthCheck(): Promise<boolean> {
  try {
    await redisClient.ping();
    return true;
  } catch {
    return false;
  }
}
```

---

### `src/config/socket.ts` (config)

**Source:** RESEARCH.md: Socket.io + Push Notification Hybrid pattern

**Socket.io Setup Pattern:**
```typescript
// src/config/socket.ts
import { Server as SocketIOServer } from 'socket.io';
import { Server } from 'http';
import { verifyJWT } from '../middleware/auth.js';
import { NotificationService } from '../services/notification.service.js';

export function setupSocket(
  server: Server,
  notificationService: NotificationService
): SocketIOServer {
  const io = new SocketIOServer(server, {
    cors: {
      origin: process.env.CLIENT_ORIGIN || 'http://localhost:3000',
      credentials: true,
    },
    transports: ['websocket', 'polling'],
    // Increased ping timeout for mobile networks
    pingTimeout: 60000,
    pingInterval: 25000,
  });

  // JWT authentication middleware
  io.use(async (socket, next) => {
    const token = socket.handshake.auth.token;
    if (!token) {
      return next(new Error('Authentication required'));
    }
    try {
      const decoded = verifyJWT(token);
      socket.data.userId = decoded.sub;
      next();
    } catch (err) {
      next(new Error('Invalid token'));
    }
  });

  io.on('connection', (socket) => {
    const userId = socket.data.userId;
    const userRoom = `user:${userId}`;
    socket.join(userRoom);

    console.log(`User ${userId} connected to Socket.io`);

    socket.on('disconnect', (reason) => {
      socket.leave(userRoom);
      console.log(`User ${userId} disconnected: ${reason}`);
    });

    // Handle SOS broadcast
    socket.on('sos:trigger', async (data) => {
      await notificationService.broadcastSOS(userId, data);
    });
  });

  return io;
}
```

---

### `src/config/stt.ts` (config)

**Source:** RESEARCH.md: STT Strategy Pattern with Fallback

**STT Strategy Pattern:**
```typescript
// src/config/stt.ts
import { Groq } from '@groq/sdk';

export interface STTProvider {
  transcribe(audio: Buffer, language?: string): Promise<string>;
  healthCheck(): Promise<boolean>;
}

// Groq Cloud Whisper (primary)
export class GroqSTT implements STTProvider {
  private groq: Groq;

  constructor() {
    this.groq = new Groq({
      apiKey: process.env.GROQ_API_KEY,
    });
  }

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
      // Minimal test - 1 byte of silence
      const testAudio = Buffer.from('RIFF\x00\x00\x00\x00WAVEfmt \x00\x00\x00\x00\x00\x00\x00\x00\x00\x00data\x00\x00\x00\x00');
      await this.groq.audio.transcriptions.create({
        file: testAudio,
        model: 'whisper-large-v3',
      });
      return true;
    } catch {
      return false;
    }
  }
}

// Whisper.cpp self-hosted fallback
export class WhisperCppSTT implements STTProvider {
  private endpoint: string;

  constructor() {
    this.endpoint = process.env.STT_FALLBACK_URL || 'http://localhost:8081/transcribe';
  }

  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    const response = await fetch(this.endpoint, {
      method: 'POST',
      body: audio,
      headers: {
        'Content-Type': 'audio/wav',
      },
    });

    if (!response.ok) {
      throw new Error(`Whisper.cpp error: ${response.statusText}`);
    }

    const { text } = await response.json();
    return text;
  }

  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.endpoint.replace('/transcribe', '/health')}`);
      return response.ok;
    } catch {
      return false;
    }
  }
}

// Manager with automatic failover
export class STTManager {
  private providers: STTProvider[] = [];

  constructor(primary: STTProvider, fallback?: STTProvider) {
    this.providers = [primary];
    if (fallback) this.providers.push(fallback);
  }

  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    let lastError: Error | null = null;

    for (const provider of this.providers) {
      try {
        if (await provider.healthCheck()) {
          return await provider.transcribe(audio, language);
        }
      } catch (error) {
        console.warn(`STT provider ${provider.constructor.name} failed:`, error);
        lastError = error as Error;
        continue;
      }
    }

    throw new Error(`All STT providers failed. Last error: ${lastError?.message}`);
  }
}

// Factory function for DI
export function createSTTManager(): STTManager {
  const primary = new GroqSTT();
  const fallback = process.env.USE_FALLBACK === 'true' ? new WhisperCppSTT() : undefined;
  return new STTManager(primary, fallback);
}
```

---

### `src/config/tts.ts` (config)

**Source:** RESEARCH.md: TTS Strategy Pattern with Fallback

**TTS Strategy Pattern:**
```typescript
// src/config/tts.ts
export interface TTSProvider {
  synthesize(text: string, language?: string): Promise<Buffer>;
  healthCheck(): Promise<boolean>;
}

// ElevenLabs Cloud TTS (primary)
export class ElevenLabsTTS implements TTSProvider {
  private apiKey: string;
  private baseUrl = 'https://api.elevenlabs.io/v1';

  constructor() {
    this.apiKey = process.env.ELEVENLABS_API_KEY!;
  }

  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    const response = await fetch(`${this.baseUrl}/text-to-speech/EXAVITQu4vr4xnSDxMaL`, {
      method: 'POST',
      headers: {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': this.apiKey,
      },
      body: JSON.stringify({
        text,
        model_id: 'eleven_multilingual_v3',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.5,
        },
      }),
    });

    if (!response.ok) {
      throw new Error(`ElevenLabs error: ${response.statusText}`);
    }

    return Buffer.from(await response.arrayBuffer());
  }

  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.baseUrl}/user`, {
        headers: { 'xi-api-key': this.apiKey },
      });
      return response.ok;
    } catch {
      return false;
    }
  }
}

// Coqui TTS self-hosted fallback
export class CoquiTTS implements TTSProvider {
  private endpoint: string;

  constructor() {
    this.endpoint = process.env.TTS_FALLBACK_URL || 'http://localhost:5002/api/tts';
  }

  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    const params = new URLSearchParams({
      text,
      language_id: language,
    });

    const response = await fetch(`${this.endpoint}?${params.toString()}`, {
      method: 'POST',
    });

    if (!response.ok) {
      throw new Error(`Coqui TTS error: ${response.statusText}`);
    }

    return Buffer.from(await response.arrayBuffer());
  }

  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.endpoint.replace('/api/tts', '/health')}`);
      return response.ok;
    } catch {
      return false;
    }
  }
}

export class TTSManager {
  private providers: TTSProvider[] = [];

  constructor(primary: TTSProvider, fallback?: TTSProvider) {
    this.providers = [primary];
    if (fallback) this.providers.push(fallback);
  }

  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    let lastError: Error | null = null;

    for (const provider of this.providers) {
      try {
        if (await provider.healthCheck()) {
          return await provider.synthesize(text, language);
        }
      } catch (error) {
        console.warn(`TTS provider ${provider.constructor.name} failed:`, error);
        lastError = error as Error;
        continue;
      }
    }

    throw new Error(`All TTS providers failed. Last error: ${lastError?.message}`);
  }
}

export function createTTSManager(): TTSManager {
  const primary = new ElevenLabsTTS();
  const fallback = process.env.USE_FALLBACK === 'true' ? new CoquiTTS() : undefined;
  return new TTSManager(primary, fallback);
}
```

---

### `src/config/livekit.ts` (config)

**Source:** RESEARCH.md: LiveKit configuration

**LiveKit Configuration Pattern:**
```typescript
// src/config/livekit.ts
import { LiveKitRoom, Room } from 'livekit-server-sdk';

export interface LiveKitConfig {
  apiKey: string;
  apiSecret: string;
  wsUrl: string;
  rtcpUrl: string;
}

export function createLiveKitConfig(): LiveKitConfig {
  return {
    apiKey: process.env.LIVEKIT_API_KEY!,
    apiSecret: process.env.LIVEKIT_API_SECRET!,
    wsUrl: process.env.LIVEKIT_WS_URL || 'ws://localhost:7880',
    rtcpUrl: process.env.LIVEKIT_RTC_URL || 'http://localhost:7880',
  };
}

export function createRoomService(config: LiveKitConfig) {
  const roomService = new RoomServiceClient(
    config.rtcpUrl,
    config.apiKey,
    config.apiSecret
  );
  return roomService;
}

export function generateRoomToken(
  config: LiveKitConfig,
  roomName: string,
  participantName: string,
  isAdmin = false
): string {
  const { apiKey, apiSecret, wsUrl } = config;

  const accessToken = new AccessToken(apiKey, apiSecret, {
    identity: participantName,
    name: participantName,
    metadata: JSON.stringify({ isAdmin }),
  });

  const video = true;
  const audio = true;

  const token = accessToken.toJwt({ room: roomName, video, audio });
  return token;
}
```

---

### `src/middleware/auth.ts` (middleware)

**Source:** RESEARCH.md: JWT verification pattern

**Authentication Middleware Pattern:**
```typescript
// src/middleware/auth.ts
import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

interface JwtPayload {
  sub: string;
  type: string;
  iat?: number;
  exp?: number;
}

export function verifyJWT(token: string): JwtPayload {
  const secret = process.env.JWT_SECRET!;
  const decoded = jwt.verify(token, secret) as JwtPayload;
  return decoded;
}

export function authenticate(req: Request, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    res.status(401).json({ error: 'No token provided' });
    return;
  }

  const token = authHeader.split(' ')[1];

  try {
    const decoded = verifyJWT(token);
    (req as any).userId = decoded.sub;
    (req as any).userType = decoded.type;
    next();
  } catch (err) {
    if (err instanceof jwt.TokenExpiredError) {
      res.status(401).json({ error: 'Token expired' });
      return;
    }
    res.status(401).json({ error: 'Invalid token' });
  }
}

// Optional: Role-based authorization
export function authorize(roles: string[]) {
  return (req: Request, res: Response, next: NextFunction): void => {
    const userRole = (req as any).userType;
    if (!roles.includes(userRole)) {
      res.status(403).json({ error: 'Insufficient permissions' });
      return;
    }
    next();
  };
}
```

---

### `src/middleware/rateLimit.ts` (middleware)

**Source:** RESEARCH.md: Rate limiting with Redis store

**Rate Limiting Pattern:**
```typescript
// src/middleware/rateLimit.ts
import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { redisClient } from '../config/redis.js';

// General API rate limit
export const apiRateLimit = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rate-limit:',
  }),
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: { error: 'Too many requests from this IP, please try again later.' },
  standardHeaders: true,
  legacyHeaders: false,
});

// Stricter limit for auth endpoints
export const authRateLimit = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rate-limit-auth:',
  }),
  windowMs: 15 * 60 * 1000,
  max: 5, // 5 attempts per 15 minutes
  message: { error: 'Too many authentication attempts, please try again later.' },
  skipSuccessfulRequests: true,
});

// STT/TTS endpoints (protect against abuse)
export const mlRateLimit = rateLimit({
  store: new RedisStore({
    client: redisClient,
    prefix: 'rate-limit-ml:',
  }),
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 50, // 50 ML requests per hour
  message: { error: 'ML service quota exceeded.' },
});
```

---

### `src/middleware/errorHandler.ts` (middleware)

**Source:** RESEARCH.md: Centralized error handling

**Error Handler Pattern:**
```typescript
// src/middleware/errorHandler.ts
import { Request, Response, NextFunction } from 'express';
import { logger } from '../utils/logger.js';

export class AppError extends Error {
  statusCode: number;
  isOperational: boolean;

  constructor(message: string, statusCode: number) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    
    Error.captureStackTrace(this, this.constructor);
  }
}

export function errorHandler(
  err: Error | AppError,
  req: Request,
  res: Response,
  next: NextFunction
): void {
  // Log error
  logger.error({
    message: err.message,
    stack: err.stack,
    url: req.url,
    method: req.method,
    body: req.body,
  });

  // Operational errors (AppError)
  if (err instanceof AppError) {
    res.status(err.statusCode).json({
      error: err.message,
    });
    return;
  }

  // Programming errors (should not happen)
  res.status(500).json({
    error: 'Internal server error',
  });
}

// Not found handler (404)
export function notFoundHandler(req: Request, res: Response): void {
  res.status(404).json({
    error: `Route ${req.method} ${req.url} not found`,
  });
}
```

---

### `src/routes/auth.routes.ts` (route)

**Source:** RESEARCH.md: Routes structure and auth endpoints

**Auth Routes Pattern:**
```typescript
// src/routes/auth.routes.ts
import { Router, Request, Response } from 'express';
import { body } from 'express-validator';
import { authRateLimit } from '../middleware/rateLimit.js';
import { authenticate, authorize } from '../middleware/auth.js';
import { AuthService } from '../services/auth.service.js';
import { validator } from '../utils/validator.js';

const router = Router();
const authService = new AuthService();

// Validation rules
const registerValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').isLength({ min: 8 }),
  body('name').optional().trim(),
];

const loginValidation = [
  body('email').isEmail().normalizeEmail(),
  body('password').notEmpty(),
];

// POST /api/v1/auth/register
router.post('/register', authRateLimit, registerValidation, validator, async (req: Request, res: Response) => {
  try {
    const { email, password, name } = req.body;
    const result = await authService.register(email, password, name);
    res.status(201).json({ data: result });
  } catch (err: any) {
    if (err.code === 'P2002') {
      // Unique constraint violation (email exists)
      res.status(409).json({ error: 'Email already registered' });
      return;
    }
    res.status(500).json({ error: 'Registration failed' });
  }
});

// POST /api/v1/auth/login
router.post('/login', authRateLimit, loginValidation, validator, async (req: Request, res: Response) => {
  try {
    const { email, password } = req.body;
    const result = await authService.login(email, password);
    res.json({ data: result });
  } catch (err: any) {
    if (err.message === 'Invalid credentials') {
      res.status(401).json({ error: err.message });
      return;
    }
    res.status(500).json({ error: 'Login failed' });
  }
});

// POST /api/v1/auth/refresh
router.post('/refresh', async (req: Request, res: Response) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) {
      res.status(400).json({ error: 'Refresh token required' });
      return;
    }
    const result = await authService.refresh(refreshToken);
    res.json({ data: result });
  } catch (err: any) {
    res.status(401).json({ error: 'Invalid refresh token' });
  }
});

// POST /api/v1/auth/logout
router.post('/logout', authenticate, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const { refreshToken } = req.body;
    await authService.logout(userId, refreshToken);
    res.json({ data: { message: 'Logged out' } });
  } catch (err) {
    res.status(500).json({ error: 'Logout failed' });
  }
});

// GET /api/v1/auth/me
router.get('/me', authenticate, async (req: Request, res: Response) => {
  try {
    const userId = (req as any).userId;
    const user = await authService.getUser(userId);
    if (!user) {
      res.status(404).json({ error: 'User not found' });
      return;
    }
    res.json({ data: user });
  } catch (err) {
    res.status(500).json({ error: 'Failed to fetch user' });
  }
});

export default router;
```

---

### `src/routes/stt.routes.ts` (route)

**Source:** RESEARCH.md: STT endpoint pattern

**STT Routes Pattern:**
```typescript
// src/routes/stt.routes.ts
import { Router, Request, Response } from 'express';
import { mlRateLimit } from '../middleware/rateLimit.js';
import { authenticate } from '../middleware/auth.js';
import { STTManager } from '../config/stt.js';

const router = Router();
const sttManager = new STTManager();

// POST /api/v1/stt/transcribe
router.post('/transcribe', mlRateLimit, authenticate, async (req: Request, res: Response) => {
  try {
    // Accept audio as base64 or raw binary
    const { audio, format = 'wav', language = 'vi' } = req.body;

    if (!audio) {
      res.status(400).json({ error: 'Audio data required' });
      return;
    }

    // Decode base64 if needed
    const audioBuffer = Buffer.isBuffer(audio)
      ? audio
      : Buffer.from(audio, 'base64');

    const text = await sttManager.transcribe(audioBuffer, language);

    res.json({ data: { text, language } });
  } catch (err: any) {
    logger.error('STT error:', err);
    res.status(500).json({ error: 'Speech recognition failed' });
  }
});

// POST /api/v1/stt/transcribe-upload (multipart form)
router.post('/transcribe-upload', mlRateLimit, authenticate, async (req: Request, res: Response) => {
  // For file uploads, use multer middleware (not shown for brevity)
  // This is an alternative endpoint for direct file upload
  res.status(501).json({ error: 'Use /transcribe for base64 audio' });
});

export default router;
```

---

### `src/routes/tts.routes.ts` (route)

**Source:** RESEARCH.md: TTS endpoint pattern

**TTS Routes Pattern:**
```typescript
// src/routes/tts.routes.ts
import { Router, Request, Response } from 'express';
import { mlRateLimit } from '../middleware/rateLimit.js';
import { authenticate } from '../middleware/auth.js';
import { TTSManager } from '../config/tts.js';

const router = Router();
const ttsManager = new TTSManager();

// POST /api/v1/tts/synthesize
router.post('/synthesize', mlRateLimit, authenticate, async (req: Request, res: Response) => {
  try {
    const { text, language = 'vi' } = req.body;

    if (!text || typeof text !== 'string') {
      res.status(400).json({ error: 'Text required' });
      return;
    }

    if (text.length > 500) {
      res.status(400).json({ error: 'Text too long (max 500 chars)' });
      return;
    }

    const audioBuffer = await ttsManager.synthesize(text, language);

    res.set({
      'Content-Type': 'audio/mpeg',
      'Content-Length': audioBuffer.length.toString(),
      'Cache-Control': 'no-cache',
    });
    res.send(audioBuffer);
  } catch (err: any) {
    logger.error('TTS error:', err);
    res.status(500).json({ error: 'Speech synthesis failed' });
  }
});

export default router;
```

---

### `src/routes/notifications.routes.ts` (route)

**Source:** RESEARCH.md: Notification routes pattern

**Notification Routes Pattern:**
```typescript
// src/routes/notifications.routes.ts
import { Router, Request, Response } from 'express';
import { authenticate } from '../middleware/auth.js';
import { NotificationService } from '../services/notification.service.js';

const router = Router();
const notificationService = new NotificationService();

// POST /api/v1/notifications/send
router.post('/send', authenticate, async (req: Request, res: Response) => {
  try {
    const { userId, title, body, type, data } = req.body;

    if (!userId || !title || !body) {
      res.status(400).json({ error: 'userId, title, and body required' });
      return;
    }

    await notificationService.sendToUser(userId, { title, body, type, data });
    res.json({ data: { message: 'Notification sent' } });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send notification' });
  }
});

// POST /api/v1/notifications/sos (high priority)
router.post('/sos', authenticate, async (req: Request, res: Response) => {
  try {
    const { userId, location, message } = req.body;

    // Broadcast to emergency contacts (implement separately)
    await notificationService.broadcastSOS(userId, { location, message });

    res.json({ data: { message: 'SOS alert sent' } });
  } catch (err) {
    res.status(500).json({ error: 'Failed to send SOS' });
  }
});

// WebSocket endpoint handled by socket.io, not HTTP

export default router;
```

---

### `src/routes/livekit.routes.ts` (route)

**Source:** RESEARCH.md: LiveKit token generation pattern

**LiveKit Routes Pattern:**
```typescript
// src/routes/livekit.routes.ts
import { Router, Request, Response } from 'express';
import { authenticate } from '../middleware/auth.js';
import { createLiveKitConfig, generateRoomToken } from '../config/livekit.js';

const router = Router();

// POST /api/v1/livekit/token
router.post('/token', authenticate, async (req: Request, res: Response) => {
  try {
    const { roomName, participantName, isAdmin = false } = req.body;
    const userId = (req as any).userId;

    if (!roomName || !participantName) {
      res.status(400).json({ error: 'roomName and participantName required' });
      return;
    }

    const config = createLiveKitConfig();
    const token = generateRoomToken(config, roomName, participantName, isAdmin);

    res.json({
      data: {
        token,
        roomName,
        wsUrl: config.wsUrl,
        rtcpUrl: config.rtcpUrl,
      },
    });
  } catch (err) {
    res.status(500).json({ error: 'Failed to generate LiveKit token' });
  }
});

export default router;
```

---

### `src/services/auth.service.ts` (service)

**Source:** RESEARCH.md: JWT Refresh Token Rotation pattern

**Auth Service Pattern:**
```typescript
// src/services/auth.service.ts
import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import { prisma } from '../config/database.js';
import { RedisClientType } from 'redis';
import { redisClient } from '../config/redis.js';

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = 7 * 24 * 60 * 60; // 7 days in seconds
const SALT_ROUNDS = 12;

export class AuthService {
  private jwtSecret: string;

  constructor() {
    this.jwtSecret = process.env.JWT_SECRET!;
  }

  async register(email: string, password: string, name?: string) {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) {
      throw new Error('Email already registered');
    }

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const user = await prisma.user.create({
      data: {
        email,
        passwordHash,
        name,
      },
    });

    const { accessToken, refreshToken } = await this.generateTokens(user.id);

    return {
      user: { id: user.id, email: user.email, name: user.name },
      accessToken,
      refreshToken,
    };
  }

  async login(email: string, password: string) {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash) {
      throw new Error('Invalid credentials');
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
      throw new Error('Invalid credentials');
    }

    const { accessToken, refreshToken } = await this.generateTokens(user.id);

    return {
      user: { id: user.id, email: user.email, name: user.name },
      accessToken,
      refreshToken,
    };
  }

  async generateTokens(userId: string): Promise<{ access: string; refresh: string }> {
    // Access token
    const accessToken = jwt.sign(
      { sub: userId, type: 'access' },
      this.jwtSecret,
      { expiresIn: ACCESS_TOKEN_TTL, algorithm: 'HS256' }
    );

    // Refresh token with jti for revocation
    const jti = crypto.randomUUID();
    const refreshToken = jwt.sign(
      { sub: userId, type: 'refresh', jti },
      this.jwtSecret,
      { expiresIn: REFRESH_TOKEN_TTL, algorithm: 'HS256' }
    );

    // Store jti in Redis with TTL for revocation capability
    await redisClient.setEx(
      `refresh:${userId}:${jti}`,
      REFRESH_TOKEN_TTL,
      'valid'
    );

    return { access: accessToken, refresh: refreshToken };
  }

  async refresh(refreshToken: string): Promise<{ access: string; refresh: string }> {
    try {
      const decoded = jwt.decode(refreshToken) as any;

      if (!decoded || decoded.type !== 'refresh') {
        throw new Error('Invalid token type');
      }

      // Check if token is blacklisted (revoked)
      const exists = await redisClient.get(`refresh:${decoded.sub}:${decoded.jti}`);
      if (!exists) {
        throw new Error('Refresh token revoked');
      }

      // Revoke old token
      await redisClient.del(`refresh:${decoded.sub}:${decoded.jti}`);

      // Issue new token pair
      return this.generateTokens(decoded.sub);
    } catch (err) {
      throw new Error('Invalid refresh token');
    }
  }

  async logout(userId: string, refreshToken?: string): Promise<void> {
    if (refreshToken) {
      try {
        const decoded = jwt.decode(refreshToken) as any;
        if (decoded && decoded.jti) {
          await redisClient.del(`refresh:${decoded.sub}:${decoded.jti}`);
        }
      } catch {
        // Ignore decode errors
      }
    } else {
      // Revoke all refresh tokens for user
      await this.revokeAllTokens(userId);
    }
  }

  private async revokeAllTokens(userId: string): Promise<void> {
    const pattern = `refresh:${userId}:*`;
    const keys = await redisClient.keys(pattern);
    if (keys.length > 0) {
      await redisClient.del(keys);
    }
  }

  async getUser(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        emailVerified: true,
      },
    });
    return user;
  }
}
```

---

### `src/services/user.service.ts` (service)

**Source:** RESEARCH.md: User profile management

**User Service Pattern:**
```typescript
// src/services/user.service.ts
import { prisma } from '../config/database.js';

export class UserService {
  async updateProfile(userId: string, data: { name?: string; avatarUrl?: string }) {
    const user = await prisma.user.update({
      where: { id: userId },
      data,
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
      },
    });
    return user;
  }

  async getProfile(userId: string) {
    const user = await prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        email: true,
        name: true,
        avatarUrl: true,
        createdAt: true,
      },
    });
    return user;
  }

  async deleteAccount(userId: string): Promise<void> {
    await prisma.user.delete({
      where: { id: userId },
    });
  }
}
```

---

### `src/services/notification.service.ts` (service)

**Source:** RESEARCH.md: Socket.io + FCM/APNs hybrid pattern

**Notification Service Pattern:**
```typescript
// src/services/notification.service.ts
import admin from 'firebase-admin';
import apn from 'node-apn';
import { Server as SocketIOServer } from 'socket.io';
import { prisma } from '../config/database.js';

export class NotificationService {
  private io: SocketIOServer;
  private fcm: admin.messaging.MessagingService;
  private apnClient: apn.Provider;

  constructor(
    io: SocketIOServer,
    fcm?: admin.messaging.MessagingService,
    apn?: apn.Provider
  ) {
    this.io = io;
    this.fcm = fcm!;
    this.apnClient = apn!;
  }

  async sendToUser(
    userId: string,
    payload: { title: string; body: string; type: string; data?: any }
  ): Promise<void> {
    // In-app via Socket.io
    this.io.to(`user:${userId}`).emit('notification', payload);

    // Push via FCM/APNs (query user's device tokens)
    const tokens = await this.getUserPushTokens(userId);

    if (tokens.fcm && tokens.fcm.length > 0) {
      await this.sendFCM(tokens.fcm, payload);
    }

    if (tokens.apn && tokens.apn.length > 0) {
      await this.sendAPNs(tokens.apn, payload);
    }
  }

  async broadcastSOS(userId: string, sosData: { location?: string; message?: string }): Promise<void> {
    // SOS gets highest priority
    const payload = {
      title: '🚨 SOS Alert',
      body: `User ${userId} triggered an emergency alert${sosData.location ? ` at ${sosData.location}` : ''}`,
      type: 'SOS',
      data: { userId, ...sosData },
      priority: 'critical',
    };

    // Send to all connected users (or emergency contacts only)
    this.io.emit('sos:alert', payload);

    // Also send push with critical priority
    // Implementation depends on emergency contacts list
  }

  private async getUserPushTokens(userId: string): Promise<{ fcm: string[]; apn: string[] }> {
    // Fetch from database - implement based on your user device table
    // For now, return empty arrays
    return { fcm: [], apn: [] };
  }

  private async sendFCM(tokens: string[], payload: any): Promise<void> {
    const message: admin.messaging.Message = {
      token: tokens[0], // For multiple, use tokens array
      notification: {
        title: payload.title,
        body: payload.body,
      },
      data: {
        type: payload.type,
        ...payload.data,
      },
      // High priority for SOS
      priority: payload.priority === 'critical' ? 'high' : 'normal',
      android: {
        priority: payload.priority === 'critical' ? 'high' : 'normal',
        notification: {
          color: payload.priority === 'critical' ? '#FF0000' : undefined,
        },
      },
      apns: {
        headers: {
          'apns-priority': payload.priority === 'critical' ? '10' : '5',
        },
      },
    };

    try {
      await this.fcm.send(message);
    } catch (err) {
      console.error('FCM send error:', err);
    }
  }

  private async sendAPNs(tokens: string[], payload: any): Promise<void> {
    const note = new apn.Notification();

    note.alert = {
      title: payload.title,
      body: payload.body,
    };

    note.payload = {
      type: payload.type,
      ...payload.data,
    };

    note.pushType = 'alert';
    note.priority = payload.priority === 'critical' ? 10 : 5;
    note.topic = process.env.APNS_TOPIC;

    try {
      await this.apnClient.send(note, tokens);
    } catch (err) {
      console.error('APNs send error:', err);
    }
  }
}
```

---

### `src/services/token.service.ts` (service)

**Source:** RESEARCH.md: JWT Refresh Token Rotation pattern

**Token Service Pattern:**
```typescript
// src/services/token.service.ts
import jwt from 'jsonwebtoken';
import { RedisClientType } from 'redis';
import { redisClient } from '../config/redis.js';

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = 7 * 24 * 60 * 60; // 7 days

export class TokenService {
  private jwtSecret: string;

  constructor() {
    this.jwtSecret = process.env.JWT_SECRET!;
  }

  async generateTokens(userId: string): Promise<{ access: string; refresh: string }> {
    const accessToken = jwt.sign(
      { sub: userId, type: 'access' },
      this.jwtSecret,
      { expiresIn: ACCESS_TOKEN_TTL, algorithm: 'HS256' }
    );

    const jti = crypto.randomUUID();
    const refreshToken = jwt.sign(
      { sub: userId, type: 'refresh', jti },
      this.jwtSecret,
      { expiresIn: REFRESH_TOKEN_TTL, algorithm: 'HS256' }
    );

    // Store jti in Redis with TTL
    await redisClient.setEx(
      `refresh:${userId}:${jti}`,
      REFRESH_TOKEN_TTL,
      'valid'
    );

    return { access: accessToken, refresh: refreshToken };
  }

  async rotateRefreshToken(oldRefreshToken: string): Promise<{ access: string; refresh: string }> {
    const decoded = jwt.decode(oldRefreshToken) as any;

    if (!decoded || decoded.type !== 'refresh') {
      throw new Error('Invalid token type');
    }

    // Verify old token hasn't been revoked
    const exists = await redisClient.get(`refresh:${decoded.sub}:${decoded.jti}`);
    if (!exists) {
      throw new Error('Refresh token revoked');
    }

    // Revoke old token
    await redisClient.del(`refresh:${decoded.sub}:${decoded.jti}`);

    // Issue new tokens
    return this.generateTokens(decoded.sub);
  }

  async revokeAllTokens(userId: string): Promise<void> {
    const pattern = `refresh:${userId}:*`;
    const keys = await redisClient.keys(pattern);
    if (keys.length > 0) {
      await redisClient.del(keys);
    }
  }

  verifyAccessToken(token: string): { sub: string; type: string } | null {
    try {
      const decoded = jwt.verify(token, this.jwtSecret) as any;
      return decoded;
    } catch {
      return null;
    }
  }
}
```

---

### `src/utils/logger.ts` (utility)

**Source:** RESEARCH.md: Logging convention

**Logger Pattern:**
```typescript
// src/utils/logger.ts
import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
      translateTime: 'SYS:standard',
      ignore: 'pid,hostname',
    },
  },
});

// Structured logging helpers
export const loggerWithContext = (context: string) => {
  return childLogger(childLogger, { context });
};

export const childLogger = (parent: typeof logger, additional: Record<string, any>) => {
  return parent.child(additional);
};

export { logger };
```

---

### `src/utils/validator.ts` (utility)

**Source:** RESEARCH.md: Zod validation pattern

**Validator Pattern:**
```typescript
// src/utils/validator.ts
import { validationResult, body } from 'express-validator';
import { Request, Response, NextFunction } from 'express';

export const validator = (req: Request, res: Response, next: NextFunction): void => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    res.status(400).json({
      error: 'Validation failed',
      details: errors.array(),
    });
    return;
  }
  next();
};

// Common validation rules
export const validationRules = {
  email: body('email').isEmail().normalizeEmail(),
  password: body('password').isLength({ min: 8 }),
  optionalString: (field: string) => body(field).optional().trim().isString(),
};
```

---

### `src/server.ts` (controller/bootstrap)

**Source:** RESEARCH.md: Express App with Socket.io and Health Checks

**Server Bootstrap Pattern:**
```typescript
// src/server.ts
import express from 'express';
import { createServer } from 'http';
import { NotificationService } from './services/notification.service.js';
import { setupSocket } from './config/socket.js';
import authRoutes from './routes/auth.routes.js';
import sttRoutes from './routes/stt.routes.js';
import ttsRoutes from './routes/tts.routes.js';
import notificationsRoutes from './routes/notifications.routes.js';
import livekitRoutes from './routes/livekit.routes.js';
import { errorHandler, notFoundHandler } from './middleware/errorHandler.js';
import { apiRateLimit } from './middleware/rateLimit.js';
import { redisHealthCheck } from './config/redis.js';
import { logger } from './utils/logger.js';

const app = express();
const server = createServer(app);

// Create notification service first for socket dependency
const notificationService = new NotificationService();

// Setup Socket.io
const io = setupSocket(server, notificationService);

// Middleware
app.use(express.json({ limit: '10mb' })); // audio uploads
app.use(express.urlencoded({ extended: true }));
app.use(apiRateLimit);

// CORS
app.use((req, res, next) => {
  const origin = process.env.CLIENT_ORIGIN || 'http://localhost:3000';
  res.header('Access-Control-Allow-Origin', origin);
  res.header('Access-Control-Allow-Credentials', 'true');
  res.header('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept, Authorization');
  if (req.method === 'OPTIONS') {
    return res.sendStatus(200);
  }
  next();
});

// Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/stt', sttRoutes);
app.use('/api/v1/tts', ttsRoutes);
app.use('/api/v1/notifications', notificationsRoutes);
app.use('/api/v1/livekit', livekitRoutes);

// Health check
app.get('/health', async (req, res) => {
  try {
    const db = await prisma.$queryRaw`SELECT 1`;
    const redis = await redisHealthCheck();
    res.json({
      status: 'healthy',
      timestamp: new Date().toISOString(),
      checks: { db: 'ok', redis },
    });
  } catch (err) {
    res.status(503).json({
      status: 'unhealthy',
      error: 'Health check failed',
    });
  }
});

// 404 handler
app.use('*', notFoundHandler);

// Error handler (must be last)
app.use(errorHandler);

const port = process.env.PORT || 3000;
server.listen(port, () => {
  logger.info(`Server listening on port ${port}`);
});

export { app, server, io };
```

---

### `docker-compose.yaml` (config)

**Source:** RESEARCH.md: Docker Compose for Full Stack

**Docker Compose Pattern:**
```yaml
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
      --language vi
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
      coqui-tts:
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
      USE_FALLBACK: ${USE_FALLBACK:-false}
      CLIENT_ORIGIN: ${CLIENT_ORIGIN:-http://localhost:3000}
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
```

---

### `Dockerfile` (config)

**Source:** RESEARCH.md best practices

**Dockerfile Pattern:**
```dockerfile
# Build stage
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package files
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies
RUN npm ci --only=production

# Copy source
COPY . .

# Generate Prisma client
RUN npx prisma generate

# Production stage
FROM node:22-alpine

WORKDIR /app

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init

# Copy dependencies and source
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/src ./src

# Generate Prisma client in final image
RUN npx prisma generate

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001

USER nodejs

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

CMD ["node", "dist/server.js"]
```

---

### `.env.example` (config)

**Source:** RESEARCH.md environment variables

**Environment Variables Pattern:**
```bash
# Database
POSTGRES_USER=vsl
POSTGRES_PASSWORD=change_this_in_production
POSTGRES_DB=vsl_bridge

# Redis
REDIS_URL=redis://redis:6379

# JWT
JWT_SECRET=generate_64+_char_random_secret_here

# STT Providers
STT_PROVIDER=groq                    # groq | local
GROQ_API_KEY=your_groq_api_key
USE_FALLBACK=false                   # Set to true to enable Whisper.cpp fallback
STT_FALLBACK_URL=http://whisper-server:8081/transcribe

# TTS Providers
TTS_PROVIDER=elevenlabs              # elevenlabs | local | veniru
ELEVENLABS_API_KEY=your_elevenlabs_key
TTS_FALLBACK_URL=http://coqui-tts:5002/api/tts

# LiveKit
LIVEKIT_API_KEY=your_livekit_api_key
LIVEKIT_API_SECRET=your_livekit_secret
LIVEKIT_WS_URL=ws://localhost:7880
LIVEKIT_RTC_URL=http://localhost:7880

# Push Notifications
FIREBASE_SERVICE_ACCOUNT=/run/secrets/firebase
APNS_CERT=/run/secrets/apns
APNS_TOPIC=com.yourcompany.vslbridge

# Client
CLIENT_ORIGIN=http://localhost:3000

# Server
NODE_ENV=production
PORT=3000
LOG_LEVEL=info
```

---

### `jest.config.ts` (test)

**Source:** RESEARCH.md: Test Framework configuration

**Jest Configuration Pattern:**
```typescript
// jest.config.ts
import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  testMatch: ['**/*.test.ts'],
  transform: {
    '^.+\\.tsx?$': ['ts-jest', {
      useESM: true,
    }],
  },
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/src/$1',
  },
  collectCoverageFrom: [
    'src/**/*.ts',
    '!src/**/*.d.ts',
  ],
  coverageDirectory: 'coverage',
  coverageReporters: ['text', 'lcov', 'html'],
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
  testTimeout: 30000,
  verbose: true,
};

export default config;
```

---

## Shared Patterns

### TypeScript Configuration

**Source:** RESEARCH.md: TypeScript best practices

```json
// tsconfig.json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "NodeNext",
    "moduleResolution": "NodeNext",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitOverride": true,
    "noPropertyAccessFromIndexSignature": true
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

---

### Import Conventions

All files must use explicit file extensions (.js, .ts) and relative imports:

```typescript
// CORRECT
import { prisma } from '../config/database.js';
import { Router } from 'express';

// INCORRECT (no extensions with NodeNext)
import { prisma } from '../config/database';
```

---

### Error Handling Convention

- Use `AppError` class for operational errors with status code
- Log all errors with structured data
- Never leak internal error details to clients
- Return consistent JSON format: `{ error: string, details?: any }`

---

### Logging Convention

- Use structured logging with pino
- Include context: `{ context, userId, action }`
- Log levels: `error` (exceptions), `warn` (recoverable), `info` (operations), `debug` (dev only)

---

### Database Access Pattern

- Always use Prisma's parameterized queries (automatic)
- Never concatenate user input into SQL
- Use transactions for multi-step operations:
```typescript
await prisma.$transaction(async (tx) => {
  await tx.user.create({ data });
  await tx.profile.create({ data });
});
```

---

### Environment Variable Naming

- Uppercase with underscores: `JWT_SECRET`, `DATABASE_URL`
- Boolean flags: `USE_FALLBACK`, `NODE_ENV`
- API keys: end with `_API_KEY` or `_SECRET`

---

## No Analog Found Notes

N/A - This is a greenfield project. All patterns sourced from RESEARCH.md as specified.

---

## Metadata

**Pattern source:** `.planning/phases/01-foundation-authentication/01-RESEARCH.md`
**Phase requirements covered:** ACC-01, ACC-02, ACC-03, NOTIF-01, NOTIF-02, COMM-02, COMM-03
**Architecture:** Monolithic Node.js REST API with Socket.io
**Deployment:** Docker Compose on single VPS
**Security:** JWT with refresh rotation, bcrypt 12+, rate limiting, Redis blacklist
