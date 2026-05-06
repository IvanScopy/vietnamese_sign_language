---
phase: 01-foundation-authentication
plan: 05B
type: execute
wave: 5
depends_on:
  - 05A
files_modified:
  - src/middleware/rateLimit.ts
  - src/utils/logger.ts
  - jest.config.ts
  - tests/setup.ts
  - tests/integration/api.test.ts
  - package.json
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
    - "Rate limiting applied to auth endpoints (5 attempts/15min per IP)"
    - "Rate limiting applied to STT/TTS endpoints (50 requests/hour)"
    - "Structured logger (pino) configured with appropriate log level"
    - "Jest configuration supports TypeScript ESM"
    - "Test database setup in tests/setup.ts"
    - "Integration tests cover happy path for auth and STT/TTS"
    - "All tests pass with npm test"
    - "package.json includes all required dependencies"
  artifacts:
    - path: "src/middleware/rateLimit.ts"
      provides: "Rate limiting middleware with Redis store"
      exports:
        - "authRateLimit (5/15min)"
        - "apiRateLimit (100/15min)"
        - "mlRateLimit (50/hour)"
    - path: "src/utils/logger.ts"
      provides: "Pino structured logger with child logger helper"
    - path: "jest.config.ts"
      provides: "Jest configuration for TypeScript ESM"
    - path: "tests/setup.ts"
      provides: "Test environment setup including database cleanup"
    - path: "tests/integration/api.test.ts"
      provides: "Integration tests for core API flows"
    - path: "package.json"
      provides: "Dependencies and npm scripts"
  key_links:
    - from: "src/server.ts"
      to: "src/middleware/rateLimit.ts"
      via: "app.use(apiRateLimit)"
    - from: "src/middleware/errorHandler.ts"
      to: "src/utils/logger.ts"
      via: "logger.error()"
---

<objective>
Middleware, Logging, Testing Infrastructure, and Dependencies

Purpose: Add rate limiting, structured logging, Jest test configuration, integration tests, and package.json. This completes the server with proper security, observability, and test coverage.

Output: Complete development and production configuration with test suite
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
@.planning/phases/01-foundation-authentication/01-05A-SERVER-BOOTSTRAP.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create rate limiting middleware with Redis store</name>
  <files>src/middleware/rateLimit.ts</files>
  <read_first>
  - src/config/redis.ts
  - .env.example
  </read_first>
  <action>Create rateLimit.ts:

import rateLimit from 'express-rate-limit';
import RedisStore from 'rate-limit-redis';
import { redisClient } from '../config/redis.js';

export const apiRateLimit = rateLimit({
  store: new RedisStore({ client: redisClient, prefix: 'rate-limit:' }),
  windowMs: 15 * 60 * 1000,
  max: 100,
  standardHeaders: true,
  legacyHeaders: false,
});

export const authRateLimit = rateLimit({
  store: new RedisStore({ client: redisClient, prefix: 'rate-limit-auth:' }),
  windowMs: 15 * 60 * 1000,
  max: 5,
  standardHeaders: true,
  legacyHeaders: false,
  skipSuccessfulRequests: true,
});

export const mlRateLimit = rateLimit({
  store: new RedisStore({ client: redisClient, prefix: 'rate-limit-ml:' }),
  windowMs: 60 * 60 * 1000,
  max: 50,
  standardHeaders: true,
  legacyHeaders: false,
});</action>
  <verify>
  - src/middleware/rateLimit.ts exists
  - grep -q "export const authRateLimit" src/middleware/rateLimit.ts
  - grep -q "export const apiRateLimit" src/middleware/rateLimit.ts
  - grep -q "export const mlRateLimit" src/middleware/rateLimit.ts
  - grep -q "RedisStore" src/middleware/rateLimit.ts
  - grep -q "windowMs.*15.*60.*1000" src/middleware/rateLimit.ts
  - grep -q "max: 5" src/middleware/rateLimit.ts
  - TypeScript compiles
  </verify>
  <done>Rate limiting middleware created with Redis store and appropriate limits per endpoint type</done>
