---
phase: 04-video-calling
plan: 04
subsystem: video-calling
tags: [livekit, socket.io, react, next.js, webrtc, video-calling]

# Dependency graph
requires:
  - phase: 04-01
    provides: LiveKit server SDK, call API routes, Socket.io call signaling
  - phase: 04-02
    provides: Socket.io server infrastructure, call lifecycle events
provides:
  - Web video calling UI with LiveKit room integration
  - Incoming call modal for foreground Socket.io notifications
  - Reusable call components (VideoTile, CallControlBar, SubtitleOverlay, SignDraftOverlay, IncomingCallModal, CallResult)
  - Call entry page with contact selection
  - Dynamic call page handling ringing/active/terminal states
  - Test scaffold for web call page
affects: [04-05, 05-sos, 06-app-readiness]

# Tech tracking
tech-stack:
  added:
    - "@livekit/components-react@2.9.21"
    - "livekit-client@2.19.0"
    - "@livekit/components-styles@1.2.0"
    - "socket.io-client"
  patterns:
    - "LiveKitRoom wrapper pattern for active call canvas"
    - "Socket.io client connection for real-time call events"
    - "State-based routing in dynamic call page (ringing/active/terminal)"
    - "UI-SPEC color system applied consistently across all components"
    - "Inline styles for component-level theming (no CSS framework)"

key-files:
  created:
    - src/components/calls/VideoTile.tsx
    - src/components/calls/CallControlBar.tsx
    - src/components/calls/SubtitleOverlay.tsx
    - src/components/calls/SignDraftOverlay.tsx
    - src/components/calls/IncomingCallModal.tsx
    - src/components/calls/CallResult.tsx
    - src/components/calls/CallEntry.tsx
    - src/components/calls/ActiveCallCanvas.tsx
    - src/app/calls/page.tsx
    - src/app/calls/[callId]/page.tsx
    - src/__tests__/web/call-page.test.tsx
  modified:
    - package.json
    - jest.config.ts

key-decisions:
  - "Used inline styles instead of Tailwind/CSS modules for component theming — matches existing project patterns"
  - "VideoTile accepts MediaStream for track prop — compatible with LiveKit's mediaStream property"
  - "Socket.io client connects with credentials for auth cookie-based registration"
  - "ActiveCallCanvas uses useRoomContext for local participant track control (setMicrophoneEnabled/setCameraEnabled)"
  - "Jest config extended to support .test.tsx files for React component testing"

requirements-completed:
  - COMM-05
  - WEB-02

# Metrics
duration: 18min
completed: 2026-05-16
---

# Phase 04 Plan 04: Web Video Calling UI Summary

**Web video calling experience with LiveKit room integration, Socket.io incoming call handling, and 8 reusable call components following UI-SPEC design contract**

## Performance

- **Duration:** 18 min
- **Started:** 2026-05-16T13:20:00Z
- **Completed:** 2026-05-16T13:38:00Z
- **Tasks:** 4 (including Task 0 checkpoint)
- **Files modified:** 13

## Accomplishments

- Installed and verified LiveKit React packages (@livekit/components-react, livekit-client)
- Created 6 reusable call components with full UI-SPEC compliance (colors, typography, spacing, copy)
- Built call entry page with contact selection and Socket.io incoming call modal
- Implemented dynamic call page with state-based routing (ringing → active → result)
- Integrated LiveKitRoom with token-based authentication and media device error handling
- Created test scaffold with 5 todo entries for web call page

## Task Commits

Each task was committed atomically:

1. **Task 0: Verify and install LiveKit packages** - `ba890b1` (chore)
2. **Task 1: Create reusable call components** - `72756d4` (feat)
3. **Task 2: Create web call pages with LiveKit integration** - `1732995` (feat)
4. **Task 3: Create web call page test scaffold** - `2112bc1` (test)

**Plan metadata:** (pending final commit)

## Files Created/Modified

- `src/components/calls/VideoTile.tsx` — Video tile with permission error, loading, and track states
- `src/components/calls/CallControlBar.tsx` — Mute, camera toggle, end call, connection status
- `src/components/calls/SubtitleOverlay.tsx` — Live subtitle overlay with speaker badge
- `src/components/calls/SignDraftOverlay.tsx` — Sign recognition draft with confidence indicator
- `src/components/calls/IncomingCallModal.tsx` — Accept/Reject modal for incoming calls
- `src/components/calls/CallResult.tsx` — Post-call result screen with state-specific copy
- `src/components/calls/CallEntry.tsx` — Contact selection and call initiation
- `src/components/calls/ActiveCallCanvas.tsx` — LiveKitRoom wrapper with full call UI
- `src/app/calls/page.tsx` — Call entry page with Socket.io incoming call listener
- `src/app/calls/[callId]/page.tsx` — Dynamic call page with state-based routing
- `src/__tests__/web/call-page.test.tsx` — Test scaffold with 5 todo entries
- `jest.config.ts` — Extended to support .test.tsx files
- `package.json` — Added LiveKit and socket.io-client dependencies

