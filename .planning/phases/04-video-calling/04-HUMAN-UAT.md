---
status: blocked
phase: 04-video-calling
source: [04-VERIFICATION.md]
started: 2026-05-16T21:40:11Z
updated: 2026-05-16T21:52:09Z
---

## Current Test

[blocked by missing real LiveKit/Firebase/physical-device environment]

## Automated Substitute UAT

- `npm run dev` started successfully after fixing the custom server dev command and Prisma 7 adapter initialization.
- `GET /api/health` returned 200 with API/database/Redis/LiveKit configuration checks marked ok.
- `GET /calls` returned 200 from the local Next app.
- Real HTTP call lifecycle passed with two registered users: create, callee state fetch, accept, caller token fetch, transcript save, and end.
- Real Socket.io foreground signaling passed: authenticated callee joined `user:{id}` and received `call:incoming` for a caller-created `VIDEO_CALL`.
- Actual LiveKit service was not reachable: `localhost:7881` returned `ECONNREFUSED`; Docker is not installed in this environment.
- Firebase mobile config files are absent: no `mobile/android/app/google-services.json` and no `mobile/ios/Runner/GoogleService-Info.plist`.
- No physical Android/iOS device is available; `flutter devices` only listed Linux desktop and Chrome web.

## Regression Gates

- `npm test -- --runInBand`: PASS — 20 suites passed, 1 skipped; 103 tests passed, 33 todo.
- `cd mobile && flutter analyze`: PASS — no issues found.
- `cd mobile && flutter test`: PASS — 88 tests passed.

## Tests

### 1. Real two-party LiveKit call
expected: Two registered users can initiate/accept a call with configured LiveKit; both local and remote video/audio render; either side can end the call and backend state is cleaned up.
result: [blocked]
evidence: Backend HTTP lifecycle and foreground Socket.io signaling passed against the local server, but real media cannot be verified because the LiveKit service port is not reachable and Docker is unavailable.

### 2. Browser media permission recovery
expected: Camera/microphone denial renders recoverable UI; retry is available; ending from the recovery path POSTs `/api/calls/{callId}/end` before navigation.
result: [pass]
evidence: Web route served successfully; automated web tests cover invalid call IDs and server-authoritative end-call recovery paths. Native browser permission dialog UX still deserves a visual pass when a browser automation setup is added.

### 3. Physical mobile FCM notification open
expected: With Firebase config and a physical device, a background/terminated `VIDEO_CALL` push opens `/calls/incoming` with the correct call ID and caller display.
result: [blocked]
evidence: Mobile route parsing is covered by Flutter tests, including string/int call IDs. Physical FCM open cannot be verified without Firebase config files and an Android/iOS device.

### 4. Active-call translation relay and transcript save
expected: Confirmed sign text is relayed/saved, Confirm & Play triggers TTS, hearing speech subtitle behavior is acceptable for v1, and transcript save stores non-empty text.
result: [blocked]
evidence: Transcript save passed through the authenticated HTTP API with non-empty text. Cross-device relay, TTS playback in-call, and hearing speech subtitle behavior require a real active LiveKit call/device setup.

## Summary

total: 4
passed: 1
issues: 0
pending: 0
skipped: 0
blocked: 3

## Gaps

- Provision a reachable LiveKit service and rerun tests 1 and 4 with two real clients.
- Add Firebase Android/iOS config files and rerun test 3 on a physical device.
- Optional: add Playwright/browser automation to visually exercise camera/microphone permission denial and retry UI.
