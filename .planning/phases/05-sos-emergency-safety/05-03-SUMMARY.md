---
plan: "05-03"
phase: "05"
status: complete
completed: "2026-05-16"
subsystem: "sos-backend"
tags: ["auth", "emergency-contacts", "push-tokens", "e164-normalization"]
dependency_graph:
  requires: ["05-02"]
  provides: ["request-auth-helper", "emergency-contacts-api", "auth-derived-push-tokens"]
  affects: ["all SOS backend routes"]
tech_stack:
  added: []
  patterns: ["cookie-and-bearer dual auth", "owner-scoped writes", "E.164 phone normalization"]
key_files:
  created:
    - src/app/lib/request-auth.ts
    - src/app/api/user/emergency-contacts/route.ts
    - src/__tests__/notifications/register-token.test.ts
    - src/__tests__/sos/emergency-contacts.test.ts
  modified:
    - src/app/api/notifications/register-token/route.ts
decisions:
  - "getAuthenticatedUser checks cookie first, Bearer header second — web sessions use cookies; mobile uses Authorization header"
  - "Phone normalization strips spaces/hyphens/parens, converts Vietnamese 0xxx → +84xxx, validates E.164 regex"
  - "emergencyContact.deleteMany used for DELETE (not delete) so missing contacts return success not 404"
  - "registerToken switched from $executeRaw to prisma.deviceToken.upsert for type-safety"
metrics:
  duration: "~10 minutes"
  completed_date: "2026-05-16"
  tasks_completed: 2
  files_count: 5
---

# Plan 05-03: Auth Helper, Emergency Contacts, Push Token Fix — Summary

## What was built

**Shared auth helper (`src/app/lib/request-auth.ts`):**
`getAuthenticatedUser` accepts a `NextRequest` and returns an `AuthPayload | null`. It
tries the `accessToken` cookie first (for web/browser clients), then falls back to the
`Authorization: Bearer <token>` header (for mobile clients). This single helper is
now used by all SOS backend routes and the register-token endpoint.

**Emergency contacts CRUD (`src/app/api/user/emergency-contacts/route.ts`):**
- GET: returns all contacts owned by `payload.userId`
- POST: validates with `EmergencyContactSchema`, normalizes the supplied phone to E.164
  (Vietnamese 0xxx → +84xxx, strips formatting chars), rejects non-E.164-like numbers
- PATCH: validates with `UpdateEmergencyContactSchema`, re-normalizes phone if updated,
  uses owner-scoped `where: { id, userId }` to prevent cross-user mutations
- DELETE: uses `deleteMany({ where: { id, userId } })` — owner-scoped, silent on not-found

**Push token fix (`src/app/api/notifications/register-token/route.ts`):**
Replaced the old body-supplied `userId` model with auth-derived userId. The route now
requires a valid session (cookie or Bearer), extracts `userId` from `payload.userId`, and
switches from `$executeRaw` to `prisma.deviceToken.upsert` for type-safety.

## Tests

20 tests across 2 files — all passing.

**`src/__tests__/notifications/register-token.test.ts`** (6 tests):
- Missing auth → 401
- Invalid token → 401
- Cookie auth → registers for payload.userId
- Bearer auth → registers for payload.userId
- Body userId ignored / cannot override auth-derived userId
- Missing device token → 400

**`src/__tests__/sos/emergency-contacts.test.ts`** (14 tests):
- GET returns only authenticated user contacts
- GET unauthenticated → 401
- POST creates contact with E.164 normalized phone (Vietnamese 0xxx)
- POST creates contact with international +xxx number
- POST rejects invalid phone
- POST missing name → 400
- POST unauthenticated → 401
- PATCH scoped to userId in where clause
- PATCH re-normalizes phone field
- PATCH unauthenticated → 401
- DELETE scoped to userId (user 2 cannot delete user 1 contacts)
- DELETE no-op when nothing matches (returns success)
- DELETE missing id → 400
- DELETE unauthenticated → 401

## Commits

- `e73ffdc` — feat(05-03): auth helper, emergency contacts API, auth-derived push tokens

## Deviations from Plan

**1. [Rule 1 - Bug] Switched register-token from $executeRaw to prisma.deviceToken.upsert**
- **Found during:** Task 1
- **Issue:** The original route used raw SQL with `$executeRaw` referencing `device_tokens` table. Plan 05-02 added the `DeviceToken` Prisma model, so the type-safe ORM method is now available and preferred.
- **Fix:** Used `prisma.deviceToken.upsert({ where: { token }, create: {...}, update: {...} })` — same semantics, better type safety.
- **Files modified:** `src/app/api/notifications/register-token/route.ts`
- **Commit:** e73ffdc

No other deviations — plan executed as written.

## Self-Check: PASSED

- `src/app/lib/request-auth.ts` — exists
- `src/app/api/user/emergency-contacts/route.ts` — exists
- `src/app/api/notifications/register-token/route.ts` — updated
- `src/__tests__/notifications/register-token.test.ts` — exists
- `src/__tests__/sos/emergency-contacts.test.ts` — exists
- Commit `e73ffdc` — confirmed in git log
- All 20 tests passing
