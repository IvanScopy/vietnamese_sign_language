---
phase: 4
slug: video-calling
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-16
---

# Phase 4 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | Jest 29.7.0 (backend), flutter_test (mobile) |
| **Config file** | `jest.config.ts` (backend), `mobile/test/` (Flutter) |
| **Quick run command** | `npm test -- --runInBand src/__tests__/calls/call-lifecycle.test.ts` |
| **Full suite command** | `npm test && cd mobile && flutter test` |
| **Estimated runtime** | ~60 seconds (backend), ~120 seconds (mobile) |

---

## Sampling Rate

- **After every task commit:** Run narrow test for touched module (backend or Flutter)
- **After every plan wave:** Run `npm test` (backend) or `cd mobile && flutter test` (mobile)
- **Before `/gsd-verify-work`:** Full backend suite + full Flutter suite must be green
- **Max feedback latency:** ~120 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 4-01-01 | 01 | 0 | COMM-05 | — | Call state machine transitions (initiated→ringing→accepted→ended) | backend unit | `npm test -- --runInBand src/__tests__/calls/call-lifecycle.test.ts` | ❌ W0 | ⬜ pending |
| 4-01-02 | 01 | 0 | COMM-05 | T-4-01 | LiveKit token only issued to accepted call participants | backend unit | `npm test -- --runInBand src/__tests__/calls/livekit-token.test.ts` | ❌ W0 | ⬜ pending |
| 4-01-03 | 01 | 0 | COMM-05 | T-4-02 | Socket.io user room emissions for call lifecycle events | backend unit | `npm test -- --runInBand src/__tests__/calls/call-signaling.test.ts` | ❌ W0 | ⬜ pending |
| 4-01-04 | 01 | 0 | NOTIF-01 | — | FCM payload helper formats VIDEO_CALL data, handles failed tokens | backend unit | `npm test -- --runInBand src/__tests__/notifications/call-push.test.ts` | ❌ W0 | ⬜ pending |
| 4-02-01 | 02 | 1 | COMM-05 | — | Web call page renders accepted LiveKit room, handles media device failure | React/unit | `npm test -- --runInBand src/__tests__/web/call-page.test.tsx` | ❌ W0 | ⬜ pending |
| 4-02-02 | 02 | 1 | COMM-05 | — | Flutter active call renders local/remote video, teardown states | widget | `cd mobile && flutter test test/widgets/active_call_screen_test.dart` | ❌ W0 | ⬜ pending |
| 4-02-03 | 02 | 1 | COMM-05 | — | Sign draft → Confirm/Confirm & Play overlay behavior in calls | widget/service | `cd mobile && flutter test test/widgets/call_translation_overlay_test.dart` | ❌ W0 | ⬜ pending |
| 4-02-04 | 02 | 1 | NOTIF-01 | — | Flutter notification open routes to incoming call screen | widget/service | `cd mobile && flutter test test/services/push_notification_service_test.dart` | ❌ W0 | ⬜ pending |
| 4-02-05 | 02 | 1 | COMM-05 | — | Flutter call API service handles create/accept/reject/cancel/end | service | `cd mobile && flutter test test/services/call_api_service_test.dart` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `src/__tests__/calls/call-lifecycle.test.ts` — covers COMM-05 lifecycle races
- [ ] `src/__tests__/calls/livekit-token.test.ts` — covers accepted participant token gating
- [ ] `src/__tests__/calls/call-signaling.test.ts` — covers Socket.io user room emissions
- [ ] `src/__tests__/notifications/call-push.test.ts` — covers FCM payload helper
- [ ] `src/__tests__/web/call-page.test.tsx` — covers web call UI shell
- [ ] `mobile/test/services/call_api_service_test.dart` — covers mobile API client
- [ ] `mobile/test/services/push_notification_service_test.dart` — covers notification-open routing
- [ ] `mobile/test/widgets/active_call_screen_test.dart` — covers active call UI states
- [ ] `mobile/test/widgets/call_translation_overlay_test.dart` — covers subtitle/sign overlay behavior

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| End-to-end 1:1 video call with audio/video | COMM-05 | Requires two devices/clients and LiveKit runtime | Start two clients, initiate call, accept, verify both video feeds render, end call |
| Mobile background incoming call notification | NOTIF-01 | Requires real device with FCM/APNs credentials | Background the app, initiate call from second account, verify notification appears and routes to incoming screen |
| Deaf user visual/haptic call notification | NOTIF-01 | Requires physical device for haptics | Trigger incoming call, verify vibration pattern and visual indicator without flashing |
| Web browser camera/microphone permission flow | WEB-02 | Browser permission prompts are user-interactive | Open web call page, verify permission prompt appears, deny then retry flow works |
| TURN traversal on restrictive networks | COMM-05 | Requires network configuration testing | Test call on corporate WiFi or mobile data with restricted UDP ports |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** pending
