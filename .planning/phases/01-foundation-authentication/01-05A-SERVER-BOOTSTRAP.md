---
phase: 01-foundation-authentication
plan: 05A
type: execute
wave: 5
depends_on:
  - 01
  - 02B
  - 03
  - 04
files_modified:
  - src/server.ts
  - src/middleware/errorHandler.ts
  - src/utils/validator.ts
  - openapi.yaml
autonomous: true
requirements:
  - ACC-01
  - ACC-02
  - ACC-03
  - NOTIF-01
  - NOTIF-02
  - COMM-02
  - COMM-03
must_haves:
  truths:
    - "Server starts and binds to PORT from environment"
    - "All routes are mounted under /api/v1/ prefix"
    - "Health check returns 200 with db, redis, livekit status"
    - "CORS configured with CLIENT_ORIGIN"
    - "Helmet security headers enabled"
    - "Central error handler returns JSON with error type and message"
    - "Zod validation schemas exist for all request bodies"
    - "OpenAPI 3.0 schema documents all endpoints"
  artifacts:
    - path: "src/server.ts"
      provides: "Express app + Socket.io bootstrap with all middleware"
      contains:
        - "app.use('/api/v1/auth', authRoutes)"
        - "app.use('/api/v1/stt', sttRoutes)"
        - "app.use('/api/v1/tts', ttsRoutes)"
        - "app.use('/api/v1/notifications', notificationsRoutes)"
        - "app.use('/api/v1/livekit', livekitRoutes)"
        - "app.get('/health'"
    - path: "src/middleware/errorHandler.ts"
      provides: "Centralized error handling middleware returning JSON"
    - path: "src/utils/validator.ts"
      provides: "Zod schemas for request validation"
    - path: "openapi.yaml"
      provides: "OpenAPI 3.0 schema for API contract"
  key_links:
    - from: "src/server.ts"
      to: "all route modules"
      via: "app.use('/api/v1/...', routes)"
    - from: "src/server.ts"
      to: "src/middleware/errorHandler.ts"
      via: "app.use(errorHandler)"
---

<objective>
Server Bootstrap, Error Handling, Validation, and OpenAPI Schema

Purpose: Wire together all components into a complete running server. Add CORS, Helmet, central error handling, health checks for dependencies, and generate OpenAPI schema for API contract documentation.

Output: Production-ready server foundation with proper middleware stack and API documentation
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-foundation-authentication/01-CONTEXT.md
@.planning/phases/01-foundation-authentication/01-RESEARCH.md
@.planning/phases/01-foundation-authentication/01-PATTERNS.md
</context>

<interfaces>
From 02B (auth.routes):
```typescript
import authRoutes from '../routes/auth.routes.js';
// exports: Router with /register, /login, /logout, /refresh, /me, /profile
```

From 03 (stt/tts routes):
```typescript
import sttRoutes from '../routes/stt.routes.js';
import ttsRoutes from '../routes/tts.routes.js';
// exports: Router with /transcribe, /synthesize
```

From 04 (notifications/livekit routes):
```typescript
import notificationsRoutes from '../routes/notifications.routes.js';
import livekitRoutes from '../routes/livekit.routes.js';
// exports: Router with notification and LiveKit endpoints
```
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Create src/server.ts bootstrap with all middleware and routes</name>
  <files>src/server.ts</files>
  <read_first>
  - .env.example
  - src/config/database.ts
  - src/config/redis.ts
  - src/config/socket.ts
  - src/services/notification.service.ts
  </read_first>
  <action>Create server.ts:

import express from 'express';
import { createServer } from 'http';
import cors from 'cors';
import helmet from 'helmet';
import { prisma } from './config/database.js';
import { redisClient, redisHealthCheck } from './config/redis.js';
import { setupSocket } from './config/socket.js';
import { notificationService } from './services/notification.service.js';
import authRoutes from './routes/auth.routes.js';
import sttRoutes from './routes/stt.routes.js';
import ttsRoutes from './routes/tts.routes.js';
import notificationsRoutes from './routes/notifications.routes.js';
import livekitRoutes from './routes/livekit.routes.js';
import { errorHandler } from './middleware/errorHandler.js';

const app = express();
const server = createServer(app);

