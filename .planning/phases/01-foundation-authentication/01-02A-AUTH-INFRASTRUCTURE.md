---
phase: 01-foundation-authentication
plan: 02A
type: execute
wave: 2
depends_on:
  - 01
files_modified:
  - prisma/schema.prisma
  - src/config/database.ts
  - src/config/redis.ts
  - src/middleware/auth.ts
  - src/services/token.service.ts
  - .env.example
autonomous: true
requirements:
  - ACC-01
  - ACC-02
  - ACC-03
must_haves:
  truths:
    - "Prisma schema defines User, RefreshToken with correct relationships and indexes"
    - "Database and Redis config files create singleton clients with proper connection management"
    - "Token service implements JWT generation (15min access, 7day refresh) with Redis blacklist"
    - "JWT middleware validates tokens and attaches userId to request"
    - "Google OAuth environment variables documented in .env.example"
  artifacts:
    - path: "prisma/schema.prisma"
      provides: "Database schema for users and refresh tokens"
      contains:
        - "model User {"
        - "model RefreshToken {"
        - "jti String @unique"
    - path: "src/config/database.ts"
      provides: "PrismaClient singleton with development logging"
    - path: "src/config/redis.ts"
      provides: "Redis client with health check utility"
    - path: "src/middleware/auth.ts"
      provides: "JWT verification middleware (authenticate)"
    - path: "src/services/token.service.ts"
      provides: "JWT generation, rotation, and revocation via Redis blacklist"
  key_links:
    - from: "src/middleware/auth.ts"
      to: "src/services/token.service.ts"
      via: "tokenService.verifyAccessToken()"
    - from: "src/services/token.service.ts"
      to: "prisma/schema.prisma"
      via: "refresh token jti storage pattern matches schema"
---

<objective>
Authentication Infrastructure (Database, Tokens, Middleware)

Purpose: Establish the authentication foundation: Prisma schema with User and RefreshToken models, database/Redis configuration, JWT token service with rotation and revocation, and authentication middleware. This infrastructure enables the application logic in 02B.

Output: Complete auth infrastructure ready for OAuth and profile management
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

<tasks>

<task type="auto">
  <name>Task 1: Create Prisma schema with User and RefreshToken models</name>
  <files>prisma/schema.prisma</files>
  <action>Create complete Prisma schema:

generator client { provider = "prisma-client-js" }
datasource db { provider = "postgresql" url = env("DATABASE_URL") }

model User {
  id            String    @id @default(cuid())
  email         String    @unique
  emailVerified DateTime?
  passwordHash  String?
  googleId      String?   @unique
  name          String?
  age           Int?
  userType      String?
  avatarUrl     String?
  createdAt     DateTime  @default(now())
  updatedAt     DateTime  @updatedAt
  refreshTokens RefreshToken[]
}

model RefreshToken {
  id        String   @id @default(cuid())
  userId    String
  jti       String   @unique
  expiresAt DateTime
  user      User     @relation(fields: [userId], references: [id])
  @@index([userId])
  @@index([expiresAt])
}

After creating schema, run: npx prisma generate</action>
  <verify>
  - grep -q "model User {" prisma/schema.prisma
  - grep -q "passwordHash" prisma/schema.prisma
  - grep -q "jti.*@unique" prisma/schema.prisma
  - grep -q "model RefreshToken {" prisma/schema.prisma
  - npx prisma validate passes
  </verify>
  <done>Prisma schema contains User and RefreshToken models with correct relationships</done>
</task>

<task type="auto">
  <name>Task 2: Implement src/services/token.service.ts</name>
  <files>src/services/token.service.ts</files>
  <read_first>
  - prisma/schema.prisma
  - .env.example
  </read_first>
  <action>Create token.service.ts with JWT generation and rotation:

import jwt from 'jsonwebtoken';
import { redisClient } from '../config/redis.js';

const ACCESS_TOKEN_TTL = '15m';
const REFRESH_TOKEN_TTL = 7 * 24 * 60 * 60;

export class TokenService {
  private jwtSecret: string;

  constructor() {
    this.jwtSecret = process.env.JWT_SECRET!;
    if (!this.jwtSecret) throw new Error('JWT_SECRET not set');
  }

  async generateTokens(userId: string): Promise<{access: string; refresh: string}> {
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

    await redisClient.setEx(`refresh:${userId}:${jti}`, REFRESH_TOKEN_TTL, 'valid');

    return { access: accessToken, refresh: refreshToken };
  }

