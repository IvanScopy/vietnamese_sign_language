# Phase 05: SOS Emergency & Safety - Research

**Researched:** 2026-05-16  
**Domain:** Next.js/Prisma emergency workflow, Twilio SMS, Flutter GPS/SMS/dialer handoff, accessible safety UX  
**Confidence:** HIGH for architecture and platform handoffs; MEDIUM for Vietnam SMS deliverability because carrier behavior requires live account testing.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
## Implementation Decisions

### SOS Activation

- **D-01:** SOS activation uses a 2-second press-and-hold gesture, then a 5-second countdown before sending.
- **D-02:** In Phase 5, the SOS entry point appears only on the mobile home screen.
- **D-03:** The countdown uses a full-screen warning state with clear emergency color treatment, gentle rhythmic haptics, and a large `Hủy` cancel action.
- **D-04:** If the user cancels during countdown, show a `Đã hủy` state for a few seconds, then return to the home screen.

### Location And Failure Behavior

- **D-05:** If location permission is missing, request it inside the SOS flow. If the user denies permission, still allow SOS without location.
- **D-06:** Wait up to 5 seconds for GPS. If location is available, include it. If not, send SOS without location and update later if location becomes available.
- **D-07:** Stale or low-accuracy location must be labeled clearly in the SMS/status copy as `vị trí gần đúng` or `vị trí cuối cùng đã biết`.
- **D-08:** If the phone has no network during SOS, open the native SMS/dialer path with prefilled content when possible and show an unconfirmed-send state.

### SMS And Emergency Dialing

- **D-09:** Use backend SMS provider delivery first. If backend delivery fails or network is unavailable, fall back to the native SMS composer on the device.
- **D-10:** Provider success may be logged/displayed as `Đã gửi`. Native SMS fallback must be logged/displayed as `Đã mở SMS, chờ người dùng gửi`.
- **D-11:** After SMS is sent or initiated, show a large `Gọi 115` action. Tapping it opens the dialer with `115`; the app must not auto-call.
- **D-12:** SOS SMS content includes the user's name, the line `Tôi cần trợ giúp khẩn cấp`, coordinates or a map link when available, the location accuracy/staleness label, and send timestamp.

### Contacts And SOS Status

- **D-13:** Send the same SOS alert to all configured emergency contacts simultaneously. This is not an escalation chain.
- **D-14:** If the user has no emergency contacts, still allow the SOS flow, show a clear warning that no contacts are configured, and keep the `Gọi 115` path available.
- **D-15:** The SOS status flow should expose these states: `Đang lấy vị trí` -> `Đang gửi` -> `Đã gửi` / `Đã mở SMS` -> `Gọi 115` -> `Hủy` / `Đóng`.
- **D-16:** Visual/haptic feedback uses clear red/emergency color, SOS/emergency iconography, and short haptics by state. Do not use strong flashing effects.

### the agent's Discretion

- Select the backend SMS provider during research/planning, with cost, Vietnam delivery, API reliability, and testability considered.
- Choose exact schema/API names for SOS send attempts, delivery status, provider response metadata, and native fallback records.
- Choose exact GPS accuracy and staleness thresholds, as long as low-quality location is labeled honestly.
- Refine Vietnamese UI copy and haptic durations while preserving the decisions above.
- Add mobile packages deliberately for location, native SMS/dialer launching, and permissions.

### Deferred Ideas (OUT OF SCOPE)
## Deferred Ideas

- App-wide floating SOS button can be reconsidered in a later app polish/settings phase.
- Receiver acknowledgement and two-way SOS status updates are future enhancements.
- Escalation chains, contact prioritization, retries over time, and "if no response then next contact" behavior remain deferred.
- Medical profile or long health-information payloads are deferred.
- User-selected recipients at SOS time are deferred because they slow down the emergency path.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| EMERG-01 | SOS button sends SMS with GPS location to emergency contacts. | Use backend Twilio send attempts first, client `url_launcher` SMS fallback, `geolocator` GPS, and per-contact attempt logging. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://www.twilio.com/docs/messaging/api/message-resource] [CITED: https://pub.dev/packages/geolocator] [CITED: https://pub.dev/packages/url_launcher] |
| EMERG-02 | SOS button also triggers local emergency services by dialing 115 in Vietnam. | Use a user-controlled `tel:115`/dialer handoff, not automatic calling. Android `ACTION_DIAL` shows UI for explicit initiation; iOS `tel` links require confirmation on modern iOS. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://developer.android.com/reference/android/content/Intent] [CITED: https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/PhoneLinks/PhoneLinks.html] |
| MOB-04 | Location services for SOS GPS. | Add `geolocator` and request location permission in-flow; use `timeLimit` for the 5-second GPS budget and `getLastKnownPosition` for labeled fallback. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://pub.dev/packages/geolocator] |
| MOB-05 | SMS sending capability for SOS. | Use Twilio provider delivery plus native SMS composer fallback; do not request Android `SEND_SMS` for v1 because composer handoff is safer and cannot honestly prove send completion. [VERIFIED: .planning/REQUIREMENTS.md] [CITED: https://www.twilio.com/docs/messaging/api/message-resource] [CITED: https://pub.dev/packages/url_launcher] |
| NOTIF-02 | Visual notification for new SOS status for emergency contacts. | Reuse existing Socket.io user rooms and Firebase push helper patterns for SOS status notifications; FCM Flutter docs require separate foreground/background/terminated handling. [VERIFIED: src/app/lib/socket.ts] [VERIFIED: src/app/lib/push.ts] [CITED: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages] |
</phase_requirements>

## Summary

Plan Phase 5 as a safety-critical, server-authoritative SOS workflow. The backend should own contact selection, SOS alert persistence, provider SMS delivery, status callback handling, and notification fanout; the Flutter client should own hold/countdown UX, in-flow location collection, native SMS fallback, `tel:115` dialer handoff, haptics, and honest failure states. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] [VERIFIED: prisma/schema.prisma] [VERIFIED: mobile/lib/main.dart]