</task>

<task type="auto">
  <name>Task 2: Create structured logger with pino</name>
  <files>src/utils/logger.ts</files>
  <action>Create logger.ts:

import pino from 'pino';

const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: process.env.NODE_ENV === 'development' ? {
    target: 'pino-pretty',
    options: { colorize: true, translateTime: 'SYS:standard', ignore: 'pid,hostname' },
  } : undefined,
});

export const childLogger = (parent = logger, additional: Record<string, any>) => {
  return parent.child(additional);
};

export { logger };</action>
  <verify>
  - src/utils/logger.ts exists
  - grep -q "import pino" src/utils/logger.ts
  - grep -q "export const logger" src/utils/logger.ts
  - grep -q "childLogger" src/utils/logger.ts
  - TypeScript compiles
  </verify>
  <done>Structured logger created with pino, development pretty-printing</done>
</task>

<task type="auto">
  <name>Task 3: Create Jest configuration and test setup</name>
  <files>
  jest.config.ts
  tests/setup.ts
  </files>
  <action>Create jest.config.ts:

import type { Config } from 'jest';

const config: Config = {
  preset: 'ts-jest/presets/default-esm',
  testEnvironment: 'node',
  roots: ['<rootDir>/tests'],
  moduleNameMapper: { '^@/(.*)$': '<rootDir>/src/$1' },
  transform: { '^.+\\.tsx?$': ['ts-jest', { useESM: true }] },
  testMatch: ['**/*.test.ts'],
  collectCoverageFrom: ['src/**/*.ts'],
  coverageDirectory: 'coverage',
  testTimeout: 30000,
  setupFilesAfterEnv: ['<rootDir>/tests/setup.ts'],
};

export default config;

Create tests/setup.ts:

import { beforeAll, afterAll } from '@jest/globals';
import { prisma } from '../src/config/database.js';
import { redisClient } from '../src/config/redis.js';

beforeAll(async () => {
  // Ensure clean test database state
});

afterAll(async () => {
  await prisma.$disconnect();
  await redisClient.quit();
});</action>
  <verify>
  - jest.config.ts exists with preset ts-jest
  - tests/setup.ts exists
  - npm test -- --passWithNoTests exits 0
  </verify>
  <done>Jest configured for TypeScript with ESM support and test environment setup</done>
</task>

<task type="auto">
  <name>Task 4: Create integration tests for core flows</name>
  <files>tests/integration/api.test.ts</files>
  <read_first>
  - src/server.ts
  - src/services/auth.service.ts
  </read_first>
  <action>Create integration tests:

import request from 'supertest';
import { app } from '../src/server.js';

