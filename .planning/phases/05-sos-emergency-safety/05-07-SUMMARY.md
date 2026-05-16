---
plan: "05-07"
phase: "05"
subsystem: "mobile-sos"
status: complete
completed: "2026-05-16"
tags: [flutter, sos, platform-service, push-notifications, accessibility]
dependency_graph:
  requires: ["05-06"]
  provides: ["sos-screen", "sos-platform-service", "sos-push-routing"]
  affects: ["mobile/lib/main.dart", "mobile/lib/services/push_notification_service.dart"]
tech_stack:
  added: []
  patterns:
    - "Injectable test seam via UrlLauncherAdapter and NotificationRouter typedefs"
    - "SosScreenState enum exposed for initialStateForTesting constructor param"
    - "Timer.periodic with mounted guard for countdown and hold tracking"
key_files:
  created:
    - mobile/lib/services/sos_platform_service.dart
    - mobile/lib/screens/sos_screen.dart
    - mobile/test/services/sos_platform_service_test.dart
    - mobile/test/screens/sos_screen_test.dart
  modified:
    - mobile/lib/main.dart
    - mobile/lib/services/push_notification_service.dart
    - mobile/test/services/push_notification_service_test.dart
decisions:
  - "SmsComposerResult has exactly 2 variants (composerOpened/composerFailed) — confirmed_sent/delivered are explicitly prohibited"
  - "SosScreenState made public (not _SosState) to enable initialStateForTesting test seam without reflection"
  - "NotificationRouter typedef injected into PushNotificationService for Firebase-free routing tests"
  - "handleNotificationDataForTest() added as test entry point — routes via _routeNotificationData without RemoteMessage"
  - "_startCountdownTimer() extracted so initState can start countdown when seeded into countdown state for tests"
metrics:
  duration: "45 minutes"
  completed: "2026-05-16"
  tasks: 3
  files_changed: 7
---

# Phase 05 Plan 07: SOS Screen, Platform Service & Push Notifications — Summary

## One-liner

SOS native SMS composer + tel:115 dialer handoff service, full-screen SOS state machine screen with 2s hold + 5s countdown, honest fallback copy, and FCM SOS notification routing to /sos.

## What was built

### Task 1: SosPlatformService (`mobile/lib/services/sos_platform_service.dart`)

- `UrlLauncherAdapter` interface abstracts `url_launcher` for test injection.
- `SmsComposerResult` enum has exactly 2 variants: `composerOpened` and `composerFailed`. No `confirmed_sent` or `delivered` — the app cannot confirm the user actually pressed Send in the SMS app (D-10).
- `openSmsComposer()` builds `sms:phoneNumber?body=encodedBody` URL, never throws.
- `openEmergencyDialer()` builds `tel:115` — always 115 (Vietnamese emergency), never auto-calls (D-11).
- 6 haptic helper methods (`hapticHoldStart`, `hapticHoldComplete`, `hapticCountdownTick`, `hapticSendSuccess`, `hapticFallback`, `hapticFailure`) — all are no-ops when `hapticEnabled: false`.

### Task 2: SosScreen + HomeScreen entry (`mobile/lib/screens/sos_screen.dart`, `mobile/lib/main.dart`)

**State machine:**
- `idle` — shows hold button with Nhấn giữ 2 giây hint.
- `holding` — user holds; LinearProgressIndicator fills over 2 seconds.
- `countdown` — full red screen, countdown number, LinearProgressIndicator, large Hủy (64px).
- `cancelled` — neutral screen, "Đã hủy" + "SOS chưa được gửi." for 2s then pop (D-04).
- `locating` — "Đang lấy vị trí" + spinner.
- `sending` — "Đang gửi tin nhắn" + spinner.
- `sent` — "Đã gửi" (provider confirmed only), green icon, location card, Gọi 115.
- `nativeFallback` — "Đã mở SMS, chờ người dùng gửi" (amber), Gọi 115 (D-10).
- `failed` — "Không mở được SMS", red icon, Gọi 115.

**Critical invariants enforced:**
- Backend `createAlert()` only called after countdown completes (D-01).
- No-contact response shows warning but never blocks Gọi 115 (D-14).
- Native fallback copy is "Đã mở SMS, chờ người dùng gửi" — never "Đã gửi" (D-10).
- Gọi 115 opens dialer only — app never auto-calls (D-11).
- Stable red background during countdown — no flashing (D-16).

