---
phase: 04-video-calling
verified: 2026-05-16T21:40:11Z
status: human_needed
score: "35/38 automated/substitute UAT checks verified; 3 blocked by missing real service/device environment"
overrides_applied: 0
human_verification:
  - description: "Run a real two-party LiveKit call with two registered users and configured LiveKit server."
    expected: "Both users can initiate/accept, see local and remote video/audio, and either side can end the call with server state cleaned up."
  - description: "Test browser media permission denial/retry/end-call recovery."
    expected: "Permission failures render recoverable UI and all exit paths POST /api/calls/{callId}/end before navigation."
  - description: "Test mobile background/terminated VIDEO_CALL push open on a physical device."
    expected: "FCM payload opens /calls/incoming with the correct string or integer callId and caller display."
  - description: "Test cross-device translation relay during a real active call."
    expected: "Confirmed sign text is saved/relayed, TTS playback works for Confirm & Play, and transcript save stores non-empty text."
residual_risks:
  - "npx tsc --noEmit still reports pre-existing project-wide typing issues in shared landmark definitions and Jest mock files; runtime Phase 4 gates passed."
  - "Real media and physical push UAT are blocked until LiveKit, Firebase config files, and an Android/iOS device are available."
---

# Phase 4: Video Calling Verification Report

**Phase Goal:** Add 1:1 in-app video calls between registered users, with integrated translation surfaces but no v1 avatar dependency.  
**Verified:** 2026-05-16T21:40:11Z  
**Status:** human_needed

## Result

Automated Phase 4 verification now passes for the prior blocker set, and substitute UAT was run against the local server. The remaining checks require real LiveKit/Firebase/device conditions that cannot be truthfully verified from this terminal session.

## Substitute UAT Results

| UAT Item | Result | Evidence |
|---|---|---|
| Real HTTP two-user call lifecycle | PASS | Registered caller/callee, created call, callee fetched state, callee accepted, caller fetched token, callee saved non-empty transcript, caller ended call. |
| Foreground Socket.io incoming call | PASS | Authenticated callee socket joined the user room and received `call:incoming` for the caller-created `VIDEO_CALL`. |
| Browser calls route availability | PASS | `GET /calls` returned HTTP 200 from the local dev server. |
| Real LiveKit media | BLOCKED | `localhost:7881` returned `ECONNREFUSED`; Docker is not installed, so a LiveKit container could not be started here. |
| Physical FCM notification open | BLOCKED | Firebase Android/iOS config files are absent and no Android/iOS physical device is available. |
| Real cross-device translation relay | BLOCKED | Transcript API save passed, but relay/TTS/subtitle behavior needs a real active LiveKit call. |

## Automated Checks

| Check | Result |
|---|---|
| `npm test -- --runInBand` | PASS: 20 suites passed, 1 skipped; 103 tests passed, 33 todo |
| `cd mobile && flutter test` | PASS: 88 tests passed |
| `cd mobile && flutter analyze` | PASS: no issues found |
| `npm test -- --runInBand src/__tests__/calls/call-lifecycle.test.ts src/__tests__/web/call-page.test.tsx src/__tests__/notifications/push.test.ts src/__tests__/notifications/register-token.test.ts src/__tests__/calls/call-state-route.test.ts` | PASS |
| `cd mobile && flutter test test/widgets/call_navigation_gap_test.dart test/widgets/camera_preview_test.dart test/widgets/conversation_screen_test.dart` | PASS |

## Must-Have Verification

