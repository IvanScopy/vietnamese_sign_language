---
status: complete
phase: 04-video-calling
source: 04-01-SUMMARY.md, 04-02-SUMMARY.md, 04-03-SUMMARY.md, 04-04-SUMMARY.md, 04-05-SUMMARY.md
started: 2026-05-16T12:52:21Z
updated: 2026-05-16T13:15:00Z
---

## Current Test

[testing complete]

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running server/service. Clear ephemeral state. Start Next.js backend from scratch. Server boots without errors, Prisma schema synced, primary API call returns live response.
result: issue
reported: "TypeScript compile error in src/app/lib/validators.ts:38 — z.record(z.string()) called with 1 arg but type definitions expect 2-3. Pre-existing error but affects tsc --noEmit. Multiple pre-existing test-file TS errors also present. Server likely boots (Next.js tolerates TS errors in dev mode) but strict build would fail."
severity: minor

### 2. Mobile HomeScreen — Start Video Call Button
expected: HomeScreen shows 'Start video call' button. Tapping it navigates to outgoing call screen with ringing state and Cancel button.
result: issue
reported: "Button exists and is visible, but it navigates to /calls/incoming (IncomingCallScreen with callId=0, fromUserName='Demo Caller') instead of outgoing call screen. Known stub per SUMMARY: 'Uses hardcoded callId=0 for demo; real contact picker needed'. Functional flow is wrong — user sees incoming call UI as caller."
severity: major

### 3. Mobile Incoming Call Screen
expected: Incoming call screen appears with caller name, Accept (green) and Reject (red) buttons. Accept navigates to active call screen. Reject dismisses.
result: issue
reported: "Screen code is correct but Flutter app WON'T COMPILE due to Bug in main.dart:130 — ActiveCallScreen route is missing 3 required named parameters: config, authToken, currentUserType. Flutter analyze confirms: 3 missing_required_argument errors. App cannot build."
severity: blocker

### 4. Mobile Active Call Screen — Video and Controls
expected: Remote video fills screen, local preview tile in corner, Mute/Camera/End controls work, End Call navigates to result screen.
result: issue
reported: "Code is well-implemented (LiveKit, VideoTrackRenderer, control bar, translation overlay all present) but app CANNOT BUILD due to main.dart missing required params for ActiveCallScreen (same blocker as Test 3). Cannot reach this screen."
severity: blocker

### 5. Mobile Call Result Screen
expected: State-specific copy after call ends. Save/Discard transcript buttons visible. Discard shows confirmation dialog.
result: pass

### 6. Web Call Entry Page (/calls)
expected: Contact selection page at /calls. Selecting contact + clicking call initiates outgoing call via POST /api/calls.
result: pass

### 7. Web Incoming Call Modal
expected: Incoming call triggers overlay modal via Socket.io call:incoming event, no page reload. Accept/Reject buttons present.
result: pass

### 8. Web Active Call Page (/calls/[callId])
expected: Dynamic call page fetches call state, renders LiveKit room for active calls, handles ringing/active/terminal states.
result: issue
reported: "Critical missing endpoint: GET /api/calls/[callId] route does not exist. The /api/calls/[callId]/ directory only has accept/, cancel/, end/, reject/, token/, transcript/ sub-routes — no root route.ts for GET. The web call page calls GET /api/calls/${callId} on mount; without this endpoint it always hits the error state and shows CallResult 'failed'. Additionally, when state is ACTIVE, page re-calls POST /accept to get token instead of using the dedicated POST /token endpoint — would fail on an already-accepted call."
severity: blocker

### 9. Mobile Sign Draft Overlay (Deaf User Mode)
expected: Sign draft overlay above control bar during active call. Confirm sends text. Confirm & Play triggers TTS. Low-confidence shows amber 'Unclear' label.
result: issue
reported: "Overlay widget implementation is correct (positioned at bottom:88, deaf/hearing modes, Confirm/Confirm & Play, low-confidence amber label). BUT cannot reach this screen because Flutter app won't compile (same blocker as Tests 3-4). Additionally sendTranscriptToHearingUser is a v1 no-op placeholder per SUMMARY known stubs."
severity: blocker

### 10. Mobile STT Subtitles (Hearing User Mode)
expected: During active call as hearing user, spoken words appear as live subtitles overlay.
result: skipped
reason: Known stub per SUMMARY — 'Speech capture lifecycle needs parent screen coordination for continuous STT loop' and '_receivedSignText always empty'. Overlay structure exists but STT loop is not wired.