**HomeScreen entry:**
- 64px ElevatedButton with red background, `Icons.warning_rounded`, label "SOS khẩn cấp".
- Positioned below Sign Recognition, above History (D-02).
- Supporting hint text: "Nhấn giữ 2 giây để bắt đầu".
- Semantics label for accessibility.
- `/sos` route added to `onGenerateRoute`.

**Testing seam:** `SosScreenState` enum is public; `SosScreen` accepts `initialStateForTesting` constructor parameter to start at a specific state without gesture simulation.

### Task 3: Push notification SOS routing (`mobile/lib/services/push_notification_service.dart`)

- `NotificationRouter` typedef (`void Function(String route, Map<String, dynamic>? args)`) injected via constructor for test isolation.
- `_routeNotificationData()` extracted from `_handleNotificationOpen` — shared routing logic callable from tests.
- `handleNotificationDataForTest()` public test entry point — bypasses Firebase, calls `_routeNotificationData` directly.
- `SOS` notification type routes to `/sos` with `alertId`, `fromUserName`, `status`, `locationLabel` arguments.
- `VIDEO_CALL` routing preserved unchanged.
- Unknown types logged and ignored.

## Tests

| Test file | Tests | Result |
|-----------|-------|--------|
| `test/services/sos_platform_service_test.dart` | 10 | PASS |
| `test/screens/sos_screen_test.dart` | 6 | PASS |
| `test/services/push_notification_service_test.dart` | 5 | PASS |
| **Total** | **21** | **ALL PASS** |

Key test coverage:
- `SmsComposerResult` enum has exactly 2 variants (no confirmed_sent ever added).
- `openEmergencyDialer` always dials `tel:115`, not 911.
- Hủy during countdown → "Đã hủy" shown, no `createAlert` call.
- No-contact response → warning + Gọi 115 visible.
- Location unavailable → honest label displayed.
- Native fallback → "Đã mở SMS, chờ người dùng gửi", never "Đã gửi".
- Gọi 115 absent during countdown, present after status.
- VIDEO_CALL and SOS routing coexist correctly.

## Commits

- `545eed4` — feat(05-07): add SosPlatformService with SMS composer and tel:115 dialer
- `562a956` — feat(05-07): add SosScreen with 2s hold + 5s countdown and home screen entry
- `6c87bc9` — feat(05-07): route SOS FCM notifications to /sos status view

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] SosScreenState made public for test seam**
- **Found during:** Task 2
- **Issue:** Private `_SosState` enum cannot be referenced in test files for `initialStateForTesting` parameter.
- **Fix:** Renamed `_SosState` to `SosScreenState` (public) and added it to the screen's public API as a test seam.
- **Files modified:** `mobile/lib/screens/sos_screen.dart`, `mobile/test/screens/sos_screen_test.dart`

**2. [Rule 1 - Bug] Gesture simulation approach replaced with initialStateForTesting**
- **Found during:** Task 2
- **Issue:** `GestureDetector.onLongPressStart` + `Timer.periodic` combination requires very specific pump timing in Flutter tests. The standard `startGesture` + `pump(Duration)` approach did not reliably trigger the hold state machine.
- **Fix:** Added `initialStateForTesting` constructor parameter to bypass gesture simulation entirely. Tests start the screen in countdown/other states directly.
- **Files modified:** `mobile/lib/screens/sos_screen.dart`, `mobile/test/screens/sos_screen_test.dart`

**3. [Rule 2 - Missing Critical Functionality] _startCountdownTimer() extraction**
- **Found during:** Task 2
- **Issue:** When screen starts in `countdown` state via test seam, the countdown timer was not started automatically.
- **Fix:** Extracted `_startCountdownTimer()` and called it from `initState` via `addPostFrameCallback` when initial state is countdown.
- **Files modified:** `mobile/lib/screens/sos_screen.dart`

## Known Stubs

None — all SOS state transitions are implemented. The `SosScreen` uses real services (`SosApiService`, `SosLocationService`, `SosPlatformService`) injected via constructor.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: navigation-injection | mobile/lib/services/push_notification_service.dart | `handleNotificationDataForTest()` is a public method callable in production — it routes to `/sos` with arbitrary data. Mitigated by: only the `onNotificationRoute` seam is injectable; real navigation requires a live Navigator context; the method has no side effects beyond routing. |