describe('API Integration', () => {
  describe('POST /api/v1/auth/register', () => {
    it('creates new user and returns tokens', async () => {
      const res = await request(app)
        .post('/api/v1/auth/register')
        .send({ email: 'test@example.com', password: 'password123', name: 'Test', age: 25, userType: 'hearing' })
        .expect(201);
      expect(res.body).toHaveProperty('user.id');
      expect(res.body).toHaveProperty('tokens.access');
      expect(res.body).toHaveProperty('tokens.refresh');
    });
  });

  describe('POST /api/v1/auth/login', () => {
    it('authenticates existing user', async () => {
      await request(app)
        .post('/api/v1/auth/register')
        .send({ email: 'login@example.com', password: 'password123', name: 'Login Test', age: 30, userType: 'deaf' });

      const res = await request(app)
        .post('/api/v1/auth/login')
        .send({ email: 'login@example.com', password: 'password123' })
        .expect(200);
      expect(res.body).toHaveProperty('tokens.access');
    });
  });

  describe('GET /api/v1/auth/me', () => {
    it('returns user profile with valid token', async () => {
      const registerRes = await request(app)
        .post('/api/v1/auth/register')
        .send({ email: 'profile@example.com', password: 'password123', name: 'Profile Test', age: 20, userType: 'both' });
      const token = registerRes.body.tokens.access;

      const res = await request(app)
        .get('/api/v1/auth/me')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(res.body.email).toBe('profile@example.com');
    });
  });

  describe('POST /api/v1/auth/refresh', () => {
    it('issues new access token with refresh token', async () => {
      const registerRes = await request(app)
        .post('/api/v1/auth/register')
        .send({ email: 'refresh@example.com', password: 'password123', name: 'Refresh Test', age: 25, userType: 'hearing' });

      const res = await request(app)
        .post('/api/v1/auth/refresh')
        .send({ refreshToken: registerRes.body.tokens.refresh })
        .expect(200);
      expect(res.body).toHaveProperty('access');
      expect(res.body).toHaveProperty('refresh');
    });
  });

  describe('Health check', () => {
    it('returns 200 with status', async () => {
      const res = await request(app).get('/health').expect(200);
      expect(res.body).toHaveProperty('status');
    });
  });
});</action>
  <verify>
  - tests/integration/api.test.ts exists
  - grep -q "POST /api/v1/auth/register" tests/integration/api.test.ts
  - grep -q "POST /api/v1/auth/login" tests/integration/api.test.ts
  - grep -q "GET /api/v1/auth/me" tests/integration/api.test.ts
  - grep -q "/auth/refresh" tests/integration/api.test.ts
  - grep -q "/health" tests/integration/api.test.ts
  - npm test -- --passWithNoTests exits 0
  </verify>
  <done>Integration tests created for auth endpoints, refresh flow, and health check</done>
</task>

<task type="auto">
  <name>Task 5: Create package.json with all dependencies</name>
  <files>package.json</files>
  <action>Create package.json:

{
  "name": "vsl-backend",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "build": "tsc",
    "start": "node src/server.ts",
    "dev": "tsx watch src/server.ts",
    "prisma:generate": "prisma generate",
    "prisma:migrate": "prisma migrate dev",
    "prisma:studio": "prisma studio",
    "test": "jest",
    "test:coverage": "jest --coverage",
    "lint": "eslint src --ext .ts"
  },
  "dependencies": {
    "express": "4.21.1",
    "prisma": "latest",
    "@prisma/client": "latest",
    "jsonwebtoken": "9.0.2",
    "socket.io": "4.8.0",
    "bcrypt": "5.1.1",
    "cors": "2.8.5",
    "helmet": "7.5.0",
    "express-rate-limit": "7.5.0",
    "rate-limit-redis": "^3.0.1",
    "redis": "4.6.0",
    "passport": "0.7.0",
    "passport-google-oauth20": "2.0.0",
    "express-session": "1.18.0",
    "connect-pg-simple": "8.0.0",
    "zod": "3.24.2"
  },
  "devDependencies": {
    "typescript": "latest",
    "tsx": "latest",
    "@types/node": "latest",
    "@types/express": "latest",
    "@types/jsonwebtoken": "latest",
    "@types/bcrypt": "latest",
    "@types/cors": "latest",
    "jest": "latest",
    "ts-jest": "latest",
    "@types/jest": "latest",
    "supertest": "latest",
    "@types/supertest": "latest",
    "eslint": "latest",
    "@typescript-eslint/eslint-plugin": "latest",
    "@typescript-eslint/parser": "latest"
  }
}</action>
  <verify>
  - package.json exists
  - grep -q '"express": "4.21.1"' package.json
  - grep -q '"jsonwebtoken": "9.0.2"' package.json
  - grep -q '"socket.io": "4.8.0"' package.json
  - grep -q '"passport-google-oauth20"' package.json
  - grep -q '"test"' package.json
  - npm install completes without errors
  </verify>
  <done>package.json with all dependencies and scripts for build, test, and development</done>
</task>

</tasks>
