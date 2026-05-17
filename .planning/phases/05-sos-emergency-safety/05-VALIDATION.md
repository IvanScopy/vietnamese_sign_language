---
phase: 05
slug: sos-emergency-safety
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-16
---

# Phase 05 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 29.7.0 with ts-jest 29.4.9; Flutter `flutter_test` |
| **Config file** | `jest.config.ts`; `mobile/pubspec.yaml` |
| **Quick run command** | `npm test -- --runInBand src/__tests__/sos/sos-api.test.ts` and `cd mobile && flutter test test/services/sos_api_service_test.dart test/services/sos_location_service_test.dart` |
| **Full suite command** | `npm test` and `cd mobile && flutter test` |
| **Estimated runtime** | ~120 seconds focused, unknown full suite |

---

## Sampling Rate

- **After every task commit:** Run the focused backend or Flutter command for the touched SOS capability.
- **After every plan wave:** Run `npm test` plus focused `cd mobile && flutter test test/services/sos_*.dart test/screens/sos_screen_test.dart`.
- **Before `$gsd-verify-work`:** Full backend and mobile suites must be green.
- **Max feedback latency:** 120 seconds for focused tests where possible.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 05-00-01 | 00 | 0 | EMERG-01 | T-05-01 / T-05-02 | Backend derives sender from auth and loads contacts server-side | backend unit/integration | `npm test -- --runInBand src/__tests__/sos/sos-api.test.ts` | ❌ W0 | ⬜ pending |
| 05-00-02 | 00 | 0 | MOB-05 | T-05-03 | Provider failure records native composer opened, not sent | backend + Flutter unit | `npm test -- --runInBand src/__tests__/sos/sos-fallback.test.ts && cd mobile && flutter test test/services/sos_platform_service_test.dart` | ❌ W0 | ⬜ pending |
| 05-00-03 | 00 | 0 | NOTIF-02 | T-05-04 | SOS notification payloads do not trust client recipient lists | backend unit | `npm test -- --runInBand src/__tests__/sos/sos-notifications.test.ts` | ❌ W0 | ⬜ pending |
| 05-00-04 | 00 | 0 | MOB-04 | T-05-05 | Missing, timed-out, stale, and approximate locations are labeled honestly | Flutter unit | `cd mobile && flutter test test/services/sos_location_service_test.dart` | ❌ W0 | ⬜ pending |
| 05-00-05 | 00 | 0 | EMERG-02 | — | App opens `tel:115` handoff only after user action; no auto-call | Flutter unit | `cd mobile && flutter test test/services/sos_platform_service_test.dart` | ❌ W0 | ⬜ pending |
| 05-00-06 | 00 | 0 | EMERG-01, MOB-04, MOB-05 | — | SOS screen exposes hold, countdown, cancel, status, fallback, and 115 states | Flutter widget | `cd mobile && flutter test test/screens/sos_screen_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `src/__tests__/sos/sos-api.test.ts` — covers EMERG-01 provider send and per-contact persistence.
- [ ] `src/__tests__/sos/sos-fallback.test.ts` — covers MOB-05 provider failure and native fallback record.
- [ ] `src/__tests__/sos/sos-notifications.test.ts` — covers NOTIF-02 Socket.io/FCM fanout.
- [ ] `mobile/test/services/sos_api_service_test.dart` — covers mobile SOS API request/response parsing.
- [ ] `mobile/test/services/sos_location_service_test.dart` — covers MOB-04 permission, timeout, stale, and approximate labels.
- [ ] `mobile/test/services/sos_platform_service_test.dart` — covers MOB-05 SMS composer and EMERG-02 `tel:115` launch.
- [ ] `mobile/test/screens/sos_screen_test.dart` — covers hold/countdown/cancel/status UI states.
- [ ] Manual physical-device SOS protocol document/checklist — covers GPS, haptics, native SMS composer, Twilio test send, Vietnam number test, no-network fallback, and 115 dialer handoff.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Real GPS prompt/current location on Android and iOS | MOB-04 | Emulators cannot prove real permission and sensor behavior | On a physical Android and iOS device, trigger SOS with location permission allowed, denied, and disabled; record whether status labels and location payload match expected states. |
| Native SMS composer fallback | MOB-05 | Platform SMS app behavior is OS/device dependent and cannot confirm final send in unit tests | Simulate provider/network failure, trigger SOS, confirm SMS composer opens with target contacts/body where platform allows, and app logs `Đã mở SMS, chờ người dùng gửi`. |
| Twilio SMS to Vietnam number | EMERG-01 | Carrier delivery depends on live credentials, geo permissions, sender setup, and recipient number | With approved test credentials and consented test number, send provider SMS and record Twilio SID/status callback lifecycle. |
| `tel:115` handoff | EMERG-02 | Actual dialer UX varies by platform and should not place a call during automated tests | Tap `Gọi 115` on physical devices and confirm dialer opens with 115 without auto-calling. Cancel before placing a call. |
| Haptic/visual accessibility | NOTIF-02 | Haptics and visual urgency require human perception checks | Trigger countdown and status changes on physical devices; verify red/emergency treatment, short haptics, and no strong flashing effects. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies.
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify.
- [ ] Wave 0 covers all MISSING references.
- [ ] No watch-mode flags.
- [ ] Feedback latency < 120s for focused tests.
- [ ] `nyquist_compliant: true` set in frontmatter after Wave 0 and sampling map are satisfied.

**Approval:** pending