notificationService.io = setupSocket(server, notificationService);

app.use(cors({ origin: process.env.CLIENT_ORIGIN || '*', credentials: true }));
app.use(helmet());
app.use(express.json({ limit: '10mb' }));

app.use('/api/v1/auth', authRoutes);
app.use('/api/v1/stt', sttRoutes);
app.use('/api/v1/tts', ttsRoutes);
app.use('/api/v1/notifications', notificationsRoutes);
app.use('/api/v1/livekit', livekitRoutes);

app.get('/health', async (req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
    const redisOk = await redisHealthCheck();
    const livekitUrl = process.env.LIVEKIT_URL;
    const livekitOk = livekitUrl ? await fetch(livekitUrl + '/.well-known/health').then(r => r.ok).catch(() => false) : true;

    const status = redisOk && livekitOk ? 'ok' : 'degraded';
    res.status(redisOk && livekitOk ? 200 : 503).json({
      status,
      timestamp: new Date().toISOString(),
      checks: { db: 'ok', redis: redisOk ? 'ok' : 'error', livekit: livekitOk ? 'ok' : 'error' },
    });
  } catch (err) {
    res.status(503).json({ status: 'error', error: String(err) });
  }
});

app.use(errorHandler);

const port = parseInt(process.env.PORT || '3000', 10);
server.listen(port, () => console.log(`Server listening on port ${port}`));

export { app, server };</action>
  <verify>
  - src/server.ts exists
  - grep -q "app.use('/api/v1/auth" src/server.ts
  - grep -q "app.get('/health'" src/server.ts
  - grep -q "setupSocket" src/server.ts
  - grep -q "cors(" src/server.ts
  - grep -q "helmet()" src/server.ts
  - grep -q "errorHandler" src/server.ts
  - npx tsc --noEmit passes
  </verify>
  <done>Server bootstrap complete with all routes, middleware, health check, and error handling</done>
</task>

<task type="auto">
  <name>Task 2: Create error handler middleware</name>
  <files>src/middleware/errorHandler.ts</files>
  <read_first>
  - src/server.ts
  </read_first>
  <action>Create centralized error handler:

import { Request, Response, NextFunction } from 'express';

export function errorHandler(err: Error, req: Request, res: Response, next: NextFunction): void {
  console.error(err.stack);
  const status = err instanceof SyntaxError ? 400 : 500;
  res.status(status).json({
    error: err.name || 'Error',
    message: err.message,
  });
}</action>
  <verify>
  - src/middleware/errorHandler.ts exists
  - grep -q "export function errorHandler" src/middleware/errorHandler.ts
  - grep -q "res.status" src/middleware/errorHandler.ts
  - TypeScript compiles
  </verify>
  <done>Error handler middleware created for consistent JSON error responses</done>
</task>

<task type="auto">
  <name>Task 3: Create Zod validator schemas</name>
  <files>src/utils/validator.ts</files>
  <action>Create validator.ts with Zod schemas:

import { z } from 'zod';

export const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
  name: z.string().min(1),
  age: z.number().int().positive(),
  userType: z.enum(['deaf', 'hearing', 'both']),
});

export const loginSchema = z.object({
  email: z.string().email(),
  password: z.string(),
});

export const profileSchema = z.object({
  name: z.string().min(1).optional(),
  age: z.number().int().positive().optional(),
  userType: z.enum(['deaf', 'hearing', 'both']).optional(),
});

export const sttSchema = z.object({
  audio: z.string().min(1),
  language: z.string().default('vi'),
});

export const ttsSchema = z.object({
  text: z.string().min(1),
  language: z.string().default('vi'),
});

export const refreshSchema = z.object({
  refreshToken: z.string().min(1),
});</action>
  <verify>
  - src/utils/validator.ts exists
  - grep -q "export const registerSchema" src/utils/validator.ts
  - grep -q "z.object" src/utils/validator.ts
  - grep -q "z.string().email()" src/utils/validator.ts
  - grep -q "z.enum" src/utils/validator.ts
  - TypeScript compiles
  </verify>
  <done>Zod validation schemas created for all request bodies</done>
</task>

<task type="auto">
  <name>Task 4: Create OpenAPI schema</name>
  <files>openapi.yaml</files>
  <action>Create OpenAPI 3.0 schema:

