# Phase 1: Foundation & Authentication - Context

**Gathered:** 2026-05-05
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the backend foundation and core infrastructure:
- User authentication system (registration, login, session management)
- Vietnamese STT/TTS services with provider abstraction
- Real-time notification infrastructure for video calls and SOS
- API design and deployment infrastructure on a single VPS

The phase enables subsequent phases (sign recognition, communication features, video calling) by providing stable, well-designed foundational services.

</domain>

<decisions>
## Implementation Decisions

### STT/TTS Vietnamese Services

**Architecture:** Strategy pattern with provider abstraction layer
- STT providers: Groq Whisper (cloud primary) / Whisper.cpp (self-hosted fallback)
- TTS providers: ElevenLabs/Google TTS (cloud primary) / Coqui TTS (self-hosted fallback) / VieNeu-TTS (to research)
- Configuration via environment variables: `STT_PROVIDER=groq|local`, `TTS_PROVIDER=elevenlabs|local|vieneu`
- Latency targets: <500ms for both STT and TTS
- Fallback mechanism: Automatic provider switching on failure
- Accuracy prioritized over open-source preference — evaluate quality during implementation

**Note:** VieNeu-TTS mentioned as potential Vietnamese TTS option — research during planning phase.

### Authentication & Session Management

**Token strategy:** JWT (stateless)
- Access tokens: Short-lived (15 minutes)
- Refresh tokens: Long-lived (7 days), securely stored
- Stateless scaling — no Redis needed for session storage

**Multi-device policy:** Multiple concurrent sessions allowed
- Users can be logged in on multiple devices simultaneously
- No automatic logout on new device login

**Login methods:** Email/password + Google OAuth
- Email/password primary with bcrypt hashing
- Google OAuth for convenience (lower friction)
- No phone number/SMS login (avoids cost and complexity)

### Notification Infrastructure

**Architecture:** Hybrid approach
- Socket.io for in-app real-time notifications (active app)
- FCM (Firebase Cloud Messaging) / APNs for background/closed app alerts
- SOS notifications use high-priority FCM / critical APNs alerts to ensure delivery when app closed

**Notification scope:**
- Incoming video calls
- SOS alerts (sent and received)
- Chat/message notifications
- Other users' SOS status alerts
- Learning reminders (future phase)

**Visual effects for deaf users:**
- Custom vibration patterns (Android) + haptic feedback (iOS)
- Custom UI colors and intensity levels via notification payload
- SOS type detection via payload `type="SOS"` for special handling
- Photosensitive epilepsy considerations: No flashing, use solid colors with gentle pulsing

### Deployment & Infrastructure

**Hosting:** Single VPS (self-hosted)
- Cost target: $6-10/month
- Providers: Hetzner, DigitalOcean, Oracle Free Tier
- Location: Cheapest available (Singapore or EU) — no Vietnam data residency requirement
- All services on one server via Docker Compose

**Database:** PostgreSQL + Redis on same VPS
- No managed database services
- Redis for caching and any session needs (even with JWT, useful for rate limiting, etc.)

**STT/TTS providers:** Strategy pattern with cloud primary + local fallback
- Cloud: Groq Whisper (STT) + ElevenLabs/Google TTS
- Self-hosted fallback: Whisper.cpp (STT) + Coqui TTS
- Env var configuration: `STT_PROVIDER`, `TTS_PROVIDER`
- Fallback logic: Cloud primary → self-hosted on failure

**Containerization:** Docker Compose for all services
- Node.js API
- PostgreSQL
- Redis
- LiveKit (for video calling, deployed now for infrastructure)
- Optional: Whisper.cpp / Coqui TTS containers

### Mobile-Web API Coordination

**API architecture:** Monolithic REST API
- Single API server serves both mobile and web
- Endpoints prefixed with `/api/v1/`
- Same authentication mechanism for both platforms
- No BFF layer — simplifies maintenance

**TypeScript SDK:** Contract-first with OpenAPI codegen
- Use `openapi-typescript` to generate types from OpenAPI schema
- Shared types between backend and frontend
- Single source of truth for API contracts

**Platform parity:** Mobile and web share identical API
- No platform-specific endpoints in v1
- Feature parity target across platforms

**WebRTC signaling:** LiveKit self-hosted
- LiveKit server deployed on same VPS via Docker Compose
- Provides SFU architecture for video calls
- Native SDKs for both mobile (Flutter) and web (JavaScript)

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Documentation
- `.planning/PROJECT.md` — Project overview, constraints, technology stack preferences
- `.planning/REQUIREMENTS.md` — Full requirements catalog with ACC/COMM/EMERG/etc IDs
- `.planning/ROADMAP.md` — Phase boundaries, dependencies, success criteria
- `.planning/STATE.md` — Current project state and blockers

### External References
- No external ADRs or specs yet — decisions captured in this CONTEXT.md file

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
None — this is a greenfield project with no existing codebase.

### Established Patterns
None — patterns to be established during Phase 1 implementation.

### Integration Points
- Future mobile app (Flutter) will integrate with `/api/v1/` endpoints
- Future web app (Next.js) will integrate with same API
- LiveKit client SDKs will connect to self-hosted LiveKit server
- FCM/APNs integration for push notifications

</code_context>

<specifics>
## Specific Ideas

**VieNeu-TTS** — Vietnamese neural TTS mentioned as potential option; research quality and integration effort during planning.

**Groq Whisper** — Cloud STT via Groq API; evaluate latency and Vietnamese accuracy.

**Whisper.cpp** — Self-hosted STT fallback; runs on CPU, requires model file (~2GB for large-v3).

**Docker Compose** — All services orchestrated via `docker-compose.yml` for easy deployment.

**Strategy pattern** — STT/TTS providers abstracted behind interfaces; switching via env vars.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

</deferred>

---

*Phase: 1-Foundation & Authentication*
*Context gathered: 2026-05-05*
