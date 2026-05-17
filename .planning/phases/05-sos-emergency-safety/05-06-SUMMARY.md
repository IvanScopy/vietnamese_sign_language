---
plan: "05-06"
phase: "05"
status: complete
completed: "2026-05-16"
tags: [flutter, sos, location, gps, http-client, testing]
key-files:
  created:
    - mobile/lib/services/sos_api_service.dart
    - mobile/lib/services/sos_location_service.dart
    - mobile/test/services/sos_api_service_test.dart
    - mobile/test/services/sos_location_service_test.dart
  modified:
    - mobile/android/app/src/main/AndroidManifest.xml
    - mobile/ios/Runner/Info.plist
decisions:
  - AppConfig lacks static apiBaseUrl; SosApiService uses internal _defaultBaseUrl constant instead
  - GeolocatorAdapter abstract class provides test seam without needing platform plugin in tests
  - SosLocationService never throws — permission denial and GPS failure both return unavailable label
---

# Plan 05-06: Flutter SOS API Client & Location Services — Summary

## What was built

**Platform permissions (Task 1):** Added `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION` permissions to AndroidManifest.xml. Added `<queries>` intents for `tel` and `sms` URL schemes so url_launcher can detect app availability on Android 11+. Added `NSLocationWhenInUseUsageDescription` (Vietnamese copy) and `LSApplicationQueriesSchemes` for `tel`/`sms` to iOS Info.plist.

**SosApiService (Task 2):** HTTP client wrapping three SOS backend endpoints:
- `createAlert()` — POST `/api/sos/alerts` with optional GPS location fields and idempotency key
- `updateLocation()` — PATCH `/api/sos/alerts/{id}/location` to update coordinates after initial alert
- `recordFallback()` — POST `/api/sos/alerts/{id}/fallback` to log native SMS intent opening

All methods include `Authorization: Bearer` header. Error handling maps 401 to `SosAuthException` and other 4xx/5xx to `SosApiException`. Parses `SosAlertResponse` with `SosAggregateStatus` enum covering `sent`, `partialFailed`, `nativeFallback`, `failed`, `sending`.

**SosLocationService (Task 3):** GPS location retrieval with 5-second budget. Uses `GeolocatorAdapter` abstract class as a test seam to avoid platform plugin calls in tests. Logic:
1. Checks/requests permission — returns `unavailable` without throwing on denial
2. Checks if location service is enabled
3. Calls `getCurrentPosition` with 5-second time limit
4. If GPS returns accuracy > 100m → `approximate` label; ≤ 100m → `current` label
5. On timeout/failure → tries `getLastKnownPosition` → `lastKnown` label with coordinates
6. If no last known → `unavailable` label

All display strings are Vietnamese. `machineLabel` getter produces API-safe strings (`current`, `approximate`, `last_known`, `unavailable`).

## Deviations from Plan

**[Rule 1 - Bug] AppConfig.apiBaseUrl does not exist**
- Found during: Task 2
- Issue: Plan referenced `AppConfig.apiBaseUrl` as a static property, but `AppConfig` is instance-based with `httpUrl` as an instance method.
- Fix: `SosApiService` defines its own `static const _defaultBaseUrl = 'http://10.0.2.2:8000'` (Android emulator default). Constructor accepts injectable `baseUrl` parameter for production config and testing.
- Files modified: `mobile/lib/services/sos_api_service.dart`

## Tests

All 18 tests pass.

**sos_api_service_test.dart (9 tests):**
- `createAlert` includes Bearer Authorization header
- `createAlert` parses SosAlertResponse correctly from JSON
- `createAlert` throws SosAuthException on 401
- `createAlert` sends location fields when provided
- `createAlert` maps partial_failed status correctly
- `recordFallback` native_sms_opened fallback type is not confirmed sent
- `recordFallback` sends fallbackType and attemptIds in request body
- `updateLocation` sends correct body with location label
- `updateLocation` throws SosAuthException on 401

**sos_location_service_test.dart (9 tests):**
- Permission denied → unavailable without throwing
- Permission deniedForever → unavailable
- Location service disabled → unavailable
- GPS timeout with last known → lastKnown label and coordinates
- GPS timeout no last known → unavailable
- GPS accuracy > 100m → approximate label with Vietnamese text
- GPS accuracy ≤ 100m → current label
- Accuracy exactly at 100m → current (boundary: condition is `> 100m`)
- machineLabel maps all labels correctly

## Commits

- `78219e6` feat(05-06): Flutter SOS API client and location services
