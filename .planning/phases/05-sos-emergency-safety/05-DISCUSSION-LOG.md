# Phase 05: SOS Emergency & Safety - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-16
**Phase:** 05-SOS Emergency & Safety
**Areas discussed:** SOS activation guardrail, Location and failure behavior, SMS and emergency dialing path, Contacts and SOS status

---

## SOS Activation Guardrail

| Decision | Options Presented | Selected |
|----------|-------------------|----------|
| Activation gesture | Hold 2s + countdown 5s; one tap + confirmation; one tap sends immediately; agent decides | Hold 2s + countdown 5s |
| SOS placement | Home + communication screens; home only; app-wide floating button; agent decides | Home only |
| Countdown UI | Full-screen warning + gentle haptics + large cancel; small dialog; bottom sheet; agent decides | Full-screen warning + gentle haptics + large cancel |
| Cancel behavior | Silent cancel; show cancelled state briefly; require cancel confirmation; agent decides | Show cancelled state briefly |

**User's choice:** Hold-to-activate, home-screen-only SOS, full-screen countdown, and brief cancelled confirmation.
**Notes:** This reduces accidental activation while keeping the emergency path fast.

---

## Location And Failure Behavior

| Decision | Options Presented | Selected |
|----------|-------------------|----------|
| Missing location permission | Request in SOS flow and still allow SOS if denied; require location; preconfigure in settings; agent decides | Request in SOS flow and still allow SOS if denied |
| GPS wait time | Wait max 5s and update later if needed; wait max 15s; use last-known immediately; agent decides | Wait max 5s and update later if needed |
| Low-quality location copy | Label approximate/last-known; omit low-accuracy location; send normally without warning; agent decides | Label approximate/last-known |
| No network behavior | Open native SMS/dialer with prefilled content if possible and show unconfirmed state; queue for later; show error; agent decides | Native fallback with unconfirmed state |

**User's choice:** Prioritize sending quickly, but label missing/stale/approximate location honestly.
**Notes:** SOS must not be blocked by denied location permission or GPS timeout.

---

## SMS And Emergency Dialing Path

| Decision | Options Presented | Selected |
|----------|-------------------|----------|
| SMS strategy | Native SMS only; backend provider only; provider first with native fallback; agent decides | Provider first with native fallback |
| Send status | Provider success = sent, native fallback = SMS opened; always sent; only log provider success; agent decides | Provider success = sent, native fallback = SMS opened |
| 115 call flow | Show large `Gọi 115` action that opens dialer; auto-open dialer; show instructions only; agent decides | Show large action that opens dialer |
| SMS content | Name + emergency line + location/link + accuracy label + timestamp; short emergency + link only; long profile/medical info; agent decides | Name + emergency line + location/link + accuracy label + timestamp |

**User's choice:** Hybrid backend-provider-first SMS, native fallback with honest status, user-controlled 115 dialer handoff, concise SOS message.
**Notes:** The user initially selected native SMS only, then explicitly changed the decision to provider-first with native fallback.

---

## Contacts And SOS Status

| Decision | Options Presented | Selected |
|----------|-------------------|----------|
| Recipients | All configured emergency contacts; one primary contact; choose each time; agent decides | All configured emergency contacts |
| No contacts configured | Still allow SOS and keep `Gọi 115`; block SOS until contacts added; open add-contact screen; agent decides | Still allow SOS and keep `Gọi 115` |
| Status flow | Location -> sending -> sent/opened SMS -> call 115 -> cancel/close; simple processing/done/error; add receiver acknowledgement; agent decides | Location -> sending -> sent/opened SMS -> call 115 -> cancel/close |
| Visual/haptic style | Red emergency color + SOS icon + short haptics, no strong flashing; strong pulse/animation; text only; agent decides | Red emergency color + SOS icon + short haptics, no strong flashing |

**User's choice:** Broadcast to all configured contacts, preserve 115 path when no contacts exist, use explicit status steps, and use accessible non-flashing visual/haptic feedback.
**Notes:** Simultaneous broadcast is in scope. Escalation chains remain deferred.

---

## the agent's Discretion

- SMS provider selection.
- Exact SOS API/schema names and provider metadata shape.
- Exact GPS accuracy/staleness thresholds.
- Exact Vietnamese microcopy and haptic durations.
- Mobile package choices for GPS, native SMS composer, dialer, and permissions.

## Deferred Ideas

- App-wide floating SOS button.
- Receiver acknowledgement flow.
- Escalation chains and contact priority ladders.
- Medical profile payloads.
- Choosing recipients at SOS time.