The primary SMS recommendation is Twilio Programmable Messaging for v1 because it has an official Node helper library, Vietnam SMS pricing, geo-permission controls, and delivery status callbacks. Twilio still needs live Vietnam-route testing before launch because SMS delivery depends on account geo permissions, sender setup, destination formatting, and carrier behavior. [CITED: https://www.twilio.com/docs/libraries/reference/twilio-node] [CITED: https://www.twilio.com/en-us/sms/pricing/vn] [CITED: https://www.twilio.com/docs/messaging/guides/sms-geo-permissions] [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks]

**Primary recommendation:** Implement `POST /api/sos/alerts` as the authoritative send endpoint using Twilio provider-first delivery, `geolocator` GPS on mobile, `url_launcher` for `sms:` and `tel:115` fallback handoffs, and per-contact SOS attempt records that distinguish provider sent/delivered/failed from native composer opened. [VERIFIED: src/app/lib/validators.ts] [CITED: https://pub.dev/packages/geolocator] [CITED: https://pub.dev/packages/url_launcher] [CITED: https://www.twilio.com/docs/messaging/api/message-resource]

## Project Constraints

- No repo-root `AGENTS.md` was found in this session. [VERIFIED: rg --files]
- No project-local `.codex/skills/` or `.agents/skills/` directories were found in this session. [VERIFIED: find . -maxdepth 3]
- Backend routes currently follow Next.js route-handler, Prisma, Zod validation, and JWT-cookie auth patterns. [VERIFIED: src/app/api/user/profile/route.ts] [VERIFIED: src/app/lib/auth.ts] [VERIFIED: src/app/lib/validators.ts]
- Flutter currently uses explicit `MaterialApp` routes and service classes passed into screens. [VERIFIED: mobile/lib/main.dart] [VERIFIED: mobile/lib/services/call_api_service.dart]
- Existing push-token registration has a mismatch: the mobile service sends `token` and `platform`, but `RegisterTokenSchema` also requires `userId`; Phase 5 planning should either fix auth-derived user IDs or avoid depending on this endpoint until corrected. [VERIFIED: mobile/lib/services/push_notification_service.dart] [VERIFIED: src/app/lib/validators.ts] [VERIFIED: src/app/api/notifications/register-token/route.ts]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|--------------|----------------|-----------|
| SOS activation/countdown/cancel | Browser / Client | API / Backend | The hold gesture, countdown, cancel, haptics, and screen states are local UX; only post-countdown sends should create authoritative backend alerts. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] |
| Emergency contact configuration | API / Backend | Browser / Client, Database | Contacts already exist in Prisma and profile reads, but write/update APIs are missing; backend must validate ownership and phone format. [VERIFIED: prisma/schema.prisma] [VERIFIED: src/app/api/user/profile/route.ts] |
| GPS acquisition | Browser / Client | API / Backend | Mobile owns runtime permission and device location; backend stores received coordinates/accuracy/staleness and late updates. [CITED: https://pub.dev/packages/geolocator] |
| Provider SMS delivery | API / Backend | External Twilio service | Provider credentials and delivery status callbacks must stay server-side. [CITED: https://www.twilio.com/docs/messaging/api/message-resource] |
| Native SMS fallback | Browser / Client | API / Backend | The device opens the SMS composer; backend records only `native_composer_opened` or client-reported fallback state, never confirmed delivery. [CITED: https://pub.dev/packages/url_launcher] [CITED: https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/SMSLinks/SMSLinks.html] |
| 115 emergency handoff | Browser / Client | — | Platform dialer UI must require user action; Android `ACTION_DIAL` and iOS `tel` URLs are appropriate handoffs. [CITED: https://developer.android.com/reference/android/content/Intent] [CITED: https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/PhoneLinks/PhoneLinks.html] |
| SOS status logging | Database / Storage | API / Backend | Safety auditability depends on persisted per-contact attempts, provider SIDs, callbacks, and fallback status. [VERIFIED: prisma/schema.prisma] [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks] |
| Emergency-contact visual notification | API / Backend | Browser / Client, FCM/APNs | Existing Socket.io/FCM patterns can deliver status prompts, but SMS remains primary emergency delivery. [VERIFIED: src/app/lib/socket.ts] [VERIFIED: src/app/lib/push.ts] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `twilio` [ASSUMED: slopcheck unavailable] | 6.0.2, npm modified 2026-05-07 | Backend SMS provider client | Official Twilio Node helper library for Programmable Messaging; supports API response SIDs/status and callback integration. [VERIFIED: npm registry] [CITED: https://www.twilio.com/docs/libraries/reference/twilio-node] |
| `geolocator` [ASSUMED: slopcheck unavailable] | 14.0.2 | Flutter location, permissions, last-known position, accuracy metadata | Official pub.dev package for cross-platform GPS/location APIs, with `getCurrentPosition`, `getLastKnownPosition`, permission checks, accuracy options, and `timeLimit`. [CITED: https://pub.dev/packages/geolocator] |
| `url_launcher` [ASSUMED: slopcheck unavailable] | 6.3.2 | Flutter `sms:` composer and `tel:115` dialer handoff | Official Flutter-maintained package supports phone and SMS URL schemes without custom native code. [CITED: https://pub.dev/packages/url_launcher] [VERIFIED: pub.dev API] |
| `permission_handler` | 12.0.1 already installed | Existing mobile permission helper | Already in `mobile/pubspec.yaml`; keep for other app permissions, but `geolocator` should own location permission flow for this phase. [VERIFIED: mobile/pubspec.yaml] [CITED: https://pub.dev/packages/permission_handler] |
| `zod` | 4.4.3 already installed | Request validation | Existing backend validators use Zod; add SOS schemas there. [VERIFIED: package.json] [VERIFIED: src/app/lib/validators.ts] |
| `@prisma/client` / `prisma` | 7.8.0 already installed | SOS persistence and migrations | Existing schema already has SOS/contact models, but they need status-detail extensions. [VERIFIED: package.json] [VERIFIED: prisma/schema.prisma] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `firebase-admin` | 13.10.0 already installed | Push SOS status notifications to emergency-contact app users | Use for NOTIF-02 only when a contact is also an app user with device tokens. [VERIFIED: package.json] [VERIFIED: src/app/lib/push.ts] |
| `firebase_messaging` | 16.2.2 already installed | Mobile receive/open handling for SOS status notifications | Reuse existing push service and add `SOS` routing/state rendering. [VERIFIED: mobile/pubspec.yaml] [CITED: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages] |
| `socket.io` / `socket.io-client` | 4.8.3 / 3.1.4 installed | Foreground realtime SOS status | Use existing `user:{userId}` rooms for in-app contact notifications; remove client-authoritative `sos:alert` contact fanout. [VERIFIED: package.json] [VERIFIED: mobile/pubspec.yaml] [VERIFIED: src/app/lib/socket.ts] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Twilio Programmable Messaging | Vonage, MessageBird, Infobip | These may be viable for Vietnam, but Twilio has directly verified official Node docs, Vietnam price page, geo-permission docs, and callback docs in this session; keep alternatives as fallback only if Twilio live-route testing fails. [CITED: https://www.twilio.com/en-us/sms/pricing/vn] [CITED: https://www.twilio.com/docs/messaging/guides/sms-geo-permissions] |
| `url_launcher` SMS composer | Android direct `SEND_SMS` plugin | Direct background SMS creates permissions, policy, and delivery-honesty problems; composer fallback matches the locked decision that native fallback is unconfirmed. [CITED: https://pub.dev/packages/url_launcher] [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] |
| `geolocator` | `location` package | `geolocator` was verified in official docs and directly exposes current/last-known position, permission state, and accuracy status needed by the phase. [CITED: https://pub.dev/packages/geolocator] |

**Installation:**

```bash
npm install twilio
cd mobile && flutter pub add geolocator url_launcher
```

**Version verification:** `npm view twilio version time.modified repository.url scripts.postinstall` returned `6.0.2`, modified `2026-05-07T16:42:29.589Z`, with repository `github.com/twilio/twilio-node`; no postinstall script was returned. [VERIFIED: npm registry] Pub.dev official pages/API verified `geolocator` 14.0.2 and `url_launcher` 6.3.2. [CITED: https://pub.dev/packages/geolocator] [VERIFIED: pub.dev API]

## Package Legitimacy Audit

> `slopcheck` could not be installed or executed in this environment; per protocol, all new recommended packages are tagged `[ASSUMED: slopcheck unavailable]` and the planner must add a human verification checkpoint before installation.

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `twilio` | npm | Existing mature official package; current 6.0.2 modified 2026-05-07 | Not checked | `https://github.com/twilio/twilio-node.git` | unavailable | Approved with checkpoint |
| `geolocator` | pub.dev | Current 14.0.2; pub.dev package is official source | Not checked | Baseflow package page/repo linked from pub.dev | unavailable | Approved with checkpoint |
| `url_launcher` | pub.dev | Current 6.3.2; first versions date back to 2017 in pub.dev API | Not checked | `https://github.com/flutter/packages/tree/main/packages/url_launcher/url_launcher` | unavailable | Approved with checkpoint |

**Packages removed due to slopcheck [SLOP] verdict:** none; slopcheck unavailable.  
**Packages flagged as suspicious [SUS]:** none by tool; planner must still checkpoint because slopcheck unavailable.

## Architecture Patterns

### System Architecture Diagram

```text
Mobile home SOS button
  -> 2s hold gesture
  -> 5s countdown with Hủy
    -> cancelled: local Đã hủy + optional backend no-op
    -> continue:
       -> request/check location permission
       -> race getCurrentPosition(timeLimit: 5s) + last-known fallback
       -> POST /api/sos/alerts { location?, accuracy?, staleLabel? }
          -> authenticate user
          -> load server-owned EmergencyContact rows
          -> create SOSAlert + per-contact SOSAlertAttempt rows
          -> for each contact in parallel:
             -> Twilio message create
             -> persist provider SID + initial status
             -> emit Socket.io/FCM SOS status if contact maps to app user
          -> return aggregate status + SMS body + fallback targets
       -> if backend/network/provider path failed:
          -> launch sms: composer per supported target or show copyable text
          -> POST fallback record when network returns
       -> show Gọi 115
          -> launch tel:115 dialer handoff
Twilio status callback
  -> verify callback/signature
  -> update SOSAlertAttempt provider status
  -> emit updated SOS status notification
```

### Recommended Project Structure

```text
src/app/api/sos/alerts/route.ts              # create/list active user's SOS alerts
src/app/api/sos/alerts/[id]/location/route.ts # late GPS update
src/app/api/sos/alerts/[id]/fallback/route.ts # native composer/dialer status record
src/app/api/sos/twilio/status/route.ts       # Twilio status callback webhook
src/app/api/user/emergency-contacts/route.ts # contact create/update/delete if profile PUT remains profile-only
src/app/lib/sos.ts                           # orchestration and status aggregation
src/app/lib/sms-provider.ts                  # Twilio abstraction and test fake
src/app/lib/validators.ts                    # SOS/contact schemas
mobile/lib/screens/sos_screen.dart           # countdown/status/dialer UX
mobile/lib/services/sos_api_service.dart     # backend API client
mobile/lib/services/sos_location_service.dart # geolocator wrapper
mobile/lib/services/sos_platform_service.dart # url_launcher + haptics wrapper
```

### Pattern 1: Server-Authoritative SOS

**What:** The client sends only location/status inputs; the backend loads trusted contacts and creates send attempts. [VERIFIED: src/app/lib/socket.ts]  
**When to use:** Every SOS send. The current client-emitted `sos:alert` socket path trusts client-provided contacts and should not be the safety-critical path. [VERIFIED: src/app/lib/socket.ts]

```typescript
// Source: existing Next route/Zod/Prisma pattern in src/app/api/calls/route.ts
const payload = await verifyAccessToken(accessToken)
const contacts = await prisma.emergencyContact.findMany({
  where: { userId: payload.userId },
})
```

### Pattern 2: Provider Attempt Records, Not Boolean Sent Flags

**What:** Store one row per contact attempt with `channel`, `provider`, `providerMessageSid`, `status`, `errorCode`, `openedAt`, `sentAt`, `deliveredAt`, and raw provider metadata JSON. [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks]  
**When to use:** SMS provider sends, Twilio callbacks, and native fallback records.

```typescript
// Source: Twilio message resource/status callback docs
type SosAttemptStatus =
  | 'provider_queued'
  | 'provider_sent'
  | 'provider_delivered'
  | 'provider_failed'
  | 'provider_undelivered'
  | 'native_composer_opened'
  | 'native_composer_failed'
```

### Pattern 3: In-Flow Location With Honest Labels

**What:** Request/check location during SOS, wait up to 5 seconds, include current coordinates when available, use last-known location only when labeled. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] [CITED: https://pub.dev/packages/geolocator]

```dart
// Source: pub.dev geolocator docs
final settings = const LocationSettings(
  accuracy: LocationAccuracy.high,
  timeLimit: Duration(seconds: 5),
);
final position = await Geolocator.getCurrentPosition(
  locationSettings: settings,
);
```

### Anti-Patterns to Avoid

- **Client-supplied emergency contact IDs for send fanout:** The backend must load contacts owned by the authenticated user. [VERIFIED: prisma/schema.prisma]
- **A single `SOSAlert.status = ACTIVE` as the only status model:** Per-contact SMS results can differ; store attempt-level state. [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks]
- **Claiming native SMS was sent:** iOS `sms:` URLs cannot include message text per Apple URL scheme docs, and native composer handoff does not prove the user sent the SMS. [CITED: https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/SMSLinks/SMSLinks.html]
- **Auto-calling 115:** The phase explicitly forbids automatic calling; Android `ACTION_DIAL` and iOS `tel` require or expose user confirmation. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] [CITED: https://developer.android.com/reference/android/content/Intent] [CITED: https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/PhoneLinks/PhoneLinks.html]
- **Strong flashing emergency UI:** Prior decisions require visual/haptic feedback without flashing. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| SMS carrier delivery | Custom modem/SMPP/send queue | Twilio Programmable Messaging | Provider handles carrier routing and exposes status callbacks; still test Vietnam routing. [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks] |
| GPS permission/current/last-known location | Native Android/iOS wrappers | `geolocator` | Package covers permission, service state, current position, last-known position, and accuracy status. [CITED: https://pub.dev/packages/geolocator] |
| SMS/dialer native bridge | Custom platform channels | `url_launcher` | Package supports `sms:` and `tel:` schemes across platforms. [CITED: https://pub.dev/packages/url_launcher] |
| Runtime request validation | Manual `if` chains | Zod validators | Existing project pattern already centralizes validators. [VERIFIED: src/app/lib/validators.ts] |
| Push token fanout | Raw HTTP to FCM | Existing `firebase-admin` helper pattern | Current helper handles missing Firebase config and unregisters stale tokens. [VERIFIED: src/app/lib/push.ts] |

**Key insight:** Emergency correctness depends less on a clever UI and more on state honesty: each recipient needs a durable record of exactly what was attempted, what the provider confirmed, and where the app handed control back to the user. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks]

## Common Pitfalls

### Pitfall 1: Treating Provider API Success As Delivered
**What goes wrong:** The app shows `Đã gửi` or `delivered` before carrier delivery is known. [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks]  
**Why it happens:** Twilio message creation returns an initial status such as queued/accepted; delivery callbacks arrive later. [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks]  
**How to avoid:** Use `provider_queued`/`provider_sent`/`provider_delivered` separately and show conservative user copy.  
**Warning signs:** A boolean `sent: true` field or one status shared by all recipients.

### Pitfall 2: Depending On Native SMS Body Prefill Everywhere
**What goes wrong:** iOS `sms:` URL fallback may open Messages without body text because Apple says SMS URL strings must not include message text. [CITED: https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/SMSLinks/SMSLinks.html]  
**Why it happens:** Android and iOS SMS URL support differs. [CITED: https://pub.dev/packages/url_launcher] [CITED: https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/SMSLinks/SMSLinks.html]  
**How to avoid:** Treat native fallback as best-effort; provide large copyable message text and log `native_composer_opened`, not sent.  
**Warning signs:** Tests only verify Android emulator SMS URI construction.

### Pitfall 3: Late Or Low-Quality GPS Blocking SOS
**What goes wrong:** The user waits too long or SOS never sends because GPS is unavailable. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md]  
**Why it happens:** Location services may be disabled, permission may be denied, or a fix may exceed the 5-second budget. [CITED: https://pub.dev/packages/geolocator]  
**How to avoid:** Send without location after timeout, label last-known/approximate location, and patch late GPS if available.  
**Warning signs:** The send button is disabled until precise GPS exists.

### Pitfall 4: Ignoring Twilio Geo Permissions
**What goes wrong:** SMS to Vietnam fails with a region-permission error. [CITED: https://www.twilio.com/docs/messaging/guides/sms-geo-permissions] [CITED: https://www.twilio.com/docs/api/errors/21408]  
**Why it happens:** Twilio account messaging geo permissions can block destination regions. [CITED: https://www.twilio.com/docs/messaging/guides/sms-geo-permissions]  
**How to avoid:** Add a manual deployment checklist item to enable Vietnam SMS geo permissions and verify with real Vietnamese test numbers.  
**Warning signs:** Error code `21408` or status callback failures for all Vietnam numbers.

### Pitfall 5: Unauthenticated Push/Token Registration
**What goes wrong:** Device tokens can be registered for arbitrary users or registration fails silently. [VERIFIED: src/app/api/notifications/register-token/route.ts] [VERIFIED: mobile/lib/services/push_notification_service.dart]  
**Why it happens:** Existing mobile registration omits `userId`, while the backend validator requires it and does not currently derive user ID from auth. [VERIFIED: src/app/lib/validators.ts]  
**How to avoid:** Fix the endpoint before using push for NOTIF-02; derive `userId` from JWT and reject body-supplied user IDs.

## Code Examples

### Twilio Provider Send

```typescript
// Source: Twilio Node helper docs + Message Resource docs
import twilio from 'twilio'

const client = twilio(process.env.TWILIO_ACCOUNT_SID!, process.env.TWILIO_AUTH_TOKEN!)

export async function sendSosSms(to: string, body: string, statusCallback: string) {
  return client.messages.create({
    to,
    body,
    messagingServiceSid: process.env.TWILIO_MESSAGING_SERVICE_SID,
    statusCallback,
  })
}
```

### Flutter Location With Timeout And Last-Known Fallback

```dart
// Source: pub.dev geolocator docs
Future<Position?> getSosPosition() async {
  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }
  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    return null;
  }

  try {
    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 5),
      ),
    );
  } on TimeoutException {
    return Geolocator.getLastKnownPosition();
  }
}
```

### Flutter SMS And 115 Handoff

```dart
// Source: pub.dev url_launcher docs
Future<bool> openEmergencyDialer() {
  return launchUrl(Uri(scheme: 'tel', path: '115'));
}

Future<bool> openSmsComposer(String phone, String body) {
  final uri = Uri(
    scheme: 'sms',
    path: phone,
    query: encodeQueryParameters({'body': body}),
  );
  return launchUrl(uri);
}
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Native-only SMS send | Provider-first SMS with native composer fallback | Locked in Phase 5 context on 2026-05-16 | Plan backend Twilio attempts and honest native fallback records. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] |
| Client-emitted `sos:alert` with contact list | Server-authoritative SOS API fanout | Phase 5 planning should change this | Avoid trusting client contact lists for safety-critical delivery. [VERIFIED: src/app/lib/socket.ts] |
| One `SOSAlert.status` enum | Alert plus per-recipient attempt statuses | Required by provider callbacks | Accurately represent mixed delivery outcomes. [VERIFIED: prisma/schema.prisma] [CITED: https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks] |

**Deprecated/outdated:**
- Direct client Socket.io `sos:alert` fanout is not appropriate for Phase 5 safety-critical behavior because it trusts client-supplied contacts. [VERIFIED: src/app/lib/socket.ts]
- Native SMS fallback as confirmed delivery is invalid because composer handoff cannot prove user send completion. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Twilio will be acceptable for the project's production SMS cost and Vietnam delivery reliability after account-level live testing. | Standard Stack | Planner may need to swap provider or add stronger fallback if Vietnam delivery fails. |
| A2 | `twilio`, `geolocator`, and `url_launcher` are legitimate packages despite slopcheck being unavailable. | Package Legitimacy Audit | Planner must checkpoint package verification before install. |
| A3 | Existing Prisma 7.8.0 and Next 16.2.4 versions in `package.json` are intentionally installed and usable in this repo. | Standard Stack | If dependency tree is broken, planning must add repair tasks before SOS implementation. |
| A4 | Twilio webhook signature validation is the correct callback-authentication method for this implementation. | Security Domain | If callback validation differs in the chosen runtime, provider status updates could be spoofable until corrected. |
| A5 | Idempotency keys or active-alert checks are the right duplicate-SOS mitigation. | Security Domain | If not implemented, repeated taps/retries could create duplicate SMS sends or duplicate incident records. |

## Open Questions

1. **Which Twilio sender configuration will production use?**
   - What we know: Twilio supports Vietnam SMS pricing and Messaging Services/status callbacks. [CITED: https://www.twilio.com/en-us/sms/pricing/vn] [CITED: https://www.twilio.com/docs/messaging/services]
   - What's unclear: Whether the project account has a compliant sender, Vietnam geo permissions enabled, and reliable delivery to target carriers.
   - Recommendation: Planner should add a manual setup/test task with real Vietnam numbers before marking EMERG-01 complete.

2. **How should emergency-contact phone numbers be normalized?**
   - What we know: Existing `EmergencyContact.phone` is a free string. [VERIFIED: prisma/schema.prisma]
   - What's unclear: Whether v1 should enforce E.164 `+84...` storage or accept local Vietnamese formats and normalize before send.
   - Recommendation: Store normalized E.164 plus display input; reject invalid numbers at contact-save time.

3. **Should SOS alerts be visible in admin logs in Phase 5 or deferred to Phase 6 admin?**
   - What we know: ADMIN-04 is Phase 6, while Phase 5 needs safety logging. [VERIFIED: .planning/REQUIREMENTS.md]
   - What's unclear: Whether to add only backend records now or also a minimal admin view.
   - Recommendation: Persist full logs now; defer admin UI to Phase 6.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|-------------|-----------|---------|----------|
| Node.js | Backend API/tests | ✓ | v20.20.2 | — |
| npm | Package install/registry verification | ✓ | 10.8.2 | — |
| Flutter | Mobile app/tests | ✓ | 3.41.9 stable | — |
| Dart | Mobile package tooling | Partial | bundled with Flutter; direct `dart --version` hit SDK cache write under sandbox | Use escalated Flutter commands when cache access is needed |
| Twilio account/credentials | Provider SMS | ✗ not present in repo | — | Native SMS composer fallback; cannot validate provider delivery without credentials |
| Firebase credentials | SOS push notifications | Conditional | Existing helper handles missing Firebase | Socket.io foreground + SMS remain primary |
| slopcheck | Package legitimacy | ✗ | — | Human verification checkpoint before package install |
| Context7/ctx7 | Docs lookup | ✗ | — | Official docs/web sources used |

**Missing dependencies with no fallback:**
- Twilio production/test credentials and configured sender are required to validate provider SMS delivery. [CITED: https://www.twilio.com/docs/messaging/api/message-resource]

**Missing dependencies with fallback:**
- Firebase credentials can be absent during local development because existing push helper returns `{ sent: 0, failed: 0 }` when Firebase is not initialized. [VERIFIED: src/app/lib/push.ts]
- `slopcheck` is unavailable; planner must add human package verification checkpoints.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Backend framework | Jest 29.7.0 with ts-jest 29.4.9. [VERIFIED: package.json] [VERIFIED: jest.config.ts] |
| Mobile framework | `flutter_test` with existing service/widget tests; several notification/call API tests are skipped placeholders. [VERIFIED: mobile/pubspec.yaml] [VERIFIED: mobile/test/services/push_notification_service_test.dart] |
| Config file | `jest.config.ts`; Flutter uses `mobile/pubspec.yaml`. [VERIFIED: jest.config.ts] [VERIFIED: mobile/pubspec.yaml] |
| Quick run command | `npm test -- --runInBand src/__tests__/sos/sos-api.test.ts` and `cd mobile && flutter test test/services/sos_api_service_test.dart test/services/sos_location_service_test.dart` |
| Full suite command | `npm test` and `cd mobile && flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|--------------|
| EMERG-01 | Creates SOS alert, loads user's contacts, sends Twilio attempts, stores per-contact statuses and location payload. | backend unit/integration with mocked provider | `npm test -- --runInBand src/__tests__/sos/sos-api.test.ts` | ❌ Wave 0 |
| EMERG-02 | Mobile opens `tel:115` via platform service and logs dialer handoff, without auto-call. | Flutter unit with mocked launcher | `cd mobile && flutter test test/services/sos_platform_service_test.dart` | ❌ Wave 0 |
| MOB-04 | Location permission denied/timeout/current/last-known flows produce correct labels. | Flutter unit with fake geolocator wrapper | `cd mobile && flutter test test/services/sos_location_service_test.dart` | ❌ Wave 0 |
| MOB-05 | Provider failure/network failure opens SMS composer or copyable fallback and records unconfirmed state. | backend + Flutter service tests | `npm test -- --runInBand src/__tests__/sos/sos-fallback.test.ts && cd mobile && flutter test test/services/sos_platform_service_test.dart` | ❌ Wave 0 |
| NOTIF-02 | SOS status emits Socket.io/FCM notification payload for app-user contacts. | backend unit with mocked socket/push | `npm test -- --runInBand src/__tests__/sos/sos-notifications.test.ts` | ❌ Wave 0 |

### Sampling Rate

- **Per task commit:** Run the focused backend or Flutter command for the touched capability.
- **Per wave merge:** Run `npm test` plus focused `cd mobile && flutter test test/services/sos_*.dart test/screens/sos_screen_test.dart`.
- **Phase gate:** Full backend and mobile test suites plus physical-device/manual SOS protocol.

### Wave 0 Gaps

- [ ] `src/__tests__/sos/sos-api.test.ts` — covers EMERG-01 provider send and per-contact persistence.
- [ ] `src/__tests__/sos/sos-fallback.test.ts` — covers MOB-05 provider failure/native fallback record.
- [ ] `src/__tests__/sos/sos-notifications.test.ts` — covers NOTIF-02 socket/push fanout.
- [ ] `mobile/test/services/sos_location_service_test.dart` — covers MOB-04 permission/timeout/stale labels.
- [ ] `mobile/test/services/sos_platform_service_test.dart` — covers MOB-05 SMS and EMERG-02 `tel:115` launch.
- [ ] `mobile/test/screens/sos_screen_test.dart` — covers hold/countdown/cancel/status UI states.
- [ ] Manual protocol document or checklist — covers real device GPS, SMS composer, Twilio test number, Vietnam number, no-network fallback, haptic/visual accessibility.

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|------------------|
| V2 Authentication | yes | Verify JWT access token server-side; derive user ID from token, not request body. [VERIFIED: src/app/lib/auth.ts] |
| V3 Session Management | yes | Reuse existing access-token cookie/session pattern and fix mobile Bearer/cookie mismatch deliberately. [VERIFIED: src/app/api/calls/route.ts] [VERIFIED: mobile/lib/services/push_notification_service.dart] |
| V4 Access Control | yes | Backend loads contacts by authenticated `userId`; never accept send recipients from client. [VERIFIED: prisma/schema.prisma] |
| V5 Input Validation | yes | Zod schemas for coordinates, accuracy, timestamps, phone numbers, contact names, and Twilio callbacks. [VERIFIED: src/app/lib/validators.ts] |
| V6 Cryptography | yes | Keep Twilio auth token and webhook validation secrets server-side; do not expose SMS credentials to Flutter. [CITED: https://www.twilio.com/docs/messaging/api/message-resource] |
| V7 Error Handling and Logging | yes | Persist provider error codes and native fallback state without leaking secrets or exact location to logs beyond SOS records. [CITED: https://www.twilio.com/docs/messaging/api/message-resource] |
| V8 Data Protection | yes | SOS location is sensitive; store only required coordinates/accuracy/timestamps and avoid long medical payloads per deferred scope. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] |
| V10 Malicious Code | yes | Package legitimacy checkpoint required because slopcheck unavailable. |

### Known Threat Patterns for Next.js/Flutter SOS

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Forged SOS sends for another user | Spoofing/Elevation | Derive sender from verified JWT and ignore body `userId`. [VERIFIED: src/app/lib/auth.ts] |
| Recipient tampering | Tampering | Load contacts from DB by authenticated user and validate contact ownership on contact edits. [VERIFIED: prisma/schema.prisma] |
| SMS abuse/cost spike | Denial of Wallet | Rate-limit SOS endpoint per user/device while preserving emergency usability; monitor Twilio geo permissions and errors. [CITED: https://www.twilio.com/docs/messaging/guides/sms-geo-permissions] |
| Location privacy leakage | Information Disclosure | Send only emergency SMS payload to configured contacts; do not broadcast coordinates through generic logs. [VERIFIED: .planning/phases/05-sos-emergency-safety/05-CONTEXT.md] |
| Fake Twilio callback | Spoofing/Tampering | Validate Twilio webhook signatures before updating attempt status. [ASSUMED] |
| Replay/duplicate SOS | Repudiation/Tampering | Use idempotency keys or active-alert checks for repeated taps during countdown/send retries. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- `.planning/phases/05-sos-emergency-safety/05-CONTEXT.md` — locked SOS behavior and scope.
- `.planning/REQUIREMENTS.md` — EMERG-01, EMERG-02, MOB-04, MOB-05, NOTIF-02.
- `.planning/STATE.md` — milestone state and prior decisions.
- `package.json`, `mobile/pubspec.yaml`, `prisma/schema.prisma`, `src/app/lib/*`, `mobile/lib/*` — actual project stack and integration points.
- https://www.twilio.com/docs/messaging/api/message-resource — Twilio Message resource and callback properties.
- https://www.twilio.com/docs/messaging/guides/outbound-message-status-in-status-callbacks — outbound status lifecycle.
- https://www.twilio.com/docs/messaging/services — Messaging Service status callback and configuration.
- https://www.twilio.com/docs/messaging/guides/sms-geo-permissions — SMS geo-permission behavior.
- https://www.twilio.com/en-us/sms/pricing/vn — Vietnam SMS pricing/support page.
- https://www.twilio.com/docs/libraries/reference/twilio-node — official Node helper library.
- https://pub.dev/packages/geolocator — Flutter location APIs and permissions.
- https://pub.dev/packages/url_launcher — `tel:` and `sms:` launch support.
- https://developer.android.com/reference/android/content/Intent — `ACTION_DIAL` behavior.
- https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/PhoneLinks/PhoneLinks.html — iOS `tel` confirmation behavior.
- https://developer.apple.com/library/archive/featuredarticles/iPhoneURLScheme_Reference/SMSLinks/SMSLinks.html — iOS `sms` URL constraints.
- https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages — Flutter FCM foreground/background/terminated behavior.

### Secondary (MEDIUM confidence)

- https://www.gov.uk/foreign-travel-advice/vietnam/getting-help — UK travel advice lists Vietnam ambulance number 115 and Vietnamese-only emergency numbers.
- https://danang.gov.vn/so-dien-thoai-can-biet — Da Nang government page lists `Cấp cứu Y tế | 115`.

### Tertiary (LOW confidence)

- None used as a basis for recommendations.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH for Twilio/geolocator/url_launcher suitability from official docs; MEDIUM for package legitimacy because slopcheck was unavailable.
- Architecture: HIGH because it follows locked context and existing backend/mobile patterns.
- Pitfalls: HIGH for platform/Twilio callback issues from official docs; MEDIUM for Vietnam delivery reliability until live testing.

**Research date:** 2026-05-16  
**Valid until:** 2026-06-15 for package versions and Twilio docs; Vietnam SMS delivery assumptions should be rechecked within 7 days of implementation.
