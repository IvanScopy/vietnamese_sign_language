---
phase: 04-video-calling
plan: 03
subsystem: mobile
tags: [flutter, livekit, firebase, fcm, socket.io, video-calling]

# Dependency graph
requires:
  - phase: 04-01
    provides: LiveKit server infrastructure and backend call API endpoints
  - phase: 04-02
    provides: Web call UI patterns and Socket.io signaling contract
provides:
  - CallState enum and CallSession data model with JSON serialization
  - CallApiService: HTTP client for all call lifecycle endpoints
  - CallSignalingService: Socket.io client for 7 server-emitted call events
  - LiveKitCallService: Room connection with camera/microphone publishing
  - PushNotificationService: FCM init, token registration, notification routing
  - Four call screens: incoming, outgoing, active, result
  - HomeScreen "Start video call" entry button
  - Test scaffolds for API service, push notification, and active call screen
affects: [04-04, 04-05, 05-sos]

# Tech tracking
tech-stack:
  added: [livekit_client ^2.7.0, firebase_core ^4.9.0, firebase_messaging ^16.2.2]
  patterns:
    - "Service-per-concern: separate API, signaling, LiveKit, and push notification services"
    - "Stream-based event handling for Socket.io (broadcast StreamControllers)"
    - "onGenerateRoute for complex route arguments (call sessions, state objects)"
    - "Global navigatorKey for push notification deep-linking"

key-files:
  created:
    - mobile/lib/models/call_state.dart
    - mobile/lib/services/call_api_service.dart
    - mobile/lib/services/call_signaling_service.dart
    - mobile/lib/services/livekit_call_service.dart
    - mobile/lib/services/push_notification_service.dart
    - mobile/lib/screens/calls/incoming_call_screen.dart
    - mobile/lib/screens/calls/outgoing_call_screen.dart
    - mobile/lib/screens/calls/active_call_screen.dart
    - mobile/lib/screens/calls/call_result_screen.dart
    - mobile/test/services/call_api_service_test.dart
    - mobile/test/services/push_notification_service_test.dart
    - mobile/test/widgets/active_call_screen_test.dart
  modified:
    - mobile/pubspec.yaml
    - mobile/lib/config/app_config.dart
    - mobile/lib/main.dart

key-decisions:
  - "Used onGenerateRoute instead of routes map for call screens requiring typed arguments"
  - "PushNotificationService gracefully handles missing Firebase config — foreground Socket.io still works"
  - "LiveKit RoomOptions passed in Room constructor (not connect) per livekit_client 2.7.0 API"
  - "Flutter test.skip used instead of test.todo (not supported in flutter_test)"

patterns-established:
  - "Service-per-concern: separate API, signaling, LiveKit, and push notification services"
  - "Stream-based event handling for Socket.io (broadcast StreamControllers)"
  - "onGenerateRoute for complex route arguments (call sessions, state objects)"
  - "Global navigatorKey for push notification deep-linking"

requirements-completed: [COMM-05, NOTIF-01]

# Metrics
duration: 15min
completed: 2026-05-16
---

# Phase 04 Plan 03: Mobile Call Experience Summary

**Flutter mobile call flow: four screens (incoming/outgoing/active/result), four services (API/Socket.io/LiveKit/FCM), CallState model, and HomeScreen video call entry**

## Performance

- **Duration:** 15 min
- **Started:** 2026-05-16T06:06:36Z
- **Completed:** 2026-05-16T06:22:21Z
- **Tasks:** 4 (Task 0 checkpoint + Tasks 1-3 auto)
- **Files modified:** 13 (3 config/dep, 5 services, 4 screens, 1 main, 3 test)

## Accomplishments

