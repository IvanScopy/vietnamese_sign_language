---
phase: 04-video-calling
plan: 02
subsystem: api
tags: [socket-io, firebase-admin, fcm, livekit, zod, video-calling]

# Dependency graph
requires:
  - phase: "04-video-calling"
    provides: "CallSession model, call state machine, async LiveKit token helpers (Plan 01)"
provides:
  - "Six REST API endpoints for full call lifecycle (create, accept, reject, cancel, end, token)"
  - "Server-authoritative Socket.io signaling via emitCallEvent()"
  - "FCM push notification helper for incoming call alerts"
  - "Zod validation schemas for call endpoints"
  - "Test scaffolds for signaling and push notification testing"
affects: [04-03, 04-04]

# Tech tracking
tech-stack:
  added: [firebase-admin]
  patterns:
    - "JWT cookie auth extraction via verifyAccessToken()"
    - "Fire-and-forget push notifications (non-blocking)"
    - "Server-authoritative signaling — clients cannot emit call lifecycle events"
    - "Atomic state transitions via Plan 01's updateMany patterns"

key-files:
  created:
    - src/app/api/calls/route.ts
    - src/app/api/calls/[callId]/accept/route.ts
    - src/app/api/calls/[callId]/reject/route.ts
    - src/app/api/calls/[callId]/cancel/route.ts
    - src/app/api/calls/[callId]/end/route.ts
    - src/app/api/calls/[callId]/token/route.ts
    - src/app/lib/call-signaling.ts
    - src/app/lib/push.ts
    - src/__tests__/calls/call-signaling.test.ts
    - src/__tests__/notifications/call-push.test.ts
  modified:
    - src/app/lib/validators.ts
    - src/app/lib/socket.ts
    - package.json

key-decisions:
  - "Used JWT cookie auth (verifyAccessToken) consistently across all endpoints — matches existing /api/user/profile pattern"
  - "Push notifications are fire-and-forget — caller name lookup and FCM send do not block the API response"
  - "Token endpoint generates fresh LiveKit tokens on-demand rather than caching — tokens are short-lived by design"
  - "Removed client-originating call:incoming socket handler — all call signaling is now server-authoritative via REST"

patterns-established:
  - "Server-authoritative call signaling: REST endpoints own state transitions, Socket.io only emits (never receives) call events"
  - "Busy check before create: checkBusy() called for both caller and callee before createCall()"
  - "Graceful Firebase degradation: push helper returns { sent: 0, failed: 0 } when Firebase not initialized (dev-friendly)"

requirements-completed: [COMM-05, NOTIF-01]

# Metrics
duration: 12min
completed: 2026-05-16
---

# Phase 04 Plan 02: Call Signaling & API Endpoints Summary

**Six REST API endpoints for call lifecycle with server-authoritative Socket.io signaling, FCM push helper, and Zod validation schemas**

## Performance

- **Duration:** 12 min
- **Started:** 2026-05-16T01:22:00Z
- **Completed:** 2026-05-16T01:34:00Z
- **Tasks:** 4 (including Task 0 checkpoint)
- **Files modified:** 12

## Accomplishments

- Installed firebase-admin SDK (v13.10.0, verified legitimate via npm registry)
- Created CreateCallSchema and CallActionSchema Zod validators
- Built call-signaling.ts with emitCallEvent() for server-to-client Socket.io events
- Built push.ts with sendCallPushNotification() for FCM VIDEO_CALL notifications
- Created 6 API route handlers: POST /api/calls, /accept, /reject, /cancel, /end, /token
- Removed client-originating call:incoming socket handler from socket.ts
- Created test scaffolds with 9 total test.todo() entries

## Task Commits

Each task was committed atomically:

1. **Task 0: Install firebase-admin and add Zod schemas** - `3e85cc9` (chore)
2. **Task 1: Call signaling library and FCM push helper** - `89b376d` (feat)
3. **Task 2: Call lifecycle API endpoints + remove client call:incoming** - `d5a1c89` (feat)
4. **Task 3: Wave 0 test scaffolds** - `099a3e3` (test)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified

