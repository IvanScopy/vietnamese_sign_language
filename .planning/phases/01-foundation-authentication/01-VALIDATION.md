---
phase: 01
slug: foundation-authentication
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-06
---

# Phase 01 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | jest 29.x + supertest |
| **Config file** | `backend/jest.config.js` |
| **Quick run command** | `cd backend && npx jest --testPathPattern=smoke --passWithNoTests` |
| **Full suite command** | `cd backend && npx jest --coverage` |
| **Estimated runtime** | ~30 seconds |

---

## Sampling Rate

- **After every task commit:** `npx jest --testPathPattern=smoke`
- **After every plan wave:** `npx jest --coverage`
- **Before `/gsd-verify-work`:** Full suite must be green
- **Max feedback latency:** 10 seconds

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 01-01-01 | 01 | 1 | REQ-01 | T-01-01 | Passwords hashed with bcrypt | unit | `npx jest auth.test.js` | ✅ / ❌ W0 | ⬜ pending |
| 01-02-01 | 02 | 1 | REQ-02 | T-01-02 | JWT httpOnly cookies | integration | `npx jest jwt.test.js` | ✅ / ❌ W0 | ⬜ pending |
| 01-03-01 | 03 | 2 | REQ-03 | T-01-03 | STT provider fallback | unit | `npx jest stt.test.js` | ✅ / ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] `backend/tests/setup.js` — shared fixtures
- [ ] `backend/jest.config.js` — jest configuration
- [ ] `npm install --save-dev jest supertest` — test framework install

*If none: "Existing infrastructure covers all phase requirements."*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| LiveKit server starts in Docker | PLAT-03 | Needs real Docker env | `docker compose up` and check logs |
| Google OAuth redirect | AUTH-04 | Requires browser + OAuth flow | Click "Login with Google" and complete flow |
| FCM/APNs push notification | NOTIF-01 | Needs mobile device | Send test notification via Firebase console |

*If none: "All phase behaviors have automated verification."*

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 10s
- [ ] `nyquist_compliant: true` set in frontmatter

**Approval:** {pending / approved YYYY-MM-DD}
