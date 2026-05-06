---
phase: 01-foundation-authentication
plan: 02B
type: execute
wave: 2
depends_on:
  - 02A
files_modified:
  - src/services/auth.service.ts
  - src/routes/auth.routes.ts
  - src/routes/oauth.routes.ts
  - src/middleware/passport.ts
autonomous: true
requirements:
  - ACC-01
  - ACC-02
  - ACC-03
must_haves:
  truths:
    - "New user can register with email/password and receives access+refresh tokens"
    - "Registered user can login with email/password"
    - "User can logout (refresh tokens invalidated in Redis)"
    - "User can access their profile via GET /api/v1/auth/me"
    - "User can update profile (name, age) via PUT /api/v1/auth/profile"
    - "Google OAuth redirects to Google and returns valid tokens on callback"
    - "Existing OAuth users can link their Google account"
    - "Multiple concurrent sessions allowed on different devices"
  artifacts:
    - path: "src/services/auth.service.ts"
      provides: "Registration, login, logout, profile management, OAuth user linking"
      exports:
        - "class AuthService"
        - "register(email, password, name, age, userType)"
        - "login(email, password)"
        - "logout(userId)"
        - "getUser(userId)"
        - "updateProfile(userId, data)"
        - "linkGoogleAccount(userId, googleId)"
    - path: "src/routes/auth.routes.ts"
      provides: "Auth endpoints: /register, /login, /logout, /refresh, /me, /profile"
    - path: "src/routes/oauth.routes.ts"
      provides: "OAuth endpoints: /oauth/google, /oauth/google/callback"
    - path: "src/middleware/passport.ts"
      provides: "Passport.js Google OAuth strategy configuration"
  key_links:
    - from: "src/routes/auth.routes.ts"
      to: "src/services/auth.service.ts"
      via: "authService.method() calls"
    - from: "src/routes/oauth.routes.ts"
      to: "src/middleware/passport.ts"
      via: "passport.authenticate() middleware"
    - from: "src/services/auth.service.ts"
      to: "src/services/token.service.ts"
      via: "tokenService.generateTokens()"
---

<objective>
Authentication Application Logic + OAuth

Purpose: Implement the application layer for authentication: email/password registration/login, profile management, token refresh, and Google OAuth integration using passport-google-oauth20. OAuth users are linked to existing accounts or created as new users.

Output: Complete auth system with email/password and Google OAuth, fulfilling ACC-01, ACC-02, ACC-03 requirements
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
@.planning/phases/01-foundation-authentication/01-02A-AUTH-INFRASTRUCTURE.md
</context>

<interfaces>
From src/middleware/auth.ts (created in 02A):
```typescript
export interface AuthRequest extends Request {
  userId?: string;
}
export function authenticate(req: AuthRequest, res: Response, next: NextFunction): void;
```

From src/services/token.service.ts (created in 02A):
```typescript
export class TokenService {
  generateTokens(userId: string): Promise<{access: string; refresh: string}>;
  rotateRefreshToken(oldRefreshToken: string): Promise<{access: string; refresh: string}>;
  verifyAccessToken(token: string): { sub: string; type: string };
  revokeAllTokens(userId: string): Promise<void>;
}
export const tokenService: TokenService;
```
</interfaces>

<tasks>

