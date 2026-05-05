# Phase 1: Foundation & Authentication - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-05
**Phase:** 1-Foundation & Authentication
**Areas discussed:** STT/TTS Vietnamese Solution, Authentication & Session Architecture, Notification Infrastructure, Deployment & Infrastructure, Mobile-Web API Coordination

---

## STT/TTS Vietnamese Solution

| Option | Description | Selected |
|--------|-------------|----------|
| Self-hosted open source | Faster Whisper + Piper/VieNeu TTS; full control, zero software cost, requires ops work | |
| Cloud API | Google/Azure STT/TTS; high quality, simple ops, recurring cost | |
| Hybrid approach | Cloud primary + self-hosted fallback with strategy pattern | ✓ |

**User's choice:** Hybrid approach with strategy pattern
**Notes:** 
- Zero or low budget; if self-hosted too complex for 1-week demo, fall back to TTS API
- Latency target: <500ms
- Willing to handle moderate-high ops complexity (graduation project)
- Accuracy prioritized over open-source preference
- STT still undecided — will evaluate during planning
- VieNeu-TTS mentioned as TTS option to research
- Groq Whisper (cloud) vs Whisper.cpp (local) for STT
- Coqui TTS or ElevenLabs/Google for TTS cloud fallback

---

## Authentication & Session Architecture

| Option | Description | Selected |
|--------|-------------|----------|
| JWT (stateless) | No server-side session storage, tokens contain all info, easy horizontal scaling | ✓ |
| Session-based (stateful) | Server stores session in Redis, easier revocation, more session data storage | |
| OAuth/social only | No email/password, third-party auth only | |

**User's choice:** JWT (stateless)
**Notes:**

| Option | Description | Selected |
|--------|-------------|----------|
| Single session per user | New login kills old sessions (security-first) | |
| Multiple concurrent sessions | Allow phone + web simultaneously (usability-first) | ✓ |
| Configurable per user | User can see active sessions and revoke | |

**Multi-device policy:** Multiple concurrent sessions allowed
**Notes:** No automatic logout on new device

| Option | Description | Selected |
|--------|-------------|----------|
| Long-lived JWT (7-30 days) | Simpler, no refresh token | |
| Short-lived (15min) + refresh (7d) | More secure, requires secure refresh storage | ✓ |
| Session cookie only | Simpler for web | |

**Refresh strategy:** Short-lived access tokens (15 minutes) + refresh tokens (7 days)

| Option | Description | Selected |
|--------|-------------|----------|
| Email/password only | Simple, no third-party dependencies | |
| Add social login (Google/Apple) | Lower friction | ✓ |
| Phone number login | SMS verification adds cost | |

**Login methods:** Email/password + Google OAuth

---

## Notification Infrastructure

| Option | Description | Selected |
|--------|-------------|----------|
| Socket.io only | WebSockets for in-app only | |
| Web Push + FCM/APNs | Native push for background, complex setup | |
| SSE | One-way server-to-client, simple | |
| Hybrid: Socket.io + FCM/APNs | Best of both worlds | ✓ |

**Primary approach:** Hybrid (Socket.io for in-app real-time + FCM/APNs for background/closed app)

**Mobile background priority:** SOS notifications must work when app closed — use FCM high-priority / APNs critical alert

| Option | Description | Selected |
|--------|-------------|----------|
| Vibration patterns | Custom haptic feedback | ✓ |
| Flashing screen | Photosensitive epilepsy concerns — avoid | |
| Custom colors/intensity | Via notification payload | ✓ |

**Visual effects:** Custom vibration patterns + custom UI colors via notification payload
**SOS detection:** Payload `type="SOS"` triggers special handling

| Option | Description | Selected |
|--------|-------------|----------|
| Video calls + SOS only | Minimal notification scope | |
| Video calls + SOS + chat/messages + SOS from others + reminders | Broader scope for completeness | ✓ |

**Notification scope:** Video calls, SOS (sent/received), chat/messages, other users' SOS alerts, reminders

---

## Deployment & Infrastructure

| Option | Description | Selected |
|--------|-------------|----------|
| Self-hosted VPS | Full control, predictable cost, requires sysadmin | ✓ |
| PaaS (Railway/Render) | Easier deployment, auto-scaling, higher cost | |

**Infrastructure approach:** Single VPS ($6-10/month: Hetzner/DigitalOcean/Oracle Free)

| Option | Description | Selected |
|--------|-------------|----------|
| DB on same VPS | Simple, no managed DB costs | ✓ |
| Separate managed DB | Better isolation, higher cost | |

**Database hosting:** PostgreSQL + Redis on same VPS

| Option | Description | Selected |
|--------|-------------|----------|
| Cloud STT/TTS only | Groq Whisper + ElevenLabs/Google | |
| Self-hosted only | Whisper.cpp + Coqui TTS on CPU | |
| Strategy pattern with both | Cloud primary + local fallback via STT_PROVIDER/TTS_PROVIDER | ✓ |

**STT/TTS implementation:** Strategy pattern
- Cloud: Groq Whisper (STT) + ElevenLabs/Google TTS
- Self-hosted fallback: Whisper.cpp (STT) + Coqui TTS
- Configuration via env vars: `STT_PROVIDER=groq|local`, `TTS_PROVIDER=elevenlabs|local|vieneu`

| Option | Description | Selected |
|--------|-------------|----------|
| Vietnam server | Higher cost for data residency | |
| Cheapest global (Singapore/EU) | No Vietnam data requirement | ✓ |

**Server location:** Cheapest available (Singapore or EU) — no Vietnam data residency requirement

---

## Mobile-Web API Coordination

| Option | Description | Selected |
|--------|-------------|----------|
| Monolithic REST | Single API for both platforms, simple | ✓ |
| BFF | Separate API layers per platform | |
| GraphQL | Flexible queries, more complex | |

**API architecture:** Monolithic REST with `/api/v1/` prefix

| Option | Description | Selected |
|--------|-------------|----------|
| OpenAPI codegen | Contract-first with `openapi-typescript` | ✓ |
| Manual API client | Handwritten types | |

**TypeScript SDK:** Generate types from OpenAPI schema

| Option | Description | Selected |
|--------|-------------|----------|
| Shared API (no BFF) | Same endpoints for mobile and web | ✓ |
| Platform-specific endpoints | Mobile-only or web-only features | |

**Platform divergence:** Mobile and web share the same API — no platform-specific endpoints

| Option | Description | Selected |
|--------|-------------|----------|
| LiveKit (self-hosted) | Docker Compose on VPS, SFU architecture | ✓ |
| Separate signaling server | Custom WebRTC signaling | |
| Cloud LiveKit service | Managed, higher cost | |

**WebRTC signaling:** Self-hosted LiveKit on VPS via Docker Compose

---

## Claude's Discretion

None — user provided explicit decisions for all options.

## Deferred Ideas

None — discussion stayed within phase scope.

---
