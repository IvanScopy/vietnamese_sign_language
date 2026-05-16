---
plan: "05-04"
phase: "05"
subsystem: "backend/sos"
status: complete
completed: "2026-05-16"
tags: [sos, sms, twilio, tdd, api]
dependency_graph:
  requires: [05-01, 05-02, 05-03]
  provides: [sms-provider, sos-core-logic, sos-alert-endpoint]
  affects: [mobile-sos-trigger]
tech_stack:
  added: [twilio-sms-provider]
  patterns: [tdd-red-green, concurrent-fanout, idempotency-key, server-authoritative-userId]
key_files:
  created:
    - src/app/lib/sms-provider.ts
    - src/app/lib/sos.ts
    - src/app/api/sos/alerts/route.ts
    - src/__tests__/sos/sos-api.test.ts
  modified: []
decisions:
  - "Import from db.ts (not prisma.ts) since that is the actual Prisma singleton module"
  - "Used @/app/lib aliases in route imports for consistency with project conventions"
  - "getSmsProvider returns unavailable provider when env vars missing — avoids hard crash in dev"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-16"
  tasks_completed: 3
  files_created: 4
---

# Phase 05 Plan 04: SMS Provider, SOS Core Logic & Alert API — Summary

## One-liner

Twilio SMS provider abstraction with concurrent per-contact fanout, idempotency, and server-authoritative POST /api/sos/alerts backed by 10 TDD tests.

## What was built

**SMS Provider Abstraction (`src/app/lib/sms-provider.ts`):**
- `getSmsProvider()` factory returns a `SmsProvider` interface
- Twilio implementation: reads `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_MESSAGING_SERVICE_SID` / `TWILIO_FROM_NUMBER` from env
- Unavailable fallback provider when env vars missing — returns `TWILIO_NOT_CONFIGURED` error without crashing
- Supports `statusCallback` for Twilio delivery webhooks

**SOS Core Logic (`src/app/lib/sos.ts`):**
- `buildSosSmsBody()`: builds Vietnamese SMS with user name, "Tôi cần trợ giúp khẩn cấp", Google Maps link (or no-GPS text), timestamp, and location accuracy labels
- `createSosAlert()`: server-authoritative orchestration — loads active contacts, creates `SOSAlert`, creates per-contact `SosAlertAttempt` records, sends provider SMS concurrently via `Promise.all`, updates attempt records with results, sets aggregate status (`SENDING` / `PARTIAL_FAILED` / `NATIVE_FALLBACK`), returns `fallbackTargets` for native SMS handoff when all fail
- Idempotency: if `idempotencyKey` provided and alert already exists, returns existing alert

**SOS Alert Endpoint (`src/app/api/sos/alerts/route.ts`):**
- `POST /api/sos/alerts`: validates auth via `getAuthenticatedUser`, validates body via `CreateSosAlertSchema` (zod), calls `createSosAlert(payload.userId, ...)` — userId always from auth token, never from body

## Tests

All 10 tests pass (TDD GREEN):

| Test | Result |
|------|--------|
| 401 when not authenticated | PASS |
| SOSAlert userId from auth, not body | PASS |
| Ignores body userId/contacts/recipient fields | PASS |
| No contacts: noContacts:true, provider not called | PASS |
| Active contacts: attempt per contact, provider called concurrently | PASS |
| Provider failure: attempt PROVIDER_FAILED, fallbackTargets returned | PASS |
| SMS body contains user name and Vietnamese emergency text | PASS |
| SMS body includes Google Maps link when coords provided | PASS |
| SMS body includes no-GPS text when no coords | PASS |
| SMS body includes timestamp | PASS |

## Commits

- `9e402fc` — test(05-04): add failing SOS alert API tests (TDD RED)
- `268a36a` — feat(05-04): SMS provider abstraction, SOS core logic, and alert API

## Deviations from Plan

**1. [Rule 3 - Import path] Fixed `import('./prisma')` → `import('./db')`**
- **Found during:** Task 3 implementation
- **Issue:** Plan's sos.ts code uses `await import('./prisma')` but the project's Prisma singleton is exported from `./db`, not `./prisma`
- **Fix:** Changed the dynamic import to `await import('./db')` to match actual module path
- **Files modified:** `src/app/lib/sos.ts`

## Self-Check

- [x] `src/app/lib/sms-provider.ts` exists
- [x] `src/app/lib/sos.ts` exists
- [x] `src/app/api/sos/alerts/route.ts` exists
- [x] `src/__tests__/sos/sos-api.test.ts` exists
- [x] Commits `9e402fc` and `268a36a` exist
- [x] All 10 tests pass

## Self-Check: PASSED

## Known Stubs

None. The implementation is fully functional with Twilio provider — the unavailable fallback is intentional for dev environments without credentials.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: auth-bypass-attempt | src/app/api/sos/alerts/route.ts | Body fields `userId`, `contacts`, `recipient` are silently stripped — userId always derived from auth token. Validated by test. |