<task type="auto">
  <name>Task 1: Implement AuthService with bcrypt</name>
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

  async linkGoogleAccount(userId: string, googleId: string): Promise<void> {
    await prisma.user.update({
      where: { id: userId },
      data: { googleId }
    });
  }

  async findUserByGoogleId(googleId: string): Promise<any> {
    return await prisma.user.findUnique({ where: { googleId } });
  }

  async findUserByEmail(email: string): Promise<any> {
    return await prisma.user.findUnique({ where: { email } });
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
  - grep -q "linkGoogleAccount" src/services/auth.service.ts
  - grep -q "findUserByGoogleId" src/services/auth.service.ts
  - TypeScript compiles
  </verify>
  <done>AuthService implements registration, login, logout, profile CRUD, and OAuth linking</done>
</task>

<task type="auto">
  <name>Task 2: Create auth routes (email/password)</name>
  <files>src/routes/auth.routes.ts</files>
  <read_first>
  - src/services/auth.service.ts
  - src/middleware/auth.ts
  </read_first>
  <action>Create Express router with auth endpoints:

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
    const tokens = await tokenService.rotateRefreshToken(refreshToken);
    res.json({ access: tokens.access, refresh: tokens.refresh });
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
  <name>Task 3: Create Passport Google OAuth strategy</name>
  <files>src/middleware/passport.ts</files>
  <read_first>
  - .env.example
  - src/services/auth.service.ts
  </read_first>
  <action>Create Google OAuth strategy using passport-google-oauth20:

import passport from 'passport';
import { Strategy, StrategyOptions, VerifyFunction } from 'passport-google-oauth20';
import { authService } from '../services/auth.service.js';

const strategyOptions: StrategyOptions = {
  clientID: process.env.GOOGLE_CLIENT_ID!,
  clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
  callbackURL: '/api/v1/auth/oauth/google/callback',
};

const verifyFn: VerifyFunction = async (accessToken, refreshToken, profile, done) => {
  try {
    // Find existing OAuth user
    let user = await authService.findUserByGoogleId(profile.id);

    if (!user) {
      // Check if email already registered with password
      user = await authService.findUserByEmail(profile.emails[0].value);

      if (user) {
        // Link existing account to Google
        await authService.linkGoogleAccount(user.id, profile.id);
      } else {
        // Create new OAuth user (no password)
        const { id, ...userData } = await prisma.user.create({
          data: {
            googleId: profile.id,
            email: profile.emails[0].value,
            name: profile.displayName,
            userType: 'hearing', // default, user can update later
          },
        });
        user = { id, ...userData };
      }
    }

    const { accessToken: jwtAccess, refreshToken: jwtRefresh } = await tokenService.generateTokens(user.id);

    return done(null, { ...user, tokens: { access: jwtAccess, refresh: jwtRefresh } });
  } catch (err) {
    return done(err as Error, null);
  }
};

passport.use(new Strategy(strategyOptions, verifyFn));

export { passport };</action>
  <verify>
  - src/middleware/passport.ts exists
  - grep -q "passport.use" src/middleware/passport.ts
  - grep -q "passport-google-oauth20" src/middleware/passport.ts (import)
  - grep -q "GOOGLE_CLIENT_ID" src/middleware/passport.ts
  - grep -q "callbackURL" src/middleware/passport.ts
  - grep -q "linkGoogleAccount" src/middleware/passport.ts
  - grep -q "tokenService.generateTokens" src/middleware/passport.ts
  - TypeScript compiles
  </verify>
  <done>Passport Google OAuth strategy configured with user linking and token generation</done>
</task>

<task type="auto">
  <name>Task 4: Create OAuth routes</name>
  <files>src/routes/oauth.routes.ts</files>
  <read_first>
  - src/middleware/passport.ts
  </read_first>
  <action>Create OAuth routes:

import { Router } from 'express';
import { passport } from '../middleware/passport.js';

const router = Router();

// Initiate OAuth flow
router.get('/google', passport.authenticate('google', { scope: ['profile', 'email'] }));

// OAuth callback
router.get('/google/callback',
  passport.authenticate('google', { session: false }),
  (req, res) => {
    // passport sets user on req (need to extract from result)
    const user = (req as any).user;
    if (!user) return res.status(401).json({ error: 'OAuth failed' });
    res.redirect(`/auth/success?access=${user.tokens.access}&refresh=${user.tokens.refresh}`);
  }
);

export default router;</action>
  <verify>
  - src/routes/oauth.routes.ts exists
  - grep -q "router.get('/google'" src/routes/oauth.routes.ts
  - grep -q "router.get('/google/callback'" src/routes/oauth.routes.ts
  - grep -q "passport.authenticate" src/routes/oauth.routes.ts
  - grep -q "scope:.*profile.*email" src/routes/oauth.routes.ts
  - TypeScript compiles
  </verify>
  <done>OAuth routes for Google authentication with redirect and callback</done>
</task>

</tasks>
