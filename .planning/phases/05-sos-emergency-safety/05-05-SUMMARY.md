---
plan: "05-05"
phase: "05"
status: complete
completed: "2026-05-16"
subsystem: "sos-emergency-safety"
tags: [sos, push-notifications, socket-io, twilio, fallback, gps, security]
dependency-graph:
  requires: ["05-04"]
  provides: ["late-gps-update", "native-fallback-record", "twilio-status-callback", "push-socket-fanout"]
  affects: ["src/app/lib/sos.ts", "src/app/lib/push.ts", "src/app/lib/socket.ts"]
tech-stack:
  added: []
  patterns: ["server-authoritative-fanout", "twilio-signature-validation", "fcm-multicast-push"]
key-files:
  created:
    - src/app/api/sos/alerts/[id]/location/route.ts
    - src/app/api/sos/alerts/[id]/fallback/route.ts
    - src/app/api/sos/twilio/status/route.ts
    - src/__tests__/sos/sos-fallback.test.ts
    - src/__tests__/sos/sos-notifications.test.ts
  modified:
    - src/app/lib/sos.ts
    - src/app/lib/push.ts
    - src/app/lib/socket.ts
decisions:
  - "Mocked sos.ts helpers in fallback tests to avoid Prisma import complexity — matches existing sos-api.test.ts pattern"
  - "Removed client-trusting socket.on(sos:alert) handler entirely — replaced with server-authoritative comment"
  - "sendSosPushNotification excludes all Twilio credentials and raw provider metadata from FCM payload"
metrics:
  duration: "~15 minutes"
  completed: "2026-05-16"
  tasks: 3
  files: 8
---

# Phase 05 Plan 05: Late GPS, Fallback, Twilio Callback & Push/Socket Fanout — Summary

## One-liner

Server-authoritative SOS fanout via FCM push and Socket.io, with Twilio signature-validated status callbacks and owner-only GPS/fallback update endpoints.

## What was built

### API Routes (3 new)

**POST /api/sos/alerts/[id]/location** (`src/app/api/sos/alerts/[id]/location/route.ts`):
Allows the alert owner to attach or update GPS coordinates after the initial SOS was sent (e.g., when location became available late). Uses `SosLocationUpdateSchema` validation and `updateSosLocation` helper. Returns 404 if the alert does not belong to the authenticated user — no cross-user coordinate updates possible.

**POST /api/sos/alerts/[id]/fallback** (`src/app/api/sos/alerts/[id]/fallback/route.ts`):
Records native-SMS-composer and dialer events from the mobile client. Accepts three fallback types: `native_sms_opened` → `NATIVE_COMPOSER_OPENED`, `native_sms_failed` → `NATIVE_COMPOSER_FAILED`, `dialer_opened` → `DIALER_OPENED`. Critically: none of these statuses imply SMS was sent or delivered — the status labels accurately reflect only what the device did.

**POST /api/sos/twilio/status** (`src/app/api/sos/twilio/status/route.ts`):
Twilio webhook for SMS delivery callbacks. Validates `X-Twilio-Signature` using `twilio.validateRequest` before processing. Rejects with 403 on invalid signature. Updates `sosAlertAttempt.status` and delivery timestamps by `providerMessageSid`. Gracefully acknowledges if `TWILIO_AUTH_TOKEN` is not configured (dev mode).

### Library Extensions

**`src/app/lib/sos.ts`** — added three helper functions:
- `updateSosLocation(userId, alertId, data)` — owner-scoped GPS update
- `recordSosFallback(userId, alertId, data)` — fallback status persistence
- `recordTwilioStatus(data)` — delivery callback update by `providerMessageSid`

**`src/app/lib/push.ts`** — added `sendSosPushNotification(userId, payload)`:
Follows `sendCallPushNotification` pattern: queries `DeviceToken`, sends FCM multicast with `type: 'SOS'` and `alertId`, cleans up unregistered tokens. Payload deliberately excludes Twilio credentials, raw provider responses, and error codes.

**`src/app/lib/socket.ts`** — removed client-trusting `socket.on('sos:alert', ...)` handler that accepted client-provided `emergencyContacts`. Replaced with a comment marking the server-authoritative pattern. Clients may still join `user:{userId}` rooms; the server emits to those rooms.

## Tests

**`src/__tests__/sos/sos-fallback.test.ts`** (9 tests — all pass):
- Location endpoint: owner update, non-owner 404, unauthenticated 401
- Fallback endpoint: native_sms_opened records NATIVE_COMPOSER_OPENED (not sent), native_sms_failed records NATIVE_COMPOSER_FAILED (not delivered), dialer_opened records DIALER_OPENED, non-owner returns 404
- Twilio callback: invalid signature returns 403, valid signature calls recordTwilioStatus with correct MessageSid

**`src/__tests__/sos/sos-notifications.test.ts`** (6 tests — all pass):
- FCM payload contains `type: 'SOS'` and `alertId`
- FCM payload excludes Twilio credentials and provider metadata
- Returns `{ sent: 0, failed: 0 }` when no device tokens exist
- Cleans up UNREGISTERED stale tokens after send
- Socket module does not expose client-trusting sos:alert handler
- Socket module contains server-authoritative comment

Full SOS suite: **39/39 tests pass** across all 4 SOS test files.

## Commits

- `de5fbac`: feat(05-05): late GPS update, fallback, Twilio callback, push/socket fanout

## Deviations from Plan

### Auto-fixed: Test structure revised to use module-level mocks

**Found during:** Task 1 / Task 2 (RED to GREEN transition)
**Issue:** The plan suggested using `jest.resetModules()` + dynamic `import()` in `beforeEach` for test isolation. This pattern breaks Jest's `jest.mock()` hoisting — after `resetModules()`, the newly-imported route modules receive real (un-mocked) dependencies, causing 401 responses instead of testing the actual route logic.
**Fix:** Structured tests to use module-level imports with module-level `jest.mock()` declarations (matching the existing `sos-api.test.ts` pattern), plus a separate mock for `@/app/lib/sos` in fallback tests to avoid Prisma import chains. This is standard Jest TDD practice and does not change what is tested.
**Files modified:** `src/__tests__/sos/sos-fallback.test.ts`

## Self-Check

All created files verified to exist. Commit de5fbac verified in git log.

## Self-Check: PASSED
