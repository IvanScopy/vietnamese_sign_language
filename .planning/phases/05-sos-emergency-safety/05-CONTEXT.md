# Phase 05: SOS Emergency & Safety - Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the v1 mobile SOS safety workflow:

- Deaf users can trigger SOS from the mobile home screen.
- The SOS flow requests GPS location, sends emergency SMS alerts, and presents a 115 emergency-call handoff.
- SMS delivery uses a backend provider first, with native SMS composer fallback when provider/network delivery is unavailable.
- Emergency alerts go to all configured emergency contacts at the same time.
- The app gives clear visual and haptic status feedback for deaf users.
- SOS logs must preserve honest delivery states, especially when native SMS fallback cannot confirm that the user actually sent the message.

Out of scope:

- App-wide floating SOS button outside the home screen.
- Automatic emergency calling; the app may open the dialer for 115, but must not place the call automatically.
- Receiver acknowledgement flow.
- Escalation chains, staged retry ladders, or contact prioritization.
- Medical profile payloads or long health-record SMS content.
- Claiming native SMS was sent when the app only opened the SMS composer.

</domain>

<decisions>
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

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope

- `.planning/ROADMAP.md` — Phase 5 boundary, success criteria, dependencies, and v1 scope.
- `.planning/REQUIREMENTS.md` — Requirement IDs `EMERG-01`, `EMERG-02`, `MOB-04`, `MOB-05`, and `NOTIF-02`; also note the v1 exclusion of escalation chains.
- `.planning/STATE.md` — Current milestone status and prior validation gaps.
- `.planning/PROJECT.md` — Target users, platform strategy, privacy boundary, and safety context.
- `BRIEF.md` — Original SOS module notes: prominent SOS button, SMS to relatives, optional emergency-service contact, GPS location, and visual notification needs.
- `CLAUDE.md` — Existing stack notes for `permission_handler`, `geolocator`, `url_launcher`, local notifications, and SOS-related backend responsibilities.

### Prior Phase Context

- `.planning/phases/01-foundation-authentication/01-CONTEXT.md` — Auth/session, user profile, emergency contact, notification, Socket.io, and FCM/APNs foundation decisions.
- `.planning/phases/03-face-to-face-conversation-history/03-CONTEXT.md` — Mobile-first UX decisions, manual confirmation patterns, text-only privacy boundary, and non-flashing accessibility preference.
- `.planning/phases/04-video-calling/04-CONTEXT.md` — Hybrid Socket.io + FCM/APNs notification decisions, mobile/web notification scope, and no flashing visual effects.

### Existing Code

- `prisma/schema.prisma` — Existing `EmergencyContact`, `SOSAlert`, `SOSAlertReceiver`, `Notification`, and `DeviceToken` models; planner must reconcile freeform phone contacts with any user-linked receiver records.
- `src/app/api/user/profile/route.ts` — Profile endpoint currently returns emergency contacts; contact write/update support may need Phase 5 work.
- `src/app/lib/socket.ts` — Existing user rooms and preliminary `sos:alert` event; safety-critical SOS should be server-authoritative rather than trusting client-supplied contact lists.
- `src/app/api/notifications/send/route.ts` — Existing notification persistence plus foreground Socket.io emit path.
- `src/app/api/notifications/register-token/route.ts` — Existing device-token registration path for push-capable users.
- `src/app/lib/push.ts` — Existing FCM helper pattern for high-priority mobile push; can inform SOS push/helper design.
- `src/app/lib/validators.ts` — Existing Zod validation pattern for auth, notifications, and calls.
- `mobile/lib/main.dart` — Current Flutter home screen and route map; Phase 5 SOS entry point belongs here.
- `mobile/lib/services/push_notification_service.dart` — Existing FCM setup and notification-open routing pattern.
- `mobile/lib/config/app_config.dart` — Existing mobile API URL configuration.
- `mobile/pubspec.yaml` — Current Flutter dependency list; planner should add location/SMS/dialer dependencies intentionally.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `prisma/schema.prisma`: already has SOS/contact/notification tables that can seed Phase 5 persistence, though the receiver model may need adjustment for phone-number contacts.
- `src/app/api/user/profile/route.ts`: already exposes emergency contacts in the profile response.
- `src/app/api/notifications/send/route.ts`: already persists notifications and emits foreground Socket.io events.
- `src/app/lib/push.ts`: already demonstrates FCM multicast send, missing-Firebase graceful behavior, and stale-token cleanup.
- `src/app/lib/socket.ts`: already has `user:{userId}` Socket.io rooms for targeted foreground events.
- `mobile/lib/main.dart`: already has a home-screen action column and explicit route map where SOS can be added.
- `mobile/lib/config/app_config.dart`: already centralizes API URLs for mobile services.

### Established Patterns

- Backend uses Next.js route handlers, Prisma, Zod validation, and cookie/JWT auth helpers.
- Foreground realtime events use Socket.io user rooms; background mobile notifications use FCM/APNs where configured.
- Flutter app currently uses explicit `MaterialApp` routes and service objects passed into screens.
- Prior phases avoid pretending unverified actions are complete; Phase 5 should preserve that honesty for native SMS fallback.
- Prior notification decisions reject flashing effects and favor clear visual/haptic states for deaf users.

### Integration Points

- Add authenticated SOS API endpoints for creating an SOS alert, sending provider SMS, recording fallback/native-send states, updating late GPS, and resolving/cancelling alert state.
- Add a backend SMS provider abstraction or helper that returns explicit provider delivery attempt status.
- Add Flutter SOS home entry, hold-to-activate gesture, countdown screen, status screen, GPS permission/location service, SMS fallback launch, and 115 dialer launch.
- Add contact management if current profile APIs cannot create/update emergency contact phone numbers.
- Replace or constrain the current client-emitted `sos:alert` Socket.io path so trusted backend code selects recipients and payloads.
- Use notification persistence/Socket.io/FCM only as supporting status notification channels; SMS remains the primary emergency-contact delivery path.

</code_context>

<specifics>
## Specific Ideas

- The SOS flow should feel urgent but controlled: hold, countdown, cancel, then status.
- The user explicitly changed the SMS approach from native-only to hybrid provider-first plus native fallback.
- The app must be honest about native SMS limitations: opening the SMS composer is not the same as confirming the message was sent.
- The 115 flow is a user-controlled dialer handoff, not automatic calling.
- Sending to all configured emergency contacts is a simultaneous broadcast, not a multi-step escalation chain.

</specifics>

<deferred>
## Deferred Ideas

- App-wide floating SOS button can be reconsidered in a later app polish/settings phase.
- Receiver acknowledgement and two-way SOS status updates are future enhancements.
- Escalation chains, contact prioritization, retries over time, and "if no response then next contact" behavior remain deferred.
- Medical profile or long health-information payloads are deferred.
- User-selected recipients at SOS time are deferred because they slow down the emergency path.

</deferred>

---

*Phase: 05-SOS Emergency & Safety*
*Context gathered: 2026-05-16*
