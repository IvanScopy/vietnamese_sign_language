---
phase: 04-video-calling
plan: 08
subsystem: video-calling
tags: [gap-closure, backend, web, mobile, signaling, transcript, tests]

requires:
  - phase: 04-06
    provides: Call-state GET endpoint and active-token flow
  - phase: 04-07
    provides: Mobile active route and outgoing call entry flow
provides:
  - Safe reject/cancel lifecycle transitions
  - Accept response without cross-participant token leakage
  - Web user lookup, socket registration, invalid-call handling, and server-authoritative end-call flow
  - Mobile outgoing signaling connection and FCM string callId parsing
  - Bearer-auth transcript saving and transcript relay event
  - Green backend Jest, Flutter test, and Flutter analyzer gates
affects: [phase-04-verification, COMM-05, WEB-02, NOTIF-01]

tech-stack:
  added: []
  patterns:
    - "Cookie-or-Bearer API auth via getAuthenticatedUser"
    - "Server-authenticated Socket.io room join from bearer token"
    - "Confirmed transcript text carried explicitly to save endpoints"

key-files:
  created:
    - src/app/api/users/route.ts
  modified:
    - src/lib/calls.ts
    - src/app/api/calls/[callId]/accept/route.ts
    - src/app/api/calls/[callId]/reject/route.ts
    - src/app/api/calls/[callId]/cancel/route.ts
    - src/app/api/calls/[callId]/transcript/route.ts
    - src/app/calls/page.tsx
    - src/app/calls/[callId]/page.tsx
    - src/app/lib/socket.ts
    - src/components/calls/ActiveCallCanvas.tsx
    - src/components/calls/CallResult.tsx
    - mobile/lib/main.dart
    - mobile/lib/config/app_config.dart
    - mobile/lib/screens/calls/active_call_screen.dart
    - mobile/lib/screens/calls/call_result_screen.dart
    - mobile/lib/screens/calls/outgoing_call_screen.dart
    - mobile/lib/services/call_signaling_service.dart
    - mobile/lib/services/call_transcription_service.dart
    - mobile/lib/widgets/call_translation_overlay.dart
    - mobile/lib/services/sos_location_service.dart
    - src/__tests__/calls/call-lifecycle.test.ts
    - src/__tests__/notifications/push.test.ts
    - src/__tests__/web/call-page.test.tsx

requirements-completed: [COMM-05, WEB-02, NOTIF-01]

duration: 55min
completed: 2026-05-16
---

# Phase 04 Plan 08: Verification Gap Closure Summary

## Accomplishments

- Fixed unsafe reject/cancel behavior by checking `updateMany.count` before routes emit terminal events.
- Removed `callerToken` from the callee accept response and added `callId`, `id`, and `state` fields so mobile can end accepted calls against the real call.
- Added authenticated `/api/users` for web call contact selection.
- Made Socket.io join `user:{id}` rooms from authenticated bearer handshakes, while keeping explicit web `register` support.
- Changed web active-call teardown so media-error and normal exits call `/api/calls/{callId}/end` before result navigation.
- Added strict positive call-id parsing for web call pages and mobile notification routes.
- Made transcript save usable from mobile Bearer auth and web cookie auth, with server transcript relay events for the other participant.
- Connected mobile outgoing signaling and disposed the owned signaling service when the screen ends.
- Made `AppConfig.create` provide a default LiveKit URL so existing widget tests compile.
- Fixed one full-analyzer issue in SOS location service that blocked `flutter analyze`.

## Verification

- `npm test -- --runInBand` - passed: 20 suites passed, 1 skipped; 103 tests passed, 33 todo.
- `cd mobile && flutter test` - passed: all tests passed.
- `cd mobile && flutter analyze` - passed: no issues found.
- Targeted Phase 4 checks passed:
  - `src/__tests__/calls/call-lifecycle.test.ts`
  - `src/__tests__/web/call-page.test.tsx`
  - `src/__tests__/notifications/push.test.ts`
  - `src/__tests__/notifications/register-token.test.ts`
  - `src/__tests__/calls/call-state-route.test.ts`
  - `mobile/test/widgets/call_navigation_gap_test.dart`
  - `mobile/test/widgets/camera_preview_test.dart`
  - `mobile/test/widgets/conversation_screen_test.dart`

## Residual Human UAT

- Real two-party LiveKit call testing still requires configured LiveKit, camera/microphone permissions, and two registered users.
- Physical mobile background/terminated FCM notification-open testing still requires Firebase project files and a device.
- Translation relay now writes confirmed text to the transcript API and emits a server event, but true cross-device display still needs end-to-end UAT with connected clients.

## Typecheck Note

`npx tsc --noEmit` still reports pre-existing project-wide TypeScript issues in shared landmark typings and Jest mock typing files. The Phase 4 runtime/test paths changed in this plan are covered by passing Jest, Flutter tests, and Flutter analyzer.
