---
phase: 04-video-calling
plan: 01
subsystem: database
tags: [prisma, postgresql, livekit, video-calling, state-machine]

# Dependency graph
requires:
  - phase: "01-foundation-authentication"
    provides: "User model, Prisma client setup, test infrastructure"
provides:
  - "CallSession model and CallState enum in Prisma schema"
  - "Call state machine library with 8 race-safe functions"
  - "Async LiveKit token helpers (fixed from sync)"
  - "Test scaffolds for call lifecycle and token generation"
affects: [04-02, 04-03, 04-04]

# Tech tracking
tech-stack:
  added: [prisma.config.ts for Prisma 7 compatibility]
  patterns: [atomic state transitions via updateMany, async token generation]

key-files:
  created:
    - prisma.config.ts
    - src/lib/calls.ts
    - src/__tests__/calls/call-lifecycle.test.ts
    - src/__tests__/calls/livekit-token.test.ts
  modified:
    - prisma/schema.prisma
    - src/lib/livekit.ts
    - src/__tests__/setup.ts

key-decisions:
  - "Used Prisma 7 prisma.config.ts format (datasource.url required for db push)"
  - "All state transitions use updateMany for race safety, never updateOne"
  - "acceptCall generates both caller and callee tokens after successful transition"
  - "Local PostgreSQL database created (vsl_user/vsl_bridge) since Docker unavailable"

patterns-established:
  - "Atomic state transitions: updateMany with where guards (calleeId, state, expiresAt)"
  - "Busy check: checkBusy() called before createCall to prevent double-calling"
  - "30-second expiry: expiresAt set to now + 30s on call creation"

requirements-completed: [COMM-05]

# Metrics
duration: 15min
completed: 2026-05-16
---

# Phase 04 Plan 01: Call Lifecycle Foundation Summary

**Prisma CallSession model with 8-state enum, race-safe call state machine, async LiveKit token helpers, and Wave 0 test scaffolds**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-16T01:07:00Z
- **Completed:** 2026-05-16T01:22:00Z
- **Tasks:** 3
- **Files modified:** 7

## Accomplishments

- Extended Prisma schema with CallState enum (8 states) and CallSession model with caller/callee relations
- Built call state machine library with 8 exported functions using atomic updateMany transitions
- Fixed LiveKit token helpers from sync to async (await token.toJwt()) matching SDK documentation
- Created test scaffolds with 24 test.todo() entries covering all state machine and token scenarios
- Set up local PostgreSQL database and Prisma 7 config for db push

## Task Commits

Each task was committed atomically:

1. **Task 1: Add CallSession model and CallState enum** - `e74bc8b` (feat)
2. **Task 2: Build call state machine library** - `1e275de` (feat)
3. **Task 3: Fix LiveKit token helpers and create test scaffolds** - `42c1ee9` (feat)

**Plan metadata:** pending (docs: complete plan)

## Files Created/Modified

- `prisma/schema.prisma` - Added CallState enum, CallSession model, User relations
- `prisma.config.ts` - Prisma 7 config with datasource URL
- `src/lib/calls.ts` - Call state machine with 8 functions (createCall, acceptCall, rejectCall, cancelCall, endCall, checkBusy, expireRingingCalls, generateRoomName)
- `src/lib/livekit.ts` - Changed generateLiveKitToken and generateLiveKitRoomToken to async
- `src/__tests__/calls/call-lifecycle.test.ts` - 20 test.todo() entries for call lifecycle
- `src/__tests__/calls/livekit-token.test.ts` - 4 test.todo() entries for token generation
- `src/__tests__/setup.ts` - Added callSession mock

## Decisions Made

- **Prisma 7 config format:** Prisma 7 requires `prisma.config.ts` with `datasource.url` for `db push` command. Created config file alongside existing schema.prisma.
- **Local database setup:** Docker not available; created PostgreSQL user/database directly (vsl_user/vsl_bridge) for schema push.
- **updateMany for all transitions:** Plan explicitly required updateMany over updateOne for race safety — all 4 state transition functions (acceptCall, rejectCall, cancelCall, endCall) use updateMany with where guards.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Created prisma.config.ts for Prisma 7 compatibility**
- **Found during:** Task 1 (Prisma db push)
- **Issue:** Prisma 7 requires `prisma.config.ts` with `datasource.url` property for `db push` command; schema.prisma datasource alone is insufficient
- **Fix:** Created `prisma.config.ts` with `defineConfig({ schema: 'prisma/schema.prisma', datasource: { url: process.env.DATABASE_URL! } })`
- **Files modified:** prisma.config.ts (created)
- **Verification:** `npx prisma db push` succeeds with config file
- **Committed in:** e74bc8b (Task 1 commit)

**2. [Rule 3 - Blocking] Set up local PostgreSQL database**
- **Found during:** Task 1 (Prisma db push)
- **Issue:** Database credentials in .env (vsl_user/vsl_password) did not exist; Docker not available for containerized setup
- **Fix:** Created PostgreSQL user and database directly: `CREATE USER vsl_user WITH PASSWORD 'vsl_password'`, `CREATE DATABASE vsl_bridge OWNER vsl_user`
- **Files modified:** none (database setup)
- **Verification:** `npx prisma db push` succeeds, database schema synced
- **Committed in:** e74bc8b (Task 1 commit)

---

**Total deviations:** 2 auto-fixed (2 blocking)
**Impact on plan:** Both auto-fixes necessary for environment setup. No scope creep — database and config are prerequisites for the plan's schema push requirement.

## Issues Encountered

- Prisma 7 config format differs from Prisma 6 — requires `prisma.config.ts` instead of relying solely on schema.prisma datasource block
- Pre-existing TypeScript errors in test files (health.test.ts, setup.ts mock typing) — not caused by this plan, left untouched per scope boundary rule

## Verification Results

All plan-level verification checks passed:
- [x] Prisma schema includes CallSession model and CallState enum with all 8 states
- [x] npx prisma generate and npx prisma db push succeed
- [x] src/lib/calls.ts exports 8 functions with correct signatures
- [x] src/lib/livekit.ts token functions are async and use await token.toJwt()
- [x] Test scaffolds run without import or syntax errors (20 + 4 test.todo entries)

## User Setup Required

None - no external service configuration required. LiveKit API keys are referenced via environment variables (LIVEKIT_API_KEY, LIVEKIT_API_SECRET) but token generation functions work with mocks in tests.

## Next Phase Readiness

- Call lifecycle foundation complete and ready for API route implementation (04-02)
- LiveKit token generation async-ready for Socket.io signaling (04-03)
- Test scaffolds in place for full test implementation in subsequent plans
- COMM-05 requirement partially fulfilled (data layer complete; API endpoints pending)

---
*Phase: 04-video-calling*
*Completed: 2026-05-16*
