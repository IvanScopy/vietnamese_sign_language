# Phase 04: Video Calling - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-16
**Phase:** 04-Video Calling
**Areas discussed:** Call Experience, Translation Surface In Call, Notification Behavior, MVP Platform Target

---

## Call Experience

| Option | Description | Selected |
|--------|-------------|----------|
| Full ringing screen | Caller sees outgoing ringing; receiver sees incoming call with Accept/Reject; timeout creates missed call. | ✓ |
| Direct join | Caller joins the room immediately; receiver joins from popup/notification. | |
| Notification-first MVP | Notification creates the call flow only after receiver interaction. | |

**User's choice:** Full ringing screen.
**Notes:** Timeout is 30 seconds. Persist minimal missed/rejected/ended call events. Either side pressing End ends the active 1:1 call for both.

---

## Translation Surface In Call

| Option | Description | Selected |
|--------|-------------|----------|
| Bottom overlay on video | Sign text and speech subtitles appear as video overlays. | ✓ |
| Separate panel below video | Translation text uses a dedicated panel below video. | |
| Split layout with video and transcript | Video and transcript share the screen as separate panes. | |

**User's choice:** Bottom overlay on video.
**Notes:** Sign recognition uses draft -> Confirm/Play before TTS. Hearing speech appears as live subtitles overlay. No video/audio media is saved; text transcript is saved only when the user explicitly chooses to save it.

---

## Notification Behavior

| Option | Description | Selected |
|--------|-------------|----------|
| Foreground plus minimal background push | Socket.io handles foreground; FCM/APNs handles a minimal mobile background incoming-call path. | ✓ |
| Foreground-only MVP | Incoming calls work only while app is open. | |
| Full production push system | Full token lifecycle, retries, badges, deep links, and analytics. | |

**User's choice:** Foreground plus minimal background push.
**Notes:** Tapping an incoming call notification opens the incoming call screen, not the active room. If receiver is already in a call, the new caller receives busy automatically. Notifications include basic visual/haptic affordances and no flashing.

---

## MVP Platform Target

| Option | Description | Selected |
|--------|-------------|----------|
| Mobile-first, web token/API ready | Full mobile call UX first; backend/API ready for later web. | |
| Mobile plus web at the same time | Build mobile and web user-facing call flows in this phase. | ✓ |
| Backend plus minimal test clients first | Focus on infrastructure and test clients before real UI. | |

**User's choice:** Mobile plus web at the same time.
**Notes:** User wants web and mobile developed in parallel to avoid creating another process later. Web should have full user-facing call flow parity, not be a demo. Mobile has stronger push support through FCM/APNs; web supports foreground/in-browser notification first. Use shared behavior and contracts with platform-native UI.

---

## the agent's Discretion

- Exact room naming, state enum names, persistence shape, overlay visual treatment, and provider setup can be decided during planning.
- Web background push service worker support can be deferred unless planning finds it low-risk.

## Deferred Ideas

- Multi-participant video calling.
- Full web background push if it is not low-risk.
- Full call history, analytics, redial, and call waiting.
- User-customizable notification color/pattern settings.
- 3D avatar signing.
