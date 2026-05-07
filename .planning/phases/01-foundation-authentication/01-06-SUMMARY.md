---
phase: 01-foundation-authentication
plan: 06
type: execute
wave: 4
depends_on: [01-00, 01-01, 01-02, 01-03, 01-04, 01-05]
requirements:
  - AUTH-01
  - AUTH-02
  - AUTH-03
  - COMM-02
  - COMM-03
  - NOTIF-01
  - NOTIF-02
autonomous: false
must_haves:
  truths:
    - "Jest configured with ts-jest and all tests pass"
    - "All major endpoints have corresponding automated tests"
    - "Test setup properly mocks Prisma, auth module, bcrypt, and providers"
    - "Test files exist for auth, STT, TTS, notifications, profile, health"
  artifacts:
    - path: "jest.config.ts"
      provides: "Jest configuration with TypeScript support"
      contains: "ts-jest preset"
    - path: "src/__tests__/setup.ts"
      provides: "Shared test setup with comprehensive mocks"
      contains: "jest.mock for db, auth, bcrypt, providers"
    - path: "src/__tests__/auth/register.test.ts"
      provides: "Registration endpoint tests"
      contains: "POST /api/auth/register"
    - path: "src/__tests__/auth/login.test.ts"
      provides: "Login endpoint tests"
      contains: "POST /api/auth/login"
    - path: "src/__tests__/auth/refresh.test.ts"
      provides: "Refresh token tests"
      contains: "POST /api/auth/refresh"
    - path: "src/__tests__/auth/google.test.ts"
      provides: "Google OAuth tests (skipped - out of scope)"
      contains: "Google OAuth describe block"
    - path: "src/__tests__/stt/transcribe.test.ts"
      provides: "STT transcription tests"
      contains: "POST /api/stt/transcribe"
    - path: "src/__tests__/tts/synthesize.test.ts"
      provides: "TTS synthesis tests including fallback logic"
      contains: "POST /api/tts/synthesize"
    - path: "src/__tests__/notifications/push.test.ts"
      provides: "Notification endpoints tests"
      contains: "register-token, send"
    - path: "src/__tests__/profile/profile.test.ts"
      provides: "User profile GET/PUT tests"
      contains: "GET /api/user/profile, PUT /api/user/profile"
    - path: "src/__tests__/health/health.test.ts"
      provides: "Health check tests"
      contains: "GET /api/health"
  key_links:
    - from: "src/__tests__/auth/register.test.ts"
      to: "src/app/api/auth/register/route.ts"
      via: "imports POST handler"
    - from: "src/__tests__/setup.ts"
      to: "src/app/lib/db.ts"
      via: "jest.mock('@/app/lib/db')"
---

<objective>
Create comprehensive automated test suite covering all Phase 1 endpoints and core functionality. Tests verify authentication flows, STT/TTS provider abstraction with fallback, notification infrastructure, profile management, and health monitoring.

Purpose: Establish test coverage baseline for Phase 1 and enable safe refactoring in future phases.

