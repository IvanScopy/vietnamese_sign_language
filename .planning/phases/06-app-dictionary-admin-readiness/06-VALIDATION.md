---
phase: 06
slug: app-dictionary-admin-readiness
status: draft
nyquist_compliant: true
wave_0_complete: false
created: 2026-05-17
---

# Phase 06 - Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Web/backend framework** | Jest 29.7.0 with ts-jest |
| **Web/backend config file** | `jest.config.ts` |
| **Mobile framework** | `flutter_test` with Flutter 3.41.9 / Dart 3.11.5 |
| **Mobile config file** | `mobile/analysis_options.yaml` |
| **Quick web command** | `npm test -- --runInBand src/__tests__/dictionary src/__tests__/admin` |
| **Full web command** | `npm test` |
| **Quick mobile command** | `cd mobile && flutter test test/widgets/app_shell_test.dart test/services/dictionary_service_test.dart` |
| **Full mobile command** | `cd mobile && flutter analyze && flutter test` |
| **Estimated quick runtime** | ~90 seconds |
| **Estimated full runtime** | ~300 seconds |

---

## Sampling Rate

- **After every task commit:** Run the focused Jest or Flutter test for the touched surface.
- **After every plan wave:** Run `npm test`; also run `cd mobile && flutter analyze && flutter test` when mobile code was touched.
- **Before `$gsd-verify-work`:** Full web/backend and mobile suites must be green.
- **Max feedback latency:** 300 seconds.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 06-W0-01 | Wave 0 | 0 | DICT-01, DICT-02, DICT-03, DICT-04 | T-06-02 | User dictionary APIs return only `published` entries and normalize Vietnamese search inputs. | API/Jest | `npm test -- src/__tests__/dictionary/dictionary-api.test.ts` | no - W0 | pending |
| 06-W0-02 | Wave 0 | 0 | ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05 | T-06-01 | Direct non-admin API calls return 401/403; admin list responses omit password/token/emergency secrets. | API/Jest | `npm test -- src/__tests__/admin/admin-auth.test.ts` | no - W0 | pending |
| 06-W0-03 | Wave 0 | 0 | ADMIN-02, ADMIN-04, ADMIN-05 | T-06-04 | Sensitive admin actions write immutable audit records. | API/Jest | `npm test -- src/__tests__/admin/admin-audit.test.ts` | no - W0 | pending |
| 06-W0-04 | Wave 0 | 0 | WEB-01 | - | Protected web app shell renders authenticated routes and redirects unauthenticated users. | React/Jest | `npm test -- src/__tests__/web/app-shell.test.tsx` | no - W0 | pending |
| 06-W0-05 | Wave 0 | 0 | WEB-03 | T-06-05 | Webcam page handles missing API, denied permission, stream cleanup, and recognition connection states. | React/Jest | `npm test -- src/__tests__/web/recognition-page.test.tsx` | no - W0 | pending |
| 06-W0-06 | Wave 0 | 0 | MOB-01, MOB-02 | - | Mobile tab shell exposes accessible navigation, preserves SOS prominence, and handles session-expired state. | Flutter widget | `cd mobile && flutter test test/widgets/app_shell_test.dart` | no - W0 | pending |
| 06-W0-07 | Wave 0 | 0 | DICT-01, DICT-02, DICT-03, DICT-04 | T-06-02 | Mobile dictionary client parses search/category/detail/video metadata responses without exposing drafts. | Flutter unit | `cd mobile && flutter test test/services/dictionary_service_test.dart` | no - W0 | pending |
| 06-DB-01 | Data/schema | 1 | DICT-01, DICT-02, DICT-03, DICT-04, ADMIN-02 | T-06-02 | Dictionary schema separates draft/needs_review/published states and supports normalized search fields. | Prisma/Jest | `npm test -- src/__tests__/dictionary/dictionary-api.test.ts` | after W0 | pending |
| 06-ADM-01 | Admin APIs | 1 | ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05 | T-06-01 / T-06-04 | Every admin route performs API-level role checks and writes audit records for sensitive actions. | API/Jest | `npm test -- src/__tests__/admin` | after W0 | pending |
| 06-WEB-01 | Web app | 2 | WEB-01, WEB-03, WEB-04, DICT-01, DICT-02, DICT-03, DICT-04 | T-06-05 | Web account, dictionary, recognition, and status surfaces work from shared auth state. | React/Jest | `npm test -- src/__tests__/web src/__tests__/dictionary` | after W0 | pending |
| 06-MOB-01 | Mobile app | 2 | MOB-01, MOB-02, WEB-04, DICT-01, DICT-02, DICT-03, DICT-04 | - | Flutter app shell and dictionary screens use shared account state and accessible navigation. | Flutter | `cd mobile && flutter analyze && flutter test` | after W0 | pending |

---

## Wave 0 Requirements

- [ ] `src/__tests__/dictionary/dictionary-api.test.ts` - covers DICT-01 through DICT-04 import/search/published filtering.
- [ ] `src/__tests__/admin/admin-auth.test.ts` - covers ADMIN role and 401/403 route matrix.
- [ ] `src/__tests__/admin/admin-audit.test.ts` - covers admin audit writes for sensitive actions.
- [ ] `src/__tests__/web/app-shell.test.tsx` - covers WEB-01 protected responsive shell/navigation.
- [ ] `src/__tests__/web/recognition-page.test.tsx` - covers WEB-03 webcam permission/error/cleanup states.
- [ ] `mobile/test/widgets/app_shell_test.dart` - covers MOB-01/MOB-02 app shell accessibility and SOS prominence.
- [ ] `mobile/test/services/dictionary_service_test.dart` - covers mobile dictionary API client behavior.

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| iOS and Android production shell feel | MOB-01, MOB-02 | Flutter widget tests cannot fully prove platform accessibility, safe areas, keyboard behavior, or screen-reader output. | Run the app on one iOS simulator/device and one Android emulator/device; verify tab navigation, SOS prominence, text scaling, 48x48 targets, and VoiceOver/TalkBack labels. |
| Dictionary video playback quality | DICT-02 | Automated tests can verify metadata and player states, but not real CDN/video playback quality. | Load at least 5 published dictionary entries with videos on web and mobile; verify play/pause/seek/replay/speed/fullscreen where supported. |
| Broadcast preview and delivery sanity | ADMIN-05 | Socket/push delivery depends on runtime credentials and device/browser notification permissions. | Create a test broadcast targeted to a small test group; verify preview target count, confirmation step, audit log, and recipient notification/status surface. |
| Webcam recognition in browser | WEB-03 | JSDOM cannot provide real camera streams or secure-context browser permission UI. | In HTTPS or localhost, allow webcam access, verify camera preview starts, recognition connection status is shown, and stopping leaves no active camera indicator. |

---

## Validation Sign-Off

- [x] All tasks have automated verify targets or Wave 0 dependencies.
- [x] Sampling continuity avoids 3 consecutive tasks without automated verification.
- [x] Wave 0 covers all missing automated references from research.
- [x] No watch-mode flags are required.
- [x] Feedback latency target is under 300 seconds.
- [x] `nyquist_compliant: true` set in frontmatter.

**Approval:** pending