## Decisions Made

- Used inline styles for component theming — consistent with existing project patterns (no Tailwind/CSS modules)
- VideoTile accepts `MediaStream` for track prop — maps to LiveKit's `publication.track?.mediaStream`
- ActiveCallCanvas uses `useRoomContext().localParticipant.setMicrophoneEnabled()/setCameraEnabled()` for track control
- Socket.io client connects with `withCredentials: true` for auth cookie-based registration
- Extended Jest config to support `.test.tsx` files (was `.test.ts` only)

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Installed socket.io-client for web Socket.io connectivity**
- **Found during:** Task 2 (web call pages)
- **Issue:** socket.io-client was not in package.json — web client cannot receive call:incoming events without it
- **Fix:** Ran `npm install socket.io-client`
- **Files modified:** package.json, package-lock.json
- **Verification:** `npm list socket.io-client` confirms installed
- **Committed in:** 1732995 (Task 2 commit)

**2. [Rule 2 - Missing Critical] Extended Jest config for .test.tsx support**
- **Found during:** Task 3 (test scaffold)
- **Issue:** Jest testMatch only matched `.test.ts` files, not `.test.tsx` — test file would not be discovered
- **Fix:** Added `'**/__tests__/**/*.test.tsx'` to testMatch and `'^.+\\.(ts|tsx)$'` to transform
- **Files modified:** jest.config.ts
- **Verification:** `npm test -- --runInBand src/__tests__/web/call-page.test.tsx` runs successfully
- **Committed in:** 2112bc1 (Task 3 commit)

**3. [Rule 1 - Bug] Fixed LiveKit API usage in ActiveCallCanvas**
- **Found during:** Task 2 (TypeScript compilation)
- **Issue:** `TrackPublication.setMuted()` does not exist — should use `LocalParticipant.setMicrophoneEnabled()/setCameraEnabled()`; `onMediaDeviceFailure` callback signature mismatch; track type mismatch (Track vs MediaStream)
- **Fix:** Used `useRoomContext()` for local participant control; fixed callback to accept `MediaDeviceFailure`; used `publication.track?.mediaStream` for VideoTile
- **Files modified:** src/components/calls/ActiveCallCanvas.tsx
- **Verification:** `npx tsc --noEmit` shows no errors in call components
- **Committed in:** 1732995 (Task 2 commit)

---

**Total deviations:** 3 auto-fixed (2 missing critical, 1 bug)
**Impact on plan:** All auto-fixes necessary for correctness. No scope creep.

## Known Stubs

| Stub | File | Reason |
|------|------|--------|
| `subtitle` state (empty string) | ActiveCallCanvas.tsx:38 | Plan 05 will wire real sign recognition data |
| `draftText` state (empty string) | ActiveCallCanvas.tsx:39 | Plan 05 will wire real sign recognition data |
| `onSaveTranscript` no-op `() => {}` | [callId]/page.tsx | Transcript save functionality for future plan |
| `/api/users` endpoint | CallEntry.tsx | User list endpoint may not exist yet — shows empty state as fallback |

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag:token_handling | ActiveCallCanvas.tsx | LiveKit token held in React state, passed as prop — not stored in localStorage or URL (matches T-04-14 mitigation) |
| threat_flag:server_auth | [callId]/page.tsx | Call accept via server POST endpoint, token received only after server validates (matches T-04-13 mitigation) |
| threat_flag:rate_limiting | CallEntry.tsx | Call creation goes through server POST /api/calls — server enforces busy check (matches T-04-15 mitigation) |

## Issues Encountered

None beyond documented deviations.

## Next Phase Readiness

- Web call UI foundation complete — LiveKit integration, Socket.io events, all call states handled
- Ready for Plan 05 (sign recognition integration during calls) to wire subtitle and draft data
- Ready for backend GET /api/calls/{id} endpoint if not already implemented
- NEXT_PUBLIC_LIVEKIT_URL env var must be configured for LiveKit server connection

---

*Phase: 04-video-calling*
*Completed: 2026-05-16*
