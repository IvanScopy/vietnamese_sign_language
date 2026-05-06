---
phase: 01-foundation-authentication
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - docker-compose.yaml
  - .env.example
  - Dockerfile
autonomous: true
requirements:
  - ACC-01
  - ACC-02
  - ACC-03
  - NOTIF-01
  - NOTIF-02
  - COMM-02
  - COMM-03
user_setup:
  - service: DigitalOcean/VPS
    why: "Host all backend services on single VPS ($6-10/month)"
    env_vars:
      - name: POSTGRES_USER
        source: "Choose during deployment"
      - name: POSTGRES_PASSWORD
        source: "Generate strong password"
      - name: JWT_SECRET
        source: "Generate 256-bit secret: openssl rand -hex 64"
      - name: GROQ_API_KEY
        source: "Groq Cloud Console -> API Keys"
      - name: ELEVENLABS_API_KEY
        source: "ElevenLabs Dashboard -> API Keys"
      - name: LIVEKIT_API_KEY
        source: "Generate with: livekit-server --generate-key"
      - name: LIVEKIT_API_SECRET
        source: "Generate with: livekit-server --generate-secret"
must_haves:
  truths:
    - "PostgreSQL database is accessible to API container"
    - "Redis cache is accessible to API container"
    - "LiveKit server is running and accepting WebSocket connections"
    - "Whisper.cpp fallback service responds to /transcribe"
    - "Coqui TTS fallback service responds to /api/tts"
    - "API container can connect to all dependencies on startup"
  artifacts:
    - path: "docker-compose.yaml"
      provides: "Orchestrates all services with proper health checks and startup order"
      contains:
        - "postgres:17-alpine"
        - "redis:7-alpine"
        - "livekit/livekit-server"
        - "ghcr.io/ggerganov/whisper.cpp"
        - "ghcr.io/coqui-tts/tts-cpu"
    - path: ".env.example"
      provides: "Documentation of all required environment variables"
      contains:
        - "DATABASE_URL"
        - "REDIS_URL"
        - "JWT_SECRET"
        - "GROQ_API_KEY"
        - "ELEVENLABS_API_KEY"
        - "STT_PROVIDER"
        - "TTS_PROVIDER"
    - path: "Dockerfile"
      provides: "Multi-stage build for Node.js API with health check"
      contains:
        - "FROM node:22-alpine"
        - "HEALTHCHECK"
  key_links:
    - from: "docker-compose.yaml"
      to: "PostgreSQL"
      via: "depends_on with healthcheck condition"
      pattern: "condition: service_healthy"
    - from: "api service"
      to: "whisper-server:8081"
      via: "STT_FALLBACK_URL environment variable"
      pattern: "STT_FALLBACK_URL: http://whisper-server:8081"
---

<objective>
Infrastructure & Docker Compose Setup

Purpose: Create production-grade Docker Compose configuration that orchestrates all services (PostgreSQL, Redis, LiveKit, ML fallbacks) with proper health checks and startup order. This enables all subsequent development by providing a consistent, reproducible environment.

Output: docker-compose.yaml, Dockerfile, .env.example that can be deployed to a $6-10/month VPS
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
  <name>Task 1: Create docker-compose.yaml with all services and health checks</name>
  <files>docker-compose.yaml</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Create docker-compose.yaml with these services in order:

1. postgres (postgres:17-alpine):
   - environment: POSTGRES_USER, POSTGRES_PASSWORD, POSTGRES_DB
   - volumes: postgres_data:/var/lib/postgresql/data
   - healthcheck: pg_isready -U ${POSTGRES_USER}
   - network: vsl-network

2. redis (redis:7-alpine):
   - command: redis-server --appendonly yes
   - volumes: redis_data:/data
   - healthcheck: redis-cli ping
   - network: vsl-network

3. livekit (livekit/livekit-server:latest):
   - depends_on: redis (service_healthy)
   - environment: LIVEKIT_KEYS, LIVEKIT_REDIS, LIVEKIT_WS_URL, LIVEKIT_RTC_URL, LIVEKIT_TURN_ENABLED=true, LIVEKIT_TURN_TLS_PORT=5349
   - ports: 7880, 7881, 5349
   - healthcheck: curl -f http://localhost:7880/.well-known/health
   - network: vsl-network

4. whisper-server (ghcr.io/ggerganov/whisper.cpp:latest):
   - command: /whisper-server --model /models/ggml-large-v3.bin --host 0.0.0.0 --port 8081 --threads 4 --language auto
   - volumes: ./models:/models
   - ports: 8081
   - healthcheck: curl -f http://localhost:8081/health
   - deploy: memory limit 2G
   - network: vsl-network