- `src/app/api/calls/route.ts` - POST handler: create call with busy check, emit call:incoming + call:ringing, fire-and-forget push
- `src/app/api/calls/[callId]/accept/route.ts` - POST handler: atomic accept, return LiveKit tokens for both participants
- `src/app/api/calls/[callId]/reject/route.ts` - POST handler: reject call, emit call:rejected to caller
- `src/app/api/calls/[callId]/cancel/route.ts` - POST handler: cancel call, emit call:cancelled to callee
- `src/app/api/calls/[callId]/end/route.ts` - POST handler: end call, emit call:ended to both participants
- `src/app/api/calls/[callId]/token/route.ts` - POST handler: generate fresh LiveKit token for active call participants
- `src/app/lib/call-signaling.ts` - emitCallEvent() helper for server-authoritative Socket.io event emission
- `src/app/lib/push.ts` - sendCallPushNotification() FCM helper with UNREGISTERED token cleanup
- `src/app/lib/validators.ts` - Added CreateCallSchema, CallActionSchema
- `src/app/lib/socket.ts` - Removed client-originating call:incoming handler (lines 41-54)
- `src/__tests__/calls/call-signaling.test.ts` - 5 test.todo() entries for emitCallEvent
- `src/__tests__/notifications/call-push.test.ts` - 4 test.todo() entries for push notifications

## Decisions Made

- **JWT cookie auth pattern:** All endpoints extract userId from accessToken cookie via verifyAccessToken(), matching the existing /api/user/profile pattern. Returns 401 for missing/invalid tokens.
- **Fire-and-forget push:** The caller name lookup and FCM send in POST /api/calls are intentionally non-blocking — the API returns 201 immediately while push is sent asynchronously.
- **Token endpoint design:** POST /api/calls/[id]/token generates fresh LiveKit tokens on each request rather than caching them from acceptCall. This supports token refresh during long calls.
- **Graceful Firebase degradation:** push.ts returns { sent: 0, failed: 0 } when Firebase apps are not initialized, allowing development without FCM credentials.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed nullable callerName type in push notification**
- **Found during:** Task 2 (TypeScript compilation)
- **Issue:** `user.name` from Prisma is `string | null` but `sendCallPushNotification` expects `string`
- **Fix:** Changed `if (user)` to `if (user?.name)` guard before calling push notification
- **Files modified:** src/app/api/calls/route.ts
- **Verification:** npx tsc --noEmit passes with 0 errors in new files
- **Committed in:** d5a1c89 (Task 2 commit)

**2. [Rule 2 - Missing Critical] Removed unused credential import from firebase-admin/app**
- **Found during:** Task 1 (TypeScript compilation)
- **Issue:** Initial import included `credential` which doesn't exist as a named export
- **Fix:** Removed unused import, only keeping `getApp` and `getApps`
- **Files modified:** src/app/lib/push.ts
- **Verification:** npx tsc --noEmit passes
- **Committed in:** 89b376d (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (1 bug, 1 missing critical)
**Impact on plan:** Both fixes necessary for TypeScript compilation. No scope creep.

## Issues Encountered

- Pre-existing TypeScript errors in test files (health.test.ts, setup.ts, livekit-token.test.ts) — not caused by this plan, left untouched per scope boundary rule
- firebase-admin v13.10.0 has native dependencies (farmhash-modern) that may require build tools on some platforms — installed successfully on this Linux environment

## Verification Results

All plan-level verification checks passed:
- [x] All six API endpoints exist and compile without TypeScript errors
- [x] Call signaling library (emitCallEvent) uses getIOInstance() and io.to(`user:${userId}`).emit()
- [x] FCM push helper (sendCallPushNotification) queries DeviceToken by userId
- [x] FCM push helper constructs VIDEO_CALL data payload
- [x] FCM push helper handles UNREGISTERED tokens by deletion
- [x] FCM push helper returns { sent: 0, failed: 0 } when Firebase not initialized
- [x] Client-originating call:incoming handler removed from socket.ts
- [x] CreateCallSchema exports calleeId field (z.number().int().positive())
- [x] CallActionSchema exports callId field
- [x] Test scaffolds run without import errors (5 + 4 test.todo entries)

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag:auth | src/app/api/calls/route.ts | JWT extraction from cookie — callerId derived from token, not request body (T-04-06 mitigated) |
| threat_flag:auth | src/app/api/calls/[callId]/accept/route.ts | Only callee can accept via userId === payload.userId check (T-04-07 mitigated) |
| threat_flag:dos | src/app/api/calls/route.ts | checkBusy() prevents ring spam — returns 409 for busy users (T-04-08 mitigated) |
| threat_flag:info-disclosure | src/app/lib/push.ts | FCM payload contains only { type, callId, callerName } — no PII or tokens (T-04-09 mitigated) |

## User Setup Required

None - no external service configuration required. Firebase Admin SDK is installed but push notifications gracefully degrade when FCM credentials are not configured.

## Next Phase Readiness

- Call lifecycle API endpoints ready for client screen integration (Plans 03, 04)
- Socket.io signaling ready for real-time call UI updates (Plan 03)
- FCM push helper ready for mobile app background notifications (Plan 04)
- COMM-05 requirement fulfilled (API endpoints complete)
- NOTIF-01 requirement fulfilled (FCM push helper complete)

---
*Phase: 04-video-calling*
*Completed: 2026-05-16*
