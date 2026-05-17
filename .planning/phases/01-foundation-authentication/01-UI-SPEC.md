---
phase: 01
slug: foundation-authentication
status: draft
shadcn_initialized: false
preset: none
created: 2026-05-06
---

# Phase 01 — UI Design Contract

> Visual and interaction contract for Phase 1: Foundation & Infrastructure.
> This phase is backend-focused (API, auth, STT/TTS, notifications infrastructure).
> UI contract covers notification payload structure and API error copywriting for future frontend consumers.

---

## Design System

| Property | Value |
|----------|-------|
| Tool | none (recommend shadcn for Phase 2 when Next.js web app is scaffolded) |
| Preset | not applicable |
| Component library | none yet (Next.js 16 + React 19 planned for web; Flutter for mobile) |
| Icon library | none yet |
| Font | none declared (recommend Inter or system font stack for v1) |

**Note:** No frontend code exists yet. Design system initialization (shadcn for web, Flutter theme for mobile) is deferred to the phase where the web/mobile apps are scaffolded. The notification visual contract below applies to both platforms via payload-driven styling.

---

## Spacing Scale

Not applicable — no UI components in this phase.

When UI is built in future phases, use 8-point scale: 4, 8, 16, 24, 32, 48, 64px.

---

## Typography

Not applicable — no UI components in this phase.

When UI is built in future phases, declare exactly 3-4 sizes and 2 weights.

---

## Color

### Notification Visual Contract (NOTIF-01, NOTIF-02)

These colors are delivered via notification payload and consumed by both web and mobile frontends.

| Role | Value | Usage |
|------|-------|-------|
| Dominant (60%) | #FFFFFF (light) / #1A1A2E (dark) | App background (future) |
| Secondary (30%) | #F5F5F5 (light) / #16213E (dark) | Cards, nav (future) |
| Accent (10%) | #3B82F6 | Incoming call notifications, active indicators |
| SOS Destructive | #DC2626 | SOS alerts only — highest priority visual |
| Success | #10B981 | Successful actions (future) |
| Warning | #F59E0B | Non-critical alerts (future) |

**Accent reserved for:** Incoming call UI, active connection indicators, primary CTAs (future phases).

**SOS color reserved for:** SOS notification payloads only (`type: "SOS"` in notification payload). Must never be used for non-emergency UI.

### Dark Mode Support (Recommended)

Phase 1 notification payloads should include `colorScheme` field to support future dark/light mode:

```json
{
  "type": "SOS",
  "title": "Emergency Alert",
  "body": "User X triggered SOS",
  "color": "#DC2626",
  "vibrationPattern": [0, 500, 200, 500],
  "priority": "critical"
}
```

---

## Copywriting Contract

### API Error Responses (JSON)

Phase 1 delivers REST API endpoints. All error responses follow this contract:

| Element | Copy |
|---------|------|
| Primary CTA (future login) | "Log in" / "Sign in" |
| Primary CTA (future register) | "Create account" |
| Empty state heading (future) | "No conversations yet" |
| Empty state body (future) | "Start a conversation to see it here." |
| Error state (invalid email) | "Please enter a valid email address." |
| Error state (wrong password) | "Incorrect password. Try again or reset it." |
| Error state (email exists) | "An account with this email already exists." |
| Error state (server error) | "Something went wrong. Please try again." |
| Destructive confirmation (future logout) | "Log out: You will need to sign in again on this device." |
| Destructive confirmation (future delete account) | "Delete account: This cannot be undone. All your data will be permanently removed." |

### Notification Copy (NOTIF-01, NOTIF-02)

| Notification Type | Title | Body |
|-------------------|-------|------|
| Incoming video call | "Incoming call" | "{callerName} is calling..." |
| SOS alert (sent) | "SOS Sent" | "Emergency alert sent to your contacts with your location." |
| SOS alert (received) | "EMERGENCY SOS" | "{userName} triggered an SOS alert at {location}." |
| SOS status update | "SOS Update" | "Emergency services have been notified." |

### Notification Payload Structure

```json
{
  "type": "CALL" | "SOS" | "SOS_UPDATE" | "CHAT",
  "title": "string",
  "body": "string",
  "priority": "normal" | "high" | "critical",
  "color": "#hexcode",
  "vibrationPattern": [number],
  "data": {
    "userId": "string",
    "timestamp": "ISO8601",
    "location": "string (optional, for SOS)"
  }
}
```

**SOS vibration pattern (Android):** `[0, 500, 200, 500, 200, 500]` — three long buzzes
**SOS haptic feedback (iOS):** `.heavy` impact followed by `.error` notification feedback
**Photosensitive safety:** No flashing/strobe effects. Use solid color fill with gentle pulse animation only.

---

## Registry Safety

| Registry | Blocks Used | Safety Gate |
|----------|-------------|-------------|
| shadcn official | none (deferred to future phase) | not required |
| third-party | none | not applicable |

**Note:** shadcn initialization is recommended when the Next.js web app is scaffolded (Phase 2+). Flutter mobile app will use Material/Cupertino theming via Flutter's built-in theming system.

---

## Checker Sign-Off

- [ ] Dimension 1 Copywriting: PASS
- [ ] Dimension 2 Visuals: PASS
- [ ] Dimension 3 Color: PASS
- [ ] Dimension 4 Typography: PASS
- [ ] Dimension 5 Spacing: PASS
- [ ] Dimension 6 Registry Safety: PASS

**Approval:** pending
