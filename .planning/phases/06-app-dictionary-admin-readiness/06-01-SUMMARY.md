---
phase: 06-app-dictionary-admin-readiness
plan: 01
subsystem: testing
tags: [jest, ts-jest, flutter_test, dictionary, admin, web, mobile]
requires:
  - phase: 01-foundation-authentication
    provides: Auth, Prisma, profile, notification, and Jest foundations used by Phase 6 contracts.
  - phase: 05-sos-emergency-safety
    provides: SOS service/test patterns reused by admin SOS and mobile service contracts.
provides:
  - Wave 0 Jest contracts for user-facing dictionary APIs.
  - Wave 0 Jest contracts for admin authorization, redaction, broadcasts, SOS review, and audit logs.
  - Wave 0 Jest contracts for protected web app shell and browser recognition camera behavior.
  - Wave 0 Flutter contracts for mobile tab shell and dictionary API client.
affects: [phase-06, dictionary, admin, web-shell, mobile-shell]
tech-stack:
  added: []
  patterns: [Red validation scaffold, dynamic future-route imports, Flutter service MockClient contracts]
key-files:
  created:
    - src/__tests__/dictionary/dictionary-api.test.ts
    - src/__tests__/admin/admin-auth.test.ts
    - src/__tests__/admin/admin-audit.test.ts
    - src/__tests__/web/app-shell.test.tsx
    - src/__tests__/web/recognition-page.test.tsx
    - mobile/test/widgets/app_shell_test.dart
    - mobile/test/services/dictionary_service_test.dart
  modified:
    - src/__tests__/setup.ts
key-decisions:
  - "Wave 0 tests intentionally fail against missing Phase 6 implementation so downstream plans have concrete contracts to satisfy."
  - "No production files were added in 06-01; this plan remains validation-only."
patterns-established:
  - "Future Next.js route contracts are loaded dynamically so missing route modules produce clear red tests."
  - "Flutter Phase 6 contracts mirror existing service tests with MockClient and explicit Bearer/auth error assertions."
requirements-completed:
  - MOB-01
  - MOB-02
  - WEB-01
  - WEB-03
  - WEB-04
  - DICT-01
  - DICT-02
  - DICT-03
  - DICT-04
  - ADMIN-01
  - ADMIN-02
  - ADMIN-03
  - ADMIN-04
  - ADMIN-05
duration: 7min
completed: 2026-05-17
---

# Phase 06 Plan 01: Validation Scaffold Summary

**Wave 0 Jest and Flutter contract tests for dictionary, admin, web shell, browser recognition, mobile shell, and dictionary client behavior**

## Performance

- **Duration:** 7 min
- **Started:** 2026-05-17T10:06:00Z
- **Completed:** 2026-05-17T10:13:27Z
- **Tasks:** 3
- **Files modified:** 8

## Accomplishments

- Added dictionary API tests covering published-only reads, draft/needs-review isolation, Vietnamese normalized search variants, category browsing, detail metadata, and playback speed contracts.
- Added admin tests covering 401/403 route boundaries, role matrix expectations, sensitive user redaction, broadcast preview/confirm, SOS review, and required audit action names.
- Added web tests covering protected user navigation, unauthenticated/session state, separate `/admin` chrome, browser camera support copy, permission denial copy, and media track cleanup.
- Added Flutter tests covering the future four-tab `VslAppShell`, SOS prominence, history placement, semantics, session-expired copy, and dictionary service list/detail/auth behavior.

## Task Commits

Each task was committed atomically:

1. **Task 1: Add backend dictionary and admin contract tests** - `76c5f42` (test)
2. **Task 2: Add web shell and browser recognition tests** - `f54e75d` (test)
3. **Task 3: Add mobile shell and dictionary service tests** - `26e9866` (test)

## Files Created/Modified

- `src/__tests__/dictionary/dictionary-api.test.ts` - User-facing dictionary route contracts for search, category, detail, published filtering, and media metadata.
- `src/__tests__/admin/admin-auth.test.ts` - Admin route authorization, role boundary, and redaction contracts.
- `src/__tests__/admin/admin-audit.test.ts` - Admin audit contracts for sensitive actions.
- `src/__tests__/web/app-shell.test.tsx` - Protected web shell and separate admin chrome contracts.
- `src/__tests__/web/recognition-page.test.tsx` - Browser recognition camera permission, unsupported-browser, and cleanup contracts.
- `mobile/test/widgets/app_shell_test.dart` - Mobile tab shell, SOS, history, semantics, and session-expired contracts.
- `mobile/test/services/dictionary_service_test.dart` - Mobile dictionary service Bearer, query/category, detail parsing, media metadata, and 401 mapping contracts.
- `src/__tests__/setup.ts` - Prisma mock extensions for dictionary, category, lesson placeholder, admin audit log, and transaction coverage.

## Verification

