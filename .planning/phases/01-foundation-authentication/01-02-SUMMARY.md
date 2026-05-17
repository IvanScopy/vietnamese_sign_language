---
phase: 01-foundation-authentication
plan: 02
subsystem: authentication
tags: [auth, jwt, oauth, nextjs, api]
dependency_graph:
  requires: [01-01]
  provides: [jwt-auth, google-oauth, refresh-token-rotation]
  affects: [user-sessions, api-security]
tech-stack:
  added:
    - name: jose
      version: 6.2.3
      purpose: Edge-compatible JWT signing and verification
    - name: google-auth-library
      version: latest
      purpose: Google OAuth2 client for token verification
    - name: bcrypt
      version: 6.0.0
      purpose: Password hashing (already in dependencies)
  patterns:
    - name: JWT with jose
      description: Stateless JWT using jose library for Edge runtime compatibility
    - name: Refresh token rotation
      description: Old refresh token invalidated when new tokens issued
    - name: httpOnly cookies
      description: Tokens stored in httpOnly, Secure, SameSite cookies to prevent XSS
key-files:
  created:
    - path: src/app/lib/auth.ts
      purpose: JWT utilities (encrypt/verify access and refresh tokens)
    - path: src/app/lib/google-oauth.ts
      purpose: Google OAuth client setup and token verification
    - path: src/app/lib/validators.ts
      purpose: Zod validation schemas for auth endpoints
    - path: src/app/api/auth/register/route.ts
      purpose: User registration endpoint
    - path: src/app/api/auth/login/route.ts
      purpose: Email/password login endpoint
    - path: src/app/api/auth/google/route.ts
      purpose: Google OAuth endpoint (GET redirect, POST callback)
    - path: src/app/api/auth/refresh/route.ts
      purpose: Refresh token rotation endpoint
    - path: src/app/api/auth/logout/route.ts
      purpose: Logout endpoint (invalidates refresh token)
  modified: []
decisions:
  - id: D-01-02-01
    decision: Use jose over jsonwebtoken
    rationale: Edge-compatible JWT operations for Next.js App Router
    impact: Enables JWT signing/verification in Edge runtime
  - id: D-01-02-02
    decision: Store JWT in httpOnly cookies (not localStorage)
    rationale: Prevent XSS token theft as per threat model T-01-08
    impact: Tokens not accessible to client-side JavaScript
  - id: D-01-02-03
    decision: Allow multiple concurrent sessions per user
    rationale: Per CONTEXT.md "Multi-device policy: Multiple concurrent sessions allowed"
    impact: No deletion of existing refresh tokens on new login
  - id: D-01-02-04
    decision: Implement refresh token rotation
    rationale: Old refresh token invalidated when used, reduces theft window
    impact: Each refresh call issues new tokens and invalidates old refresh token
metrics:
  duration: "30 minutes"
  completed_date: "2026-05-06"
  tasks_completed: 3
  files_created: 8
  files_modified: 1
  lines_added: 475
  lines_deleted: 22
---

# Phase 01 Plan 02: JWT Authentication System Summary

## One-liner

JWT authentication with jose (Edge-compatible), Google OAuth integration, refresh token rotation, and httpOnly cookie storage for secure session management.

## Objective

Implement JWT-based authentication system with registration, login (email/password + Google OAuth), refresh token rotation, and logout. Uses stateless JWT (per CONTEXT.md decision) with jose library for Edge compatibility.

## Tasks Completed

| Task | Name | Commit | Status |
|------|------|--------|--------|
| 1 | Create auth utilities, Google OAuth client, and validators | e735523 | Done |
| 2 | Implement register, login, and Google OAuth API routes | cc0e7db | Done |
| 3 | Implement refresh token and logout endpoints | b87c271 | Done |

## Key Implementation Details

### JWT Authentication (jose library)

- **Access tokens**: 15-minute expiry, signed with `JWT_SECRET`
- **Refresh tokens**: 7-day expiry, signed with `REFRESH_TOKEN_SECRET`
- Uses `SignJWT` and `jwtVerify` from jose for Edge compatibility
- Tokens contain: `userId`, `email`, `userType` claims

### Google OAuth Integration

- GET `/api/auth/google` - Redirects to Google for authorization
- POST `/api/auth/google` - Handles OAuth callback with authorization code
- Verifies Google ID token using `google-auth-library`
- Creates user if not exists (with random password for Google users)
- Default userType is `HEARING` for Google sign-ups

### Refresh Token Rotation

- POST `/api/auth/refresh` - Issues new tokens and invalidates old refresh token
- Old refresh token is updated in database (token rotation pattern)
- Verifies token signature, expiry, and database presence

### Logout

- POST `/api/auth/logout` - Deletes refresh token from database
- Clears both access and refresh token cookies with `maxAge: 0`

### Security Measures

- Passwords hashed with bcrypt (10 salt rounds)
- Tokens stored in httpOnly, Secure, SameSite=strict cookies
- Multiple concurrent sessions allowed (per CONTEXT.md)
- Generic error messages to prevent user enumeration
- Input validation with Zod schemas

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

### Auth Gates

None encountered during execution.

## Known Stubs

None - all endpoints are fully implemented with working logic.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: rate-limiting | src/app/api/auth/login/route.ts | Login endpoint lacks rate limiting (per threat T-01-07 mitigation plan: "TODO: add Redis-based rate limiter") |

## Self-Check: PASSED

- [x] All 8 source files exist
- [x] All 3 task commits present in git log
- [x] package.json includes google-auth-library
- [x] JWT secrets referenced via process.env.JWT_SECRET and process.env.REFRESH_TOKEN_SECRET
- [x] Zod schemas exported from validators.ts
- [x] Auth endpoints set httpOnly cookies correctly

## Commit History

```
e735523 feat(01-02): add JWT auth utilities, Google OAuth client, and Zod validators
cc0e7db feat(01-02): implement register, login, and Google OAuth API routes
b87c271 feat(01-02): implement refresh token rotation and logout endpoints
```