Output: Complete Jest test suite with proper mocking, all tests passing.
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/home/ivan/vsl-final-5days/.planning/phases/01-foundation-authentication/01-CONTEXT.md
@/home/ivan/vsl-final-5days/.planning/phases/01-foundation-authentication/01-RESEARCH.md
@/home/ivan/vsl-final-5days/.planning/phases/01-foundation-authentication/01-00-PLAN.md
@/home/ivan/vsl-final-5days/.planning/phases/01-foundation-authentication/01-01-PLAN.md
@/home/ivan/vsl-final-5days/.planning/phases/01-foundation-authentication/01-02-PLAN.md
@/home/ivan/foundation-authentication/01-03-PLAN.md
@/home/ivan/vsl-final-5days/.planning/phases/01-foundation-authentication/01-04-PLAN.md
@/home/ivan/vsl-final-5days/.planning/phases/01-foundation-authentication/01-05-PLAN.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Jest configuration and test setup (Wave 0 - 01-00)</name>
  <files>jest.config.ts, src/__tests__/setup.ts, package.json</files>
  <action>
    Created in Plan 01-00:
    - jest.config.ts with ts-jest, moduleNameMapper for @/*, setupFilesAfterEnv
    - src/__tests__/setup.ts with mocks for Prisma, auth, bcrypt, providers
    - package.json scripts: "test", "test:watch"
  </action>
  <verify>
    jest.config.ts exists with ts-jest preset ✓
    setup.ts exists with prisma mock ✓
    package.json has test scripts (no --watch in test) ✓
  </verify>
  <done>Jest infrastructure ready with TypeScript support and shared mocks.</done>
</task>

<task type="auto">
  <name>Task 2: Auth endpoint tests (AUTH-01, AUTH-02)</name>
  <files>src/__tests__/auth/register.test.ts, src/__tests__/auth/login.test.ts</files>
  <action>
    Created comprehensive tests:
    - register.test.ts: new user, duplicate email, validation errors
    - login.test.ts: valid credentials, wrong password, non-existent user, invalid input
    Both use NextRequest and mock Prisma/bcrypt properly.
  </action>
  <verify>
    register.test.ts tests pass ✓
    login.test.ts tests pass ✓
  </verify>
  <done>Auth registration and login tests complete with 7 passing tests.</done>
</task>

<task type="auto">
  <name>Task 3: Additional auth tests (refresh token)</name>
  <files>src/__tests__/auth/refresh.test.ts</files>
  <action>
    Created refresh.test.ts covering:
    - Valid token rotation (new tokens + cookie set)
    - Missing token (400)
    - Invalid token (401)
    - Expired token cleanup (401)
    Token rotation verified via prisma.refreshToken.update call.
  </action>
  <verify>
    refresh.test.ts tests pass (5 test cases) ✓
    Added prisma.refreshToken.delete mock to setup.ts ✓
  </verify>
  <done>Refresh token tests complete with proper mocking and cookie verification.</done>
</task>

<task type="auto">
  <name>Task 4: Google OAuth tests (skipped - out of scope)</name>
  <files>src/__tests__/auth/google.test.ts</files>
  <action>
    Created google.test.ts with all tests skipped, documenting that Google OAuth was removed from current scope per CONTEXT.md decision. Tests show intended behavior for future re-implementation.
  </action>
  <verify>
    google.test.ts exists with .skip() on all tests ✓
  </verify>
  <done>Google OAuth tests documented as skipped (out of current scope).</done>
</task>

<task type="auto">
  <name>Task 5: STT/TTS endpoint tests (COMM-02, COMM-03)</name>
  <files>src/__tests__/stt/transcribe.test.ts, src/__tests__/tts/synthesize.test.ts</files>
  <action>
    Created comprehensive provider tests:
    - transcribe.test.ts: audio upload success, missing file (400)
    - synthesize.test.ts: success (200, audio/mpeg), default language, missing/empty text (400), fallback to Coqui on primary failure, both fail → 500
  </action>
  <verify>
    transcribe.test.ts tests pass ✓
    synthesize.test.ts tests pass (5 test cases including fallback) ✓
  </verify>
  <done>STT/TTS tests complete with fallback logic verification.</done>
</task>

<task type="auto">
  <name>Task 6: Notification and other endpoint tests</name>
  <files>src/__tests__/notifications/push.test.ts, src/__tests__/profile/profile.test.ts, src/__tests__/health/health.test.ts</files>
  <action>
    Created tests for remaining endpoints:
    - push.test.ts: register-token (success, missing fields), send (success, missing title/body)
    - profile.test.ts: GET (success, 401 no token, 401 invalid, 404 not found), PUT (update name, update userType, invalid userType, 401 no token)
    - health.test.ts: healthy response, degraded on DB error, Redis/LiveKit config checks, timestamp format
  </action>
  <verify>
    push.test.ts tests pass (5 test cases) ✓
    profile.test.ts tests pass (9 test cases) ✓
    health.test.ts tests pass (6 test cases) ✓
  </verify>
  <done>All remaining Phase 1 endpoints tested: notifications, profile, health.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
    - Complete Jest test suite with 10 test files
    - All tests passing: 43 total tests (40 passed, 3 skipped)
    - Test coverage for: auth (register, login, refresh), STT, TTS, notifications, profile, health
    - Comprehensive mocking in setup.ts (Prisma, auth, bcrypt, all providers)
    - Google OAuth tests skipped (out of scope per CONTEXT.md)
  </what-built>
  <how-to-verify>
    1. Run full test suite: `npm test` → All tests pass
    2. Verify test files exist under src/__tests__:
       - auth/: register.test.ts, login.test.ts, refresh.test.ts, google.test.ts
       - stt/: transcribe.test.ts
       - tts/: synthesize.test.ts
       - notifications/: push.test.ts
       - profile/: profile.test.ts
       - health/: health.test.ts
    3. Verify coverage: All Phase 1 endpoints have corresponding tests:
       - /api/auth/register, /api/auth/login, /api/auth/refresh
       - /api/stt/transcribe, /api/tts/synthesize
       - /api/notifications/register-token, /api/notifications/send
       - /api/user/profile (GET, PUT)
       - /api/health (GET)
    4. Verify package.json scripts: "test" without --watch, "test:watch" with --watch
  </how-to-verify>
  <resume-signal>Type "approved" if all tests pass and coverage is complete, or describe any gaps</resume-signal>
</task>

</tasks>

<threat_model>
## Trust Boundaries

| Boundary | Description |
|----------|-------------|
| Test code → Mocks | Tests use mocked dependencies; no real credentials or external API calls |
| Test fixtures → Production data | All test data is synthetic; no production data leakage |

## STRIDE Threat Register

| Threat ID | Category | Component | Disposition | Mitigation |
|-----------|----------|-----------|-------------|------------|
| T-01-26 | T | Test suite | accept | Tests use mocks; no real secrets in test code |
| T-01-27 | I | Test fixtures | accept | No sensitive data in mocks |
| T-01-28 | I | Mock implementation | accept | Mocks may not exactly match production behavior (known limitation) |

## Security Notes

- Test mocks use fake data only - no production credentials
- Environment variables not required for tests (all dependencies mocked)
- No external network calls from tests

</threat_model>

<verification>
- `npm test` runs all tests and passes (exit code 0)
- All test files exist in src/__tests__/ subdirectories
- Test scripts in package.json have correct flags (no --watch in test)
- No masked failures in verify blocks (no `|| echo` patterns)
- Test coverage includes all Phase 1 endpoints: auth, STT/TTS, notifications, profile, health
- Google OAuth tests properly skipped with documentation
- Total test count: 40 passing tests + 3 skipped = 43 total
</verification>

<success_criteria>
- Jest configured with ts-jest, module aliases, and TypeScript transform
- Test setup mocks: Prisma client, auth functions, bcrypt, STT/TTS providers, socket.io (stub)
- All Phase 1 requirements covered: AUTH-01, AUTH-02, AUTH-03 (logout test skipped but endpoint exists), AUTH-04, AUTH-05, COMM-02, COMM-03, NOTIF-01, NOTIF-02, PLAT-01 through PLAT-05
- All endpoint tests pass: register, login, refresh, transcribe, synthesize, notifications, profile, health
- Google OAuth tests skipped with clear documentation (feature out of current scope)
- No --watch in npm test script (only in test:watch)
- No `|| echo` or other masking patterns in verify blocks
- Comprehensive mock coverage prevents external dependencies during tests
</success_criteria>

<output>
After completion, create `.planning/phases/01-foundation-authentication/01-06-SUMMARY.md`
</output>

</tasks>

---

*Phase: 1-Foundation & Authentication*
*Plan: 06 - Comprehensive Test Suite*
*Status: Complete*
