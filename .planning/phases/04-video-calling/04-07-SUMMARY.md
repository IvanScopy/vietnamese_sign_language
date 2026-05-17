---
phase: 04-video-calling
plan: 07
subsystem: video-calling
tags: [flutter, navigation, active-call, outgoing-call, widget-test, uat-gap]

# Dependency graph
requires:
  - phase: 04-03
    provides: Mobile call screens, call API service, call models, and route skeletons
  - phase: 04-05
    provides: ActiveCallScreen constructor with config/authToken/currentUserType requirements
provides:
  - /calls/active route wiring compatible with the current ActiveCallScreen constructor
  - HomeScreen outgoing call initiation flow using CallApiService.createCall
  - Regression widget tests for active route defaults and outgoing call navigation
affects: [phase-04-verification, mobile-call-uat, notif-01-routing]

# Tech tracking
tech-stack:
  added: []
  patterns: [Optional widget test seams for async route actions, default deaf-user-first UserType route argument]

key-files:
  created:
    - mobile/test/widgets/call_navigation_gap_test.dart
  modified:
    - mobile/lib/main.dart
    - mobile/lib/screens/calls/active_call_screen.dart

key-decisions:
  - "The /calls/active route defaults currentUserType to UserType.deaf when no route argument is provided, matching the v1 deaf-user-first mobile default."
  - "HomeScreen now prompts for a numeric callee ID and starts outgoing calls via CallApiService.createCall instead of opening the incoming-call demo route."
  - "The /calls/incoming route remains intact for VIDEO_CALL push notification routing."

patterns-established:
  - "HomeScreen accepts optional CallApiService and SelectCalleeId seams so widget tests can exercise async call creation without a backend."
  - "Outgoing call navigation passes callId and calleeName through /calls/outgoing route arguments."

requirements-completed: [COMM-05, NOTIF-01]

# Metrics
duration: 8min
completed: 2026-05-16
---

# Phase 04 Plan 07: Mobile Call Navigation Gap Closure Summary

**Flutter active-call route wiring and HomeScreen outgoing call initiation for Phase 4 mobile UAT**

## Performance

- **Duration:** 8 min
- **Started:** 2026-05-16T15:10:00Z
- **Completed:** 2026-05-16T15:18:00Z
- **Tasks:** 3
- **Files modified:** 3

## Accomplishments

- Updated `/calls/active` to pass `config`, `authToken`, and `currentUserType` into `ActiveCallScreen`.
- Preserved the missing `callSession` fallback for invalid active-call route arguments.
- Replaced the HomeScreen incoming-call demo shortcut with a real outgoing call flow using `CallApiService.createCall(calleeId)`.
- Added callee ID selection and validation with visible SnackBar feedback for invalid input and API errors.
- Preserved `/calls/incoming` route handling for push notification opens.
- Added widget tests for active route defaults, prevention of incoming demo navigation, and outgoing route navigation after call creation.

## Task Commits

Each task was committed atomically:

1. **Task 1: Fix /calls/active route constructor arguments** - `b913f51` (fix)
2. **Task 2: Replace HomeScreen incoming demo stub with outgoing call initiation** - `4190830` (fix)
3. **Task 3: Add mobile regression tests for call navigation gaps** - `37753b5` (test)

## Files Created/Modified

- `mobile/lib/main.dart` - Imports `UserType`, supplies ActiveCallScreen route args, and starts outgoing calls from HomeScreen.
- `mobile/lib/screens/calls/active_call_screen.dart` - Marks `_ownsRecognitionService` final to satisfy the required analyzer command.
- `mobile/test/widgets/call_navigation_gap_test.dart` - Widget tests covering active route defaults and HomeScreen outgoing call navigation.

## Decisions Made

- Used a numeric callee ID dialog for v1 because no contact picker exists yet in the current app shell.
- Kept the HomeScreen production constructor compatible while adding optional seams for widget tests.
- Used `session.fromUserName ?? 'User $calleeId'` for outgoing screen display text, matching the plan and current `CallSession` model.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 3 - Blocking] Fixed analyzer lint in ActiveCallScreen**
- **Found during:** Task 1 analyzer verification
- **Issue:** `flutter analyze lib/main.dart lib/screens/calls/active_call_screen.dart` failed because `_ownsRecognitionService` could be final.
- **Fix:** Changed `_ownsRecognitionService` to `final`.
- **Files modified:** `mobile/lib/screens/calls/active_call_screen.dart`
- **Verification:** Analyzer command passed with no issues.
- **Committed in:** `b913f51`

---

**Total deviations:** 1 auto-fixed (1 blocking)
**Impact on plan:** The change was a local lint fix required by the plan's own analyzer command. No runtime behavior changed.

## Issues Encountered

- `pumpAndSettle()` could not be used on the ActiveCallScreen route test because the screen shows a loading spinner when no LiveKit token is present. The test now pumps through the route transition for a fixed duration and inspects the constructed widget directly.

## Verification

- `cd mobile && flutter analyze lib/main.dart lib/screens/calls/active_call_screen.dart` - passed.
- `cd mobile && flutter test test/widgets/call_navigation_gap_test.dart` - passed, 3 tests.
- `rg "createCall\\(calleeId\\)|pushNamed\\('/calls/outgoing'" mobile/lib/main.dart` - passed.
- `/calls/incoming` route case remains present in `mobile/lib/main.dart`.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- Phase 4 mobile UAT gaps for active route construction and outgoing call entry are closed.
- Incoming push notification routing remains available through `/calls/incoming`.
- Phase 4 is ready for verification/UAT, with separate known repo-wide TypeScript issues already documented in 04-06.

## Self-Check: PASSED

- Key created files exist.
- Commits for `04-07` are present.
- Analyzer and targeted widget tests pass.
- `/calls/active`, `/calls/outgoing`, and `/calls/incoming` route expectations are covered.

---
*Phase: 04-video-calling*
*Completed: 2026-05-16*