- CallState model (8 states) + CallSession with JSON serialization and copyWith
- Four call services: HTTP API client, Socket.io signaling (7 streams), LiveKit room connection, FCM push notification
- Four call screens with UI-SPEC colors (#16A34A green, #DC2626 red), stale-push verification, and recoverable permission error handling
- main.dart wired with 4 call routes via onGenerateRoute, PushNotificationService init, and "Start video call" button
- Test scaffolds with 24 skipped test entries across 3 test files

## Task Commits

Each task was committed atomically:

1. **Task 0: Verify packages and add dependencies** - `c266c73` (chore)
2. **Task 1: Create CallState model and four call services** - `2224e79` (feat)
3. **Task 2: Create four call screens and wire routing** - `6f5f6a4` (feat)
4. **Task 3: Create Wave 0 test scaffolds** - `aac8a65` (test)

## Files Created/Modified

- `mobile/pubspec.yaml` — Added livekit_client, firebase_core, firebase_messaging
- `mobile/lib/config/app_config.dart` — Added liveKitUrl field with VSL_LIVEKIT_URL env var
- `mobile/lib/models/call_state.dart` — CallState enum (8 values), CallSession class with fromJson/toJson
- `mobile/lib/services/call_api_service.dart` — HTTP client: createCall, acceptCall, rejectCall, cancelCall, endCall, getToken, getCallState
- `mobile/lib/services/call_signaling_service.dart` — Socket.io client: 7 broadcast streams for server-emitted events (read-only)
- `mobile/lib/services/livekit_call_service.dart` — LiveKit room connect with adaptiveStream/dynacast, camera/mic toggle
- `mobile/lib/services/push_notification_service.dart` — FCM init, token registration, VIDEO_CALL routing to /calls/incoming
- `mobile/lib/screens/calls/incoming_call_screen.dart` — Full-screen incoming call with Accept/Reject, stale-push verification
- `mobile/lib/screens/calls/outgoing_call_screen.dart` — Ringing UI with Cancel, signaling listeners for state transitions
- `mobile/lib/screens/calls/active_call_screen.dart` — Remote video via LiveKit, local preview tile, control bar (mute/camera/end)
- `mobile/lib/screens/calls/call_result_screen.dart` — State-specific copy, transcript save prompt, retry for failed
- `mobile/lib/main.dart` — 4 call routes via onGenerateRoute, PushNotificationService init, "Start video call" button
- `mobile/test/services/call_api_service_test.dart` — 10 skipped test entries
- `mobile/test/services/push_notification_service_test.dart` — 6 skipped test entries
- `mobile/test/widgets/active_call_screen_test.dart` — 8 skipped test entries

## Decisions Made

- Used `onGenerateRoute` instead of `routes` map for call screens that require typed arguments (CallSession, CallState)
- PushNotificationService gracefully handles missing Firebase config — logs warning and continues; foreground Socket.io signaling still works
- LiveKit `RoomOptions` passed in `Room()` constructor (not `connect()`) per livekit_client 2.7.0 API
- Flutter `test.skip` used instead of `test.todo` (not supported in flutter_test framework)
- IncomingCallScreen uses solid green dot indicator (no flashing/pulsing) per D-17 accessibility requirement

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed livekit_client API incompatibilities**
- **Found during:** Task 1 (LiveKitCallService creation)
- **Issue:** `roomOptions` parameter deprecated in `connect()` — must be in `Room()` constructor. `microphoneTrack` getter doesn't exist on `LocalParticipant`.
- **Fix:** Moved `RoomOptions(adaptiveStream: true, dynacast: true)` to `Room()` constructor. Used `isMicrophoneEnabled()`/`setMicrophoneEnabled()` instead of `microphoneTrack`.
- **Files modified:** mobile/lib/services/livekit_call_service.dart
- **Verification:** Dart analyze passes with no issues
- **Committed in:** 2224e79 (Task 1 commit)

**2. [Rule 3 - Blocking] Fixed outgoing_call_screen listener syntax**
- **Found during:** Task 2 (OutgoingCallScreen creation)
- **Issue:** Invalid Dart syntax for listener callbacks — `_navigateToResult(CallState.rejected, data)` is not valid function definition.
- **Fix:** Rewrote each listener as inline closure with proper type annotations.
- **Files modified:** mobile/lib/screens/calls/outgoing_call_screen.dart
- **Verification:** Dart analyze passes with no issues
- **Committed in:** 6f5f6a4 (Task 2 commit)

**3. [Rule 3 - Blocking] Fixed Flutter test.todo not supported**
- **Found during:** Task 3 (Test scaffold creation)
- **Issue:** `test.todo()` is a Jest/Vitest feature, not available in Flutter's flutter_test.
- **Fix:** Used `test('name', () {}, skip: true)` pattern instead.
- **Files modified:** mobile/test/services/call_api_service_test.dart, mobile/test/services/push_notification_service_test.dart, mobile/test/widgets/active_call_screen_test.dart
- **Verification:** `flutter test` runs without errors (all tests skipped)
- **Committed in:** aac8a65 (Task 3 commit)

---

**Total deviations:** 3 auto-fixed (3 blocking)
**Impact on plan:** All auto-fixes necessary for correctness and compilation. No scope creep.

## Issues Encountered

- None beyond the deviations documented above.

## Known Stubs

| Stub | File | Line/Location | Reason |
|------|------|---------------|--------|
| Camera switching | active_call_screen.dart | Switch button onPressed | To be implemented in Plan 05 (translation overlays + camera switching) |
| Open settings button | active_call_screen.dart | _PermissionErrorScreen | Requires platform-specific settings URL launcher |
| Transcript save | call_result_screen.dart | Save transcript button | Requires conversation history integration |
| Demo caller navigation | main.dart | HomeScreen "Start video call" | Uses hardcoded callId=0 for demo; real contact picker needed |

## User Setup Required

**External services require manual configuration.** See 04-USER-SETUP.md for:
- Firebase project setup (google-services.json, GoogleService-Info.plist)
- FCM token registration endpoint configuration
- LiveKit server URL configuration (VSL_LIVEKIT_URL env var)

## Next Phase Readiness

- Mobile call flow is structurally complete: incoming → accept → active → end → result
- All services compile and analyze cleanly
- Test scaffolds ready for Wave 1 implementation
- **Blocker:** Firebase config files (google-services.json, GoogleService-Info.plist) needed for push notifications to work on device
- **Ready for:** Plan 04-04 (web call UI), Plan 04-05 (call translation overlays)

---
*Phase: 04-video-calling*
*Completed: 2026-05-16*