openapi: 3.0.3
info:
  title: VSL Bridge API
  version: 1.0.0
  description: Backend API for Vietnamese Sign Language Bridge

servers:
  - url: /api/v1

paths:
  /health:
    get:
      summary: Health check
      responses:
        '200':
          description: All services healthy
          content:
            application/json:
              schema:
                type: object
                properties:
                  status: { type: string }
                  timestamp: { type: string }
                  checks:
                    type: object
                    properties:
                      db: { type: string }
                      redis: { type: string }
                      livekit: { type: string }

  /auth/register:
    post:
      summary: Register new user
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/RegisterRequest'
      responses:
        '201':
          description: User created

  /auth/login:
    post:
      summary: Login with email/password
      requestBody:
        required: true
        content:
          application/json:
            schema:
              $ref: '#/components/schemas/LoginRequest'

  /auth/refresh:
    post:
      summary: Refresh access token
      requestBody:
        required: true
        content:
          application/json:
            schema:
              type: object
              properties:
                refreshToken: { type: string }

  /auth/me:
    get:
      summary: Get current user profile
      security:
        - bearerAuth: []

  /auth/profile:
    put:
      summary: Update profile
      security:
        - bearerAuth: []

  /auth/oauth/google:
    get:
      summary: Initiate Google OAuth
      responses:
        '302':
          description: Redirect to Google

  /auth/oauth/google/callback:
    get:
      summary: Google OAuth callback
      responses:
        '302':
          description: Redirect with tokens

  /stt/transcribe:
    post:
      summary: Speech-to-text transcription
      security:
        - bearerAuth: []

  /tts/synthesize:
    post:
      summary: Text-to-speech synthesis
      security:
        - bearerAuth: []

  /notifications/register-token:
    post:
      summary: Register push notification token
      security:
        - bearerAuth: []

  /notifications/send:
    post:
      summary: Send notification to user
      security:
        - bearerAuth: []

  /notifications/sos:
    post:
      summary: Trigger SOS alert
      security:
        - bearerAuth: []

  /livekit/token:
    get:
      summary: Get LiveKit token
      security:
        - bearerAuth: []

  /livekit/room/create:
    post:
      summary: Create LiveKit room
      security:
        - bearerAuth: []

components:
  schemas:
    RegisterRequest:
      type: object
      required: [email, password, name, age, userType]
      properties:
        email: { type: string, format: email }
        password: { type: string, minLength: 8 }
        name: { type: string }
        age: { type: integer, minimum: 1 }
        userType: { type: string, enum: [deaf, hearing, both] }
    LoginRequest:
      type: object
      required: [email, password]
      properties:
        email: { type: string, format: email }
        password: { type: string }
    AuthResponse:
      type: object
      properties:
        user: { $ref: '#/components/schemas/User' }
        tokens: { $ref: '#/components/schemas/Tokens' }
    User:
      type: object
      properties:
        id: { type: string }
        email: { type: string }
        name: { type: string }
        age: { type: integer }
        userType: { type: string }
    Tokens:
      type: object
      properties:
        access: { type: string }
        refresh: { type: string }
    ProfileUpdate:
      type: object
      properties:
        name: { type: string }
        age: { type: integer }
        userType: { type: string, enum: [deaf, hearing, both] }
    STTRequest:
      type: object
      required: [audio]
      properties:
        audio: { type: string, format: base64 }
        language: { type: string, default: 'vi' }
    TTSRequest:
      type: object
      required: [text]
      properties:
        text: { type: string }
        language: { type: string, default: 'vi' }

  securitySchemes:
    bearerAuth:
      type: http
      scheme: bearer
      bearerFormat: JWT</action>
  <verify>
  - openapi.yaml exists
  - grep -q "openapi: 3.0" openapi.yaml
  - grep -q "/auth/register" openapi.yaml
  - grep -q "/stt/transcribe" openapi.yaml
  - grep -q "/tts/synthesize" openapi.yaml
  - grep -q "/health" openapi.yaml
  - grep -q "bearerAuth" openapi.yaml
  - YAML parses correctly
  </verify>
  <done>OpenAPI schema documents all endpoints with request/response schemas</done>
</task>

</tasks>