  async rotateRefreshToken(oldRefreshToken: string): Promise<{access: string; refresh: string}> {
    const decoded = jwt.decode(oldRefreshToken) as any;
    if (!decoded || decoded.type !== 'refresh') throw new Error('Invalid refresh token');

    const exists = await redisClient.get(`refresh:${decoded.sub}:${decoded.jti}`);
    if (!exists) throw new Error('Refresh token revoked');

    await redisClient.del(`refresh:${decoded.sub}:${decoded.jti}`);
    return this.generateTokens(decoded.sub);
  }

  verifyAccessToken(token: string): { sub: string; type: string } {
    return jwt.verify(token, this.jwtSecret, { algorithms: ['HS256'] }) as any;
  }

  async revokeAllTokens(userId: string): Promise<void> {
    const pattern = `refresh:${userId}:*`;
    const keys = await redisClient.keys(pattern);
    if (keys.length) await redisClient.del(keys);
  }
}

export const tokenService = new TokenService();</action>
  <verify>
  - src/services/token.service.ts exists
  - grep -q "generateTokens" src/services/token.service.ts
  - grep -q "rotateRefreshToken" src/services/token.service.ts
  - grep -q "ACCESS_TOKEN_TTL.*15m" src/services/token.service.ts
  - grep -q "REFRESH_TOKEN_TTL.*7" src/services/token.service.ts
  - TypeScript compiles
  </verify>
  <done>TokenService implements JWT generation, rotation, and Redis blacklist revocation</done>
</task>

<task type="auto">
  <name>Task 3: Implement src/middleware/auth.ts JWT middleware</name>
  <files>src/middleware/auth.ts</files>
  <read_first>
  - src/services/token.service.ts
  </read_first>
  <action>Create JWT authentication middleware:

import { Request, Response, NextFunction } from 'express';
import { tokenService } from '../services/token.service.js';

export interface AuthRequest extends Request {
  userId?: string;
}

export function authenticate(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers.authorization;
  if (!authHeader?.startsWith('Bearer ')) {
    res.status(401).json({ error: 'No token provided' });
    return;
  }

  const token = authHeader.substring(7);

  try {
    const decoded = tokenService.verifyAccessToken(token);
    req.userId = decoded.sub;
    next();
  } catch {
    res.status(401).json({ error: 'Invalid or expired token' });
  }
}</action>
  <verify>
  - src/middleware/auth.ts exists
  - grep -q "export function authenticate" src/middleware/auth.ts
  - grep -q "AuthRequest.*extends Request" src/middleware/auth.ts
  - grep -q "req.userId" src/middleware/auth.ts
  - grep -q "verifyAccessToken" src/middleware/auth.ts
  - TypeScript compiles
  </verify>
  <done>authenticate middleware validates JWT and sets req.userId</done>
</task>

<task type="auto">
  <name>Task 4: Create database and Redis config files</name>
  <files>
  src/config/database.ts
  src/config/redis.ts
  </files>
  <read_first>
  - .env.example
  </read_first>
  <action>Create src/config/database.ts:

import { PrismaClient } from '@prisma/client';

const globalForPrisma = globalThis as unknown as { prisma: PrismaClient | undefined };

export const prisma = globalForPrisma.prisma ?? new PrismaClient();

if (process.env.NODE_ENV !== 'production') globalForPrisma.prisma = prisma;

Create src/config/redis.ts:

import { createClient, RedisClientType } from 'redis';

const redisUrl = process.env.REDIS_URL || 'redis://localhost:6379';

export const redisClient: RedisClientType = createClient({ url: redisUrl });

redisClient.on('error', (err) => console.error('Redis Client Error:', err));
redisClient.on('connect', () => console.log('Redis client connected'));

redisClient.connect().catch(console.error);

export async function redisHealthCheck(): Promise<boolean> {
  try { await redisClient.ping(); return true; } catch { return false; }
}</action>
  <verify>
  - src/config/database.ts exists with PrismaClient singleton
  - src/config/redis.ts exists with redisClient and connect()
  - grep -q "PrismaClient" src/config/database.ts
  - grep -q "createClient" src/config/redis.ts
  - TypeScript compiles
  </verify>
  <done>Database and Redis config files created with proper connection management</done>
</task>

<task type="auto">
  <name>Task 5: Update .env.example with OAuth variables</name>
  <files>.env.example</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Ensure .env.example includes OAuth variables (add if missing):

# OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://localhost:3000/api/v1/auth/oauth/google/callback</action>
  <verify>
  - grep -q "GOOGLE_CLIENT_ID" .env.example
  - grep -q "GOOGLE_CLIENT_SECRET" .env.example
  - grep -q "GOOGLE_REDIRECT_URI" .env.example
  </verify>
  <done>.env.example includes all OAuth environment variables</done>
</task>

</tasks>