| # | Source | Truth | Status | Evidence |
|---|---|---|---|---|
| 1 | ROADMAP | Registered users can initiate, receive, accept, reject, and end 1:1 calls. | AUTOMATED PASS | Create/accept/reject/cancel/end routes exist; reject/cancel now fail on zero-row unauthorized transitions; accept returns call identity and only the caller's own token path is used through `/token`. Real two-user call UAT remains. |
| 2 | ROADMAP | Both video feeds render reliably during a call. | BLOCKED UAT | LiveKit web/mobile components and services are wired, but real camera/audio rendering requires configured LiveKit and devices; local LiveKit port is currently unreachable. |
| 3 | ROADMAP | Deaf user's signs can be shown as text and/or TTS output to the hearing user. | PARTIAL AUTOMATED PASS / BLOCKED UAT | Mobile active calls connect recognition service; confirmed text posts to transcript API and emits transcript relay. Cross-device display/TTS still needs real UAT. |
| 4 | ROADMAP | Hearing user's speech can be shown as subtitles to the deaf user. | HUMAN NEEDED | STT service exists and overlay structure remains; real microphone/STT loop needs active-call device UAT. |
| 5 | ROADMAP | Incoming call notifications work when foregrounded and have a path for background delivery. | AUTOMATED PASS + BLOCKED UAT | Socket.io room join is restored from authenticated handshake/web register and was verified with a real socket client; `/calls/incoming` accepts string callId. Physical FCM open still requires Firebase/device UAT. |
| 6 | ROADMAP | Call setup and teardown handle permission and network errors gracefully. | AUTOMATED PASS | Web media-error exits now call `/end`; invalid web call IDs render failure; mobile analyzer/tests pass. |
| 7 | 04-01 | CallSession rows exist with callerId, calleeId, roomName, state, expiresAt. | PASS | Prisma schema defines CallSession and CallState. |
| 8 | 04-01 | Call state transitions are atomic and race-safe. | PASS | `acceptCall`, `rejectCall`, `cancelCall`, and `endCall` check guarded update results where needed. |
| 9 | 04-02 | Accept returns participant-safe LiveKit tokens. | PASS | `/accept` returns only callee token plus `callId`, `id`, `state`, and `roomName`; caller token is fetched through authenticated `/token`. |
| 10 | 04-02 | Reject/cancel/end emit only after authorized transitions. | PASS | `rejectCall` and `cancelCall` throw `Call unavailable` when `updateMany.count !== 1`; routes return 409 and do not emit success events. |
| 11 | 04-03 | Mobile outgoing calls receive lifecycle signaling. | PASS | `OutgoingCallScreen` now connects `CallSignalingService`; service marks connection true and stream listeners can resolve accepted/rejected/missed/busy. |
| 12 | 04-03 | Mobile push notification routing remains available. | PASS | `/calls/incoming` parses `callId` from int or string and renders an invalid notification screen instead of crashing. |
| 13 | 04-04 | Web users can select registered users and start a call. | PASS | Added authenticated `/api/users`; web calls page fetches profile/users and CallEntry POSTs `/api/calls`. |
| 14 | 04-04 | Web users receive foreground incoming call events. | PASS | Server authenticates socket handshakes into `user:{id}` rooms; web also emits `register` after profile load. |
| 15 | 04-04 | Invalid web call IDs fail visibly. | PASS | `parsePositiveCallId` rejects invalid/zero params and the page renders a failed result. |
| 16 | 04-05 | Transcript saving stores non-empty text. | PASS | Transcript route accepts cookie or Bearer auth, requires non-empty text, stores rows, and emits `call:transcript`. Mobile/web save paths now pass collected text instead of empty strings/no-op handlers. |

## Requirements Coverage

| Requirement | Status | Notes |
|---|---|---|
| COMM-05 | BLOCKED UAT | Automated lifecycle, transcript, route, and socket blockers are fixed; real two-party LiveKit media still needs configured service/device validation. |
| WEB-02 | AUTOMATED PASS | Web flow, token, teardown, and invalid route handling are fixed and covered by tests/local route checks. |
| NOTIF-01 | PARTIAL PASS / BLOCKED UAT | Foreground socket and notification route parsing are fixed and verified; background FCM open needs Firebase config and physical-device validation. |

## Human Verification Items

1. Real LiveKit call with two registered users: both local and remote video/audio render and either participant can end the call.
2. Mobile background/terminated VIDEO_CALL push: FCM opens incoming call screen with correct call ID and caller display.
3. Translation relay in a real active call: confirmed sign text and hearing-user speech/subtitles behave correctly enough for v1, and transcript save stores non-empty text.

## Residual Typecheck Note

`npx tsc --noEmit` still fails on pre-existing project-wide TypeScript issues outside the Phase 4 runtime path, including `shared/types/landmarks.ts`, `src/__tests__/auth/google.test.ts`, and Jest mock typing in older health/TTS setup files. Jest and Flutter runtime gates are green.

---

_Verified: 2026-05-16T21:40:11Z_
