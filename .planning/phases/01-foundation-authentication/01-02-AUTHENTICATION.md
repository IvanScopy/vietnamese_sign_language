---
phase: 01-foundation-authentication
plan: 02
type: execute
wave: 2
depends_on:
  - 01
files_modified:
  - prisma/schema.prisma
  - src/config/database.ts
  - src/config/redis.ts
  - src/middleware/auth.ts
  - src/services/auth.service.ts
  - src/services/token.service.ts
  - src/services/user.service.ts
  - src/routes/auth.routes.ts
  - .env.example
autonomous: true
requirements:
  - ACC-01
  - ACC-02
  - ACC-03
must_haves:
  truths:
    - "New user can register with email/password and receives access token"
    - "Registered user can login with email/password and receives new tokens"
    - "User can logout and refresh token is invalidated"
    - "User can access their profile via /api/v1/auth/me"
    - "User can update their profile (name, age) via PUT /api/v1/auth/profile"
    - "Access token expires after 15 minutes"
    - "Refresh token rotation works and invalidates old token"
    - "Google OAuth redirects to Google and returns valid tokens"
    - "Multiple concurrent sessions allowed on different devices"
  artifacts:
    - path: "prisma/schema.prisma"
      provides: "Database schema for users, refresh tokens, conversations, messages"
      contains:
        - "model User {"
        - "model RefreshToken {"
    - path: "src/services/auth.service.ts"
      provides: "Registration, login, logout, Google OAuth flow"
    - path: "src/services/token.service.ts"
      provides: "JWT generation and refresh token rotation with Redis blacklist"
    - path: "src/middleware/auth.ts"
      provides: "JWT verification middleware for protected routes"
    - path: "src/routes/auth.routes.ts"
      provides: "All authentication endpoints under /api/v1/auth"
  key_links:
    - from: "src/routes/auth.routes.ts"
      to: "src/services/auth.service.ts"
      via: "authService.method calls in route handlers"
    - from: "src/middleware/auth.ts"
      to: "src/services/token.service.ts"
      via: "tokenService.verifyAccessToken in middleware"
---

<objective>
Authentication System (JWT + OAuth)

Purpose: Implement complete user authentication with email/password and Google OAuth, using JWT tokens with short-lived access (15min) and refresh token rotation (7 days). Profile management allows users to update name, age, and user type (deaf/hearing).

Output: Fully functional auth system with registration, login, logout, profile CRUD, and OAuth integration
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
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create Prisma schema with User, RefreshToken, Conversation, Message models</name>
  <files>prisma/schema.prisma</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Create complete Prisma schema from RESEARCH.md:

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
  conversations Conversation[]
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

model Conversation {
  id        String   @id @default(cuid())
  userId    String
  messages  Message[]
  createdAt DateTime @default(now())
  @@index([userId])
}

model Message {
  id             String   @id @default(cuid())
  conversationId String
  role           String
  content        String
  audioUrl       String?
  createdAt      DateTime @default(now())
  @@index([conversationId])
}

After creating schema, run: npx prisma generate</action>
  <verify>
  - grep -q "model User {" prisma/schema.prisma
  - grep -q "passwordHash" prisma/schema.prisma
  - grep -q "jti.*@unique" prisma/schema.prisma
  - grep -q "model RefreshToken {" prisma/schema.prisma
  - grep -q "userType.*String" prisma/schema.prisma
  - npx prisma validate passes
  </verify>
  <done>Prisma schema contains all required models with correct relationships and indexes</done>
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
  - grep -q "refresh:.*:.*:" src/services/token.service.ts
  - grep -q "ACCESS_TOKEN_TTL.*15m" src/services/token.service.ts
  - grep -q "REFRESH_TOKEN_TTL.*7" src/services/token.service.ts
  - TypeScript compiles: npx tsc --noEmit
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
  <name>Task 4: Implement src/services/auth.service.ts</name>
  <files>src/services/auth.service.ts</files>
  <read_first>
  - prisma/schema.prisma
  - src/services/token.service.ts
  </read_first>
  <action>Create auth.service.ts with bcrypt:

import bcrypt from 'bcrypt';
import { prisma } from '../config/database.js';
import { tokenService } from './token.service.js';

const SALT_ROUNDS = 12;

export class AuthService {
  async register(email: string, password: string, name: string, age: number, userType: 'deaf' | 'hearing' | 'both'): Promise<any> {
    const existing = await prisma.user.findUnique({ where: { email } });
    if (existing) throw new Error('User already exists');

    const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

    const user = await prisma.user.create({
      data: { email, passwordHash, name, age, userType }
    });

    const tokens = await tokenService.generateTokens(user.id);

    return { user: { id: user.id, email: user.email, name: user.name, age, userType }, tokens };
  }