- `rg -n "PUBLISHED|DRAFT|NEEDS_REVIEW|gia đình|Gia Dinh|gia_dinh|dinh|category|videoUrl|videoKey" src/__tests__/dictionary/dictionary-api.test.ts` - PASS; required dictionary source assertions present.
- `rg -n "401|403|Super Admin|Content Admin|Support Admin|normal users|User" src/__tests__/admin/admin-auth.test.ts` - PASS; required admin role/status assertions present.
- `rg -n "USER_DEACTIVATE|ADMIN_ROLE_CHANGE|DICTIONARY_PUBLISH|DICTIONARY_UNPUBLISH|BROADCAST_SEND|SOS_REVIEW|AdminAuditLog" src/__tests__/admin/admin-audit.test.ts` - PASS; required audit action assertions present.
- `rg -n "Dictionary|Recognition|Calls|Profile|Notifications" src/__tests__/web/app-shell.test.tsx` - PASS; required web parity labels present.
- `rg -n "mediaDevices|getUserMedia|Permission denied|Stop camera|Start camera|track.stop|Camera requires HTTPS" src/__tests__/web/recognition-page.test.tsx` - PASS; required browser recognition assertions present.
- `rg -n "Communicate|Dictionary|SOS|Profile|History|findsNWidgets\(4\)|Your session expired" mobile/test/widgets/app_shell_test.dart` - PASS; required mobile tab/session assertions present.
- `rg -n "Bearer|/api/dictionary|/api/dictionary/\{slug\}|getSignDetail|401|DictionaryAuthException|DRAFT|thumbnailUrl|thumbnailKey|videoUrl|videoKey|playbackSpeeds" mobile/test/services/dictionary_service_test.dart` - PASS; required dictionary service assertions present.

Focused commands run:

- `npm test -- --runInBand src/__tests__/dictionary/dictionary-api.test.ts src/__tests__/admin/admin-auth.test.ts src/__tests__/admin/admin-audit.test.ts` - EXPECTED FAIL; Jest executed 3 suites and failed because Phase 6 dictionary/admin route modules do not exist yet.
- `npm test -- --runInBand src/__tests__/web/app-shell.test.tsx src/__tests__/web/recognition-page.test.tsx` - EXPECTED FAIL; web app shell currently renders `VSL Bridge API`, and `/admin` plus `/recognition` pages do not exist yet.
- `cd mobile && flutter test test/widgets/app_shell_test.dart test/services/dictionary_service_test.dart` - EXPECTED FAIL; `mobile/lib/widgets/app_shell.dart` and `mobile/lib/services/dictionary_service.dart` do not exist yet.

Plan-level commands run:

- `npm test -- --runInBand src/__tests__/dictionary src/__tests__/admin src/__tests__/web/app-shell.test.tsx src/__tests__/web/recognition-page.test.tsx` - EXPECTED FAIL; 5 suites ran, 37 tests loaded, failures were missing Phase 6 dictionary/admin/recognition/admin modules and current placeholder web home.
- `cd mobile && flutter test test/widgets/app_shell_test.dart test/services/dictionary_service_test.dart` - EXPECTED FAIL; compiler failed on absent Phase 6 mobile shell and dictionary service modules.

## Decisions Made

- Kept 06-01 validation-only and did not add production routes/pages/services.
- Used dynamic `require` for future Next.js route modules so the suites can exist before implementation while still failing directly on missing contracts.
- Used direct Flutter imports for future mobile files so downstream mobile plans must provide the exact `VslAppShell`, `VslSessionState`, `DictionaryService`, `DictionaryEntryStatus`, and `DictionaryAuthException` surfaces.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

- The first admin Jest draft mocked a future `admin-auth` helper and failed before reaching route contracts. I adjusted the tests so the red state points at missing Phase 6 route modules instead.
- The recognition test initially assumed `global.navigator` existed in the Node Jest environment. I added local navigator setup so failures focus on the absent recognition page.

## Known Stubs

None. The `null` values in dictionary test fixtures are intentional media metadata cases (`thumbnailUrl`/`thumbnailKey`, `videoUrl`/`videoKey`) and do not feed a shipped UI.

## Threat Flags

None. This plan adds tests only; it does not introduce network endpoints, auth paths, file access patterns, schema changes, or production trust-boundary code.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

Phase 6 downstream implementation plans can now run against explicit red contracts. Expected next blockers are implementation work in 06-02 through 06-06: Prisma dictionary/admin schema, dictionary/admin routes, web shell/admin/recognition pages, mobile shell, and mobile dictionary service.

## Self-Check: PASSED

- Verified all created/modified plan files exist.
- Verified task commits `76c5f42`, `f54e75d`, and `26e9866` exist in git history.
- Confirmed `STATE.md` and `ROADMAP.md` were not updated by this executor per user instruction.

---
*Phase: 06-app-dictionary-admin-readiness*
*Completed: 2026-05-17*
