---
phase: 04-video-calling
plan: 06
subsystem: video-calling
tags: [nextjs, calls, livekit, zod, jest, uat-gap]

# Dependency graph
requires:
  - phase: 04-02
    provides: Call lifecycle API routes, token endpoint, auth patterns, and validators
  - phase: 04-04
    provides: Web call page and ActiveCallCanvas integration
provides:
  - Participant-authorized GET endpoint for call state lookup
  - Web active-call token fetch flow using the token endpoint instead of re-accept
  - Zod notification data schema compatible with installed Zod types
  - Focused backend and web regression tests for Phase 4 UAT gaps
affects: [04-07, phase-04-verification, web-call-uat]

# Tech tracking
tech-stack:
  added: []
  patterns: [Bearer-or-cookie auth extraction for shared web/mobile endpoints, exported call page fetch helpers for node-safe unit tests]

key-files:
  created:
    - src/app/api/calls/[callId]/route.ts
    - src/__tests__/calls/call-state-route.test.ts
  modified:
    - src/app/lib/validators.ts
    - src/app/calls/[callId]/page.tsx
    - src/__tests__/web/call-page.test.tsx

key-decisions:
  - "GET /api/calls/[callId] accepts either accessToken cookie or mobile Bearer token, then authorizes caller/callee participation before returning call details."
  - "Already ACTIVE web calls fetch fresh LiveKit credentials from POST /api/calls/[callId]/token; only the explicit RINGING accept action calls /accept."
  - "Web call page request logic was extracted into exported helpers so Jest can test fetch sequencing without a browser DOM test environment."

patterns-established:
  - "Call state responses include both id and callId for compatibility with existing web/mobile call models."
  - "FCM custom notification data remains string-to-string through z.record(z.string(), z.string())."

requirements-completed: [COMM-05, WEB-02]

# Metrics
duration: 8min
completed: 2026-05-16
---

# Phase 04 Plan 06: Web/Backend UAT Gap Closure Summary

**Participant-authorized call state lookup and corrected web active-call token flow for Phase 4 video calling**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-16T15:02:00Z
- **Completed:** 2026-05-16T15:10:00Z
- **Tasks:** 3
- **Files modified:** 5

## Accomplishments

- Fixed the Zod v4 `z.record` compile issue for notification custom data payloads.
- Added `GET /api/calls/[callId]` with cookie and Bearer auth, participant authorization, 400/401/403/404 handling, and caller/callee display names.
- Changed web ACTIVE call loading to fetch `/api/calls/{id}/token` instead of re-posting to `/accept`.
- Replaced web call page todo tests with executable fetch-sequencing tests.
- Added backend route tests covering unauthenticated, invalid ID, missing call, non-participant, participant success, and Bearer auth paths.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix Zod record schema compile error** - `e1057c2` (fix)
2. **Task 2: Add participant-authorized call state GET endpoint** - `8446c20` (feat)
3. **Task 3: Fix web active-call token fetch flow** - `f616a65` (fix)
4. **Verification typing fix** - `f442fcc` (fix)

## Files Created/Modified

- `src/app/lib/validators.ts` - Uses `z.record(z.string(), z.string())` for FCM-compatible string custom data.
- `src/app/api/calls/[callId]/route.ts` - New GET endpoint returning call state only to authenticated participants.
- `src/__tests__/calls/call-state-route.test.ts` - Route tests for auth, validation, authorization, success response, and Bearer token support.
- `src/app/calls/[callId]/page.tsx` - Extracted call page request helpers and routes ACTIVE calls through `/token`.
- `src/__tests__/web/call-page.test.tsx` - Executable web tests proving ACTIVE token flow, no ACTIVE re-accept, accept action behavior, and terminal-state behavior.

## Decisions Made

- Used Bearer fallback in the GET route because mobile `CallApiService.getCallState` needs the same endpoint without browser cookies.
- Returned `callerName` and `calleeName` from the GET route so web can render existing call labels without a second user lookup.
- Kept `/accept` exclusively for the explicit RINGING accept action, preserving the call state machine and avoiding duplicate accept attempts for ACTIVE calls.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Tightened route test typing after TypeScript check**
- **Found during:** Plan verification (`npx tsc --noEmit --pretty false`)
- **Issue:** The new route test inferred `state` as plain `string`, producing a TypeScript error against Prisma's `CallState` type.
- **Fix:** Marked the fixture state as the literal `'ACTIVE' as const`.
- **Files modified:** `src/__tests__/calls/call-state-route.test.ts`
- **Verification:** Targeted route test passed and filtered TypeScript check no longer reports 04-06 files.
- **Committed in:** `f442fcc`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The fix was local to the new test fixture typing. No product behavior changed.

## Issues Encountered

- Full `npx tsc --noEmit --pretty false` still fails on pre-existing unrelated project files, including `shared/types/landmarks.ts`, `src/__tests__/auth/google.test.ts`, older health/livekit/tts tests, and shared Jest mock typing in `src/__tests__/setup.ts`.
- After the local fixture fix, the filtered TypeScript check reports no errors for `04-06` files.

## Verification

- `rg "data: z\\.record\\(z\\.string\\(\\), z\\.string\\(\\)\\)\\.optional\\(\\)" src/app/lib/validators.ts` - passed.
- `npm test -- --runInBand src/__tests__/calls/call-state-route.test.ts` - passed, 6 tests.
- `npm test -- --runInBand src/__tests__/web/call-page.test.tsx` - passed, 4 tests.
- `npx tsc --noEmit --pretty false` - failed on unrelated pre-existing repo-wide TypeScript errors; no remaining errors in the new/modified 04-06 files after filtering.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 web/backend UAT gaps for call-state lookup, ACTIVE token fetching, and Zod validator compilation are closed.
- `04-07` can proceed to mobile route wiring and outgoing call entry flow.
- Remaining full TypeScript failures should be handled as a separate repo-wide validation cleanup, not as blockers for this web/backend gap closure.

## Self-Check: PASSED

- Key created files exist.
- Commits for `04-06` are present.
- Targeted backend and web tests pass.
- Known full-TypeScript failures are outside the files and behaviors changed by this plan.

---
*Phase: 04-video-calling*
*Completed: 2026-05-16*