  async login(email: string, password: string): Promise<any> {
    const user = await prisma.user.findUnique({ where: { email } });
    if (!user || !user.passwordHash) throw new Error('Invalid credentials');

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) throw new Error('Invalid credentials');

    const tokens = await tokenService.generateTokens(user.id);
    return { user: { id: user.id, email: user.email, name: user.name, age: user.age, userType: user.userType }, tokens };
  }

  async logout(userId: string): Promise<void> {
    await tokenService.revokeAllTokens(userId);
  }

  async getUser(userId: string): Promise<any> {
    const user = await prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new Error('User not found');
    return { id: user.id, email: user.email, name: user.name, age: user.age, userType: user.userType };
  }

  async updateProfile(userId: string, data: {name?: string; age?: number; userType?: string}): Promise<any> {
    const user = await prisma.user.update({
      where: { id: userId },
      data,
      select: { id: true, email: true, name: true, age: true, userType: true }
    });
    return user;
  }
}

export const authService = new AuthService();</action>
  <verify>
  - src/services/auth.service.ts exists
  - grep -q "async register" src/services/auth.service.ts
  - grep -q "async login" src/services/auth.service.ts
  - grep -q "bcrypt.hash" src/services/auth.service.ts
  - grep -q "bcrypt.compare" src/services/auth.service.ts
  - grep -q "prisma.user.create" src/services/auth.service.ts
  - TypeScript compiles
  </verify>
  <done>AuthService implements registration, login, logout, getUser, updateProfile with bcrypt password hashing</done>
</task>

<task type="auto">
  <name>Task 5: Implement src/routes/auth.routes.ts</name>
  <files>src/routes/auth.routes.ts</files>
  <read_first>
  - src/services/auth.service.ts
  - src/middleware/auth.ts
  </read_first>
  <action>Create Express router with all auth endpoints:

import { Router } from 'express';
import { authService } from '../services/auth.service.js';
import { authenticate, AuthRequest } from '../middleware/auth.js';

const router = Router();

router.post('/register', async (req, res) => {
  const { email, password, name, age, userType } = req.body;
  try {
    const result = await authService.register(email, password, name, age, userType);
    res.status(201).json(result);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

router.post('/login', async (req, res) => {
  const { email, password } = req.body;
  try {
    const result = await authService.login(email, password);
    res.json(result);
  } catch (err: any) {
    res.status(401).json({ error: err.message });
  }
});

router.post('/logout', authenticate, async (req: AuthRequest, res) => {
  await authService.logout(req.userId!);
  res.json({ success: true });
});

router.post('/refresh', async (req, res) => {
  const { refreshToken } = req.body;
  if (!refreshToken) return res.status(400).json({ error: 'Refresh token required' });
  try {
    const tokens = await authService['tokenService'].rotateRefreshToken(refreshToken);
    res.json(tokens);
  } catch (err: any) {
    res.status(401).json({ error: err.message });
  }
});

router.get('/me', authenticate, async (req: AuthRequest, res) => {
  try {
    const user = await authService.getUser(req.userId!);
    res.json(user);
  } catch (err: any) {
    res.status(404).json({ error: err.message });
  }
});

router.put('/profile', authenticate, async (req: AuthRequest, res) => {
  const { name, age, userType } = req.body;
  try {
    const user = await authService.updateProfile(req.userId!, { name, age, userType });
    res.json(user);
  } catch (err: any) {
    res.status(400).json({ error: err.message });
  }
});

export default router;</action>
  <verify>
  - src/routes/auth.routes.ts exists
  - grep -q "router.post('/register'" src/routes/auth.routes.ts
  - grep -q "router.post('/login'" src/routes/auth.routes.ts
  - grep -q "router.get('/me'" src/routes/auth.routes.ts
  - grep -q "router.put('/profile'" src/routes/auth.routes.ts
  - grep -q "authenticate" src/routes/auth.routes.ts
  - TypeScript compiles
  </verify>
  <done>All auth endpoints implemented with proper middleware and error handling</done>
</task>

<task type="auto">
  <name>Task 6: Create config files for database and Redis</name>
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
  <name>Task 7: Update .env.example with all required auth variables</name>
  <files>.env.example</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Ensure .env.example from Plan 01 includes:

# OAuth
GOOGLE_CLIENT_ID=
GOOGLE_CLIENT_SECRET=
GOOGLE_REDIRECT_URI=http://localhost:3000/api/v1/auth/oauth/google/callback

Add these lines if not present.</action>
  <verify>
  - grep -q "GOOGLE_CLIENT_ID" .env.example
  - grep -q "GOOGLE_CLIENT_SECRET" .env.example
  - grep -q "GOOGLE_REDIRECT_URI" .env.example
  </verify>
  <done>.env.example includes all OAuth environment variables</done>
</task>

</tasks>