### 11. Web Sign Draft Overlay — Confirm & Play
expected: SignDraftOverlay on web call page shows sign text, Confirm/Confirm & Play buttons work.
result: skipped
reason: Known stub per SUMMARY — draftText state is always empty string, wired to sign recognition 'when backend is ready'. Overlay component exists and renders when draftText is non-empty, but nothing populates it in v1.

### 12. FCM Push Notification — Background Incoming Call
expected: App in background receives push notification. Tapping opens incoming call screen.
result: blocked
blocked_by: physical-device
reason: Requires Firebase config (google-services.json, GoogleService-Info.plist) and physical device. PushNotificationService code is correct — routes VIDEO_CALL type to /calls/incoming via navigatorKey. Gracefully degrades when Firebase not configured. Cannot test without real device + FCM setup.

## Summary

total: 12
passed: 2
issues: 6
pending: 0
skipped: 2
blocked: 1

## Gaps

- truth: "Flutter app builds and ActiveCallScreen is reachable"
  status: failed
  reason: "User reported: main.dart:130 missing 3 required params for ActiveCallScreen constructor — config (AppConfig), authToken (String), currentUserType (UserType). Flutter analyze: 3 missing_required_argument errors. App cannot build."
  severity: blocker
  test: 3
  root_cause: "Plan 05 added config/authToken/currentUserType to ActiveCallScreen constructor but did not update the /calls/active route builder in main.dart. The route still uses the Plan 03 signature."
  artifacts:
    - path: "mobile/lib/main.dart"
      issue: "Line 130 — ActiveCallScreen missing required params: config, authToken, currentUserType"
    - path: "mobile/lib/screens/calls/active_call_screen.dart"
      issue: "Constructor requires config, authToken, currentUserType (added in Plan 05)"
  missing:
    - "Pass config: widget.config (available in VSLBridgeApp), authToken: authToken, currentUserType: UserType.deaf (default or derive from stored prefs)"

- truth: "Mobile HomeScreen 'Start video call' navigates to outgoing call screen"
  status: failed
  reason: "User reported: Button routes to /calls/incoming (IncomingCallScreen) instead of /calls/outgoing. Known stub per Plan 03 SUMMARY."
  severity: major
  test: 2
  root_cause: "main.dart HomeScreen 'Start video call' button intentionally routes to incoming screen as demo stub (no contact picker yet). Real outgoing call flow requires user selection before initiating call."
  artifacts:
    - path: "mobile/lib/main.dart"
      issue: "pushNamed('/calls/incoming', ...) should be a contact picker → /calls/outgoing flow"
  missing:
    - "Contact picker or demo outgoing call flow routing to /calls/outgoing with a valid callId"

- truth: "GET /api/calls/[callId] endpoint exists and returns call state"
  status: failed
  reason: "User reported: /api/calls/[callId]/ directory has no route.ts for GET. Web call page calls GET /api/calls/${callId} on mount and hits 404, always showing error/failed state."
  severity: blocker
  test: 8
  root_cause: "Plan 04 created POST routes under /api/calls/[callId]/ (accept, reject, cancel, end, token) but did not create the root GET route.ts. The web call page was implemented to fetch call state via GET but the endpoint was never planned/built."
  artifacts:
    - path: "src/app/calls/[callId]/page.tsx"
      issue: "Calls GET /api/calls/${callId} on mount — endpoint missing"
    - path: "src/app/api/calls/[callId]/"
      issue: "Missing route.ts for GET method"
  missing:
    - "Create src/app/api/calls/[callId]/route.ts with GET handler: auth check, verify participant, return CallSession fields (id, state, roomName, callerId, calleeId, callerName, calleeName)"
    - "Fix web call page: when state is ACTIVE, fetch token via POST /token not POST /accept"

- truth: "src/app/lib/validators.ts compiles without TypeScript errors"
  status: failed
  reason: "User reported: z.record(z.string()) on line 38 triggers TS2554 'Expected 2-3 arguments, but got 1' — likely Zod type definitions mismatch."
  severity: minor
  test: 1
  root_cause: "z.record() in this Zod version requires explicit key type: z.record(z.string(), z.string()). Current call passes only value type."
  artifacts:
    - path: "src/app/lib/validators.ts"
      issue: "Line 38: z.record(z.string()) — missing key type argument"
  missing:
    - "Change to z.record(z.string(), z.string()) or z.record(z.union([z.string(), z.number()]), z.string())"