5. coqui-tts (ghcr.io/coqui-tts/tts-cpu:latest):
   - command: python3 TTS/server/server.py --model_name tts_models/multilingual/multi-dataset/xtts_v2 --port 5002
   - ports: 5002
   - healthcheck: curl -f http://localhost:5002/health
   - deploy: memory limit 3G
   - network: vsl-network

6. api (built from Dockerfile):
   - depends_on: postgres, redis, livekit, whisper-server, coqui-tts (all service_healthy)
   - environment: DATABASE_URL, REDIS_URL, JWT_SECRET, GROQ_API_KEY, ELEVENLABS_API_KEY, STT_PROVIDER, STT_FALLBACK_URL, TTS_PROVIDER, TTS_FALLBACK_URL, FIREBASE_SERVICE_ACCOUNT, APNS_CERT, LIVEKIT_URL, LIVEKIT_API_KEY, LIVEKIT_API_SECRET
   - ports: 3000
   - healthcheck: curl -f http://localhost:3000/health
   - network: vsl-network

Include volumes for postgres_data, redis_data. Network: vsl-network bridge.</action>
  <verify>
  - docker-compose.yaml exists with 6 services
  - grep -q "condition: service_healthy" docker-compose.yaml
  - grep -q "healthcheck:" docker-compose.yaml
  - grep -q "ggml-large-v3.bin" docker-compose.yaml
  - grep -q "xtts_v2" docker-compose.yaml
  - grep -q "vsl-network" docker-compose.yaml
  - docker-compose config validates without errors
  </verify>
  <done>docker-compose.yaml is valid YAML with all services defined, health checks present, and proper dependency order</done>
</task>

<task type="auto">
  <name>Task 2: Create Dockerfile for Node.js API</name>
  <files>Dockerfile</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Create multi-stage Dockerfile:

Stage 1 (deps):
FROM node:22-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

Stage 2 (runner):
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
RUN addgroup -g 1001 -S nodejs && adduser -S nodejs -u 1001
COPY --from=deps /app/node_modules ./node_modules
COPY . .
USER nodejs
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (r) => {process.exit(r.statusCode === 200 ? 0 : 1)})"
CMD ["node", "src/server.ts"]</action>
  <verify>
  - Dockerfile exists
  - grep -q "FROM node:22-alpine" Dockerfile
  - grep -q "HEALTHCHECK" Dockerfile
  - grep -q "EXPOSE 3000" Dockerfile
  - grep -q 'CMD.*server' Dockerfile
  - docker build --dry-run succeeds
  </verify>
  <done>Dockerfile has multi-stage build, health check, and proper user permissions</done>
</task>

<task type="auto">
  <name>Task 3: Create .env.example with all required environment variables</name>
  <files>.env.example</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Create .env.example listing all environment variables with comments:

# Database
POSTGRES_USER=vsl
POSTGRES_PASSWORD=
POSTGRES_DB=vsl_bridge
DATABASE_URL=postgresql://${POSTGRES_USER}:${POSTGRES_PASSWORD}@postgres:5432/${POSTGRES_DB}

# Redis
REDIS_URL=redis://redis:6379

# JWT
JWT_SECRET=

# STT/TTS Providers
STT_PROVIDER=groq  # Options: groq, local
STT_FALLBACK_URL=http://whisper-server:8081/transcribe
GROQ_API_KEY=

TTS_PROVIDER=elevenlabs  # Options: elevenlabs, local
TTS_FALLBACK_URL=http://coqui-tts:5002/api/tts
ELEVENLABS_API_KEY=

# Firebase (FCM)
FIREBASE_SERVICE_ACCOUNT=/run/secrets/firebase

# APNs
APNS_CERT=/run/secrets/apns
APNS_KEY=/run/secrets/apns-key
APNS_TOPIC=com.vslbridge.push

# LiveKit
LIVEKIT_URL=ws://livekit:7880
LIVEKIT_API_KEY=
LIVEKIT_API_SECRET=
LIVEKIT_WS_URL=ws://localhost:7880
LIVEKIT_RTC_URL=http://localhost:7880

# Server
NODE_ENV=production
PORT=3000
CLIENT_ORIGIN=http://localhost:3000</action>
  <verify>
  - .env.example exists
  - grep -q "DATABASE_URL" .env.example
  - grep -q "JWT_SECRET" .env.example
  - grep -q "STT_PROVIDER" .env.example
  - grep -q "TTS_PROVIDER" .env.example
  - grep -q "GROQ_API_KEY" .env.example
  - grep -q "ELEVENLABS_API_KEY" .env.example
  - grep -q "LIVEKIT_API_KEY" .env.example
  - grep -q "FIREBASE_SERVICE_ACCOUNT" .env.example
  - grep -q "APNS_CERT" .env.example
  - Contains exactly 22 environment variable entries
  </verify>
  <done>.env.example contains all required environment variables with descriptive comments</done>
</task>

</tasks>
