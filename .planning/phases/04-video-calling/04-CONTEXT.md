# Phase 04: Video Calling - Context

**Gathered:** 2026-05-16
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers 1:1 in-app video calling between registered users, with integrated communication surfaces for deaf and hearing users:

- Registered users can initiate, receive, accept, reject, timeout, and end 1:1 video calls.
- LiveKit is the WebRTC/SFU stack for audio/video rooms.
- Socket.io handles foreground call signaling and incoming-call notifications.
- Mobile receives a minimal background push path through FCM/APNs for incoming calls.
- Web participates in the same user-facing call flow, with foreground/in-browser notifications first.
- Sign recognition output appears as text and user-confirmed TTS for the hearing participant.
- Hearing-user speech appears as live subtitles for the deaf participant.
- Call transcript text may be saved only when a user explicitly chooses to save it.

Out of scope:

- 3D avatar signing. Avatar work remains v2+.
- Multi-participant calls. Phase 4 is 1:1 only.
- Messenger/social chat features.
- Full call history analytics or rich call logs beyond minimal missed/rejected/ended call events.
- Full web background push via service worker unless planning finds it is trivial; web background push is not required for Phase 4 parity.
- Recording or retaining video/audio media.

</domain>

<decisions>
## Implementation Decisions

### Call Experience

- **D-01:** Use a full ringing flow. The caller sees an outgoing ringing screen; the receiver sees an incoming call screen with Accept and Reject actions.
- **D-02:** Unanswered incoming calls time out after 30 seconds and become missed calls.
- **D-03:** Persist a minimal call event or notification for missed, rejected, and ended calls so users do not lose call state when they miss the realtime prompt.
- **D-04:** Either participant pressing End ends the active 1:1 call for both participants.
- **D-05:** If the caller cancels before acceptance, the receiver's incoming prompt must be dismissed or marked unavailable.

### Translation Surface In Call

- **D-06:** Keep video as the primary surface and display sign text and speech subtitles as bottom overlays on the video.
- **D-07:** Sign recognition text follows a draft -> Confirm/Play flow before TTS is sent to the hearing participant.
- **D-08:** Do not auto-play TTS from raw phrase completion in calls; this matches Phase 3 and protects users from imperfect recognition.
- **D-09:** Hearing-user speech appears to the deaf participant as live subtitles overlayed on the video.
- **D-10:** Do not save video or audio media from calls.
- **D-11:** Save only text transcript, and only when the user explicitly chooses to save it after or during the call.

### Notification Behavior

- **D-12:** Implement foreground incoming-call signaling via Socket.io.
- **D-13:** Implement a minimal mobile background/closed-app incoming-call path through FCM/APNs.
- **D-14:** Tapping an incoming call notification opens the incoming call screen with Accept and Reject. The app joins LiveKit only after Accept.
- **D-15:** If a user is already in a call, automatically return busy to a second incoming caller and show only a lightweight notification to the busy receiver.
- **D-16:** Call notifications must include basic deaf-user visual and haptic affordances: clear color/icon treatment and simple vibration/haptic pattern.
- **D-17:** Do not use flashing visual effects.

### Mobile And Web Scope

- **D-18:** Develop mobile and web video calling in parallel for Phase 4. Do not split web video calling into a later process.
- **D-19:** Web is a user-facing Phase 4 feature, not an internal LiveKit demo page.
- **D-20:** Mobile and web must share the same backend API contracts, LiveKit room/token model, call state model, and signaling semantics.
- **D-21:** Use platform-native UI: Flutter-native mobile layout and responsive web layout rather than forcing pixel-perfect parity.
- **D-22:** Mobile notification support should be stronger than web in Phase 4: mobile uses FCM/APNs, while web supports foreground Socket.io and in-browser notifications when permission is available.

### the agent's Discretion

- Exact room naming, call state enum names, and database table names can be chosen during planning if they preserve the decisions above.
- Exact overlay placement, opacity, subtitle line limits, and responsive breakpoints can be refined during UI planning.
- Exact FCM/APNs provider setup can be scoped to the smallest reliable background incoming-call path.
- Web background push service worker support may be deferred unless research shows it is low-risk within Phase 4.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope

- `.planning/ROADMAP.md` — Phase 4 boundary, success criteria, dependencies, and v1 avatar exclusion.
- `.planning/REQUIREMENTS.md` — Requirement IDs `COMM-05`, `WEB-02`, and `NOTIF-01`.
- `.planning/STATE.md` — Current milestone status, Phase 2 validation gaps, and avatar deferral.
- `.planning/PROJECT.md` — Product vision, target users, v1 constraints, privacy boundary, and platform strategy.

### Prior Phase Context

- `.planning/phases/01-foundation-authentication/01-CONTEXT.md` — LiveKit, Socket.io, auth/session, notification, STT/TTS, and shared API decisions.
- `.planning/phases/02-sign-language-recognition/02-CONTEXT.md` — Recognition pipeline, phrase completion, confidence handling, TTS behavior, and Phase 2 constraints.
- `.planning/phases/03-face-to-face-conversation-history/03-CONTEXT.md` — Conversation mode, draft/confirm lifecycle, subtitle/TTS behavior, manual fallback, and local text-only history decisions.
- `.planning/phases/03-face-to-face-conversation-history/03-01-SUMMARY.md` — Implemented conversation and history assets that Phase 4 can reuse or mirror.

### Existing Code

- `src/lib/livekit.ts` — Existing LiveKit token helpers.
- `src/app/lib/socket.ts` — Existing Socket.io setup and current `call:incoming` event shape.
- `src/app/api/notifications/send/route.ts` — Existing notification persistence and foreground Socket.io emit path.
- `src/app/api/notifications/register-token/route.ts` — Existing device token registration path for push notification work.
- `prisma/schema.prisma` — Existing user, device token, notification, and SOS models; likely location for call event persistence.
- `docker-compose.yml` — Existing LiveKit service container.
- `livekit.yaml` — Existing local LiveKit server configuration.
- `mobile/lib/main.dart` — Existing Flutter routing pattern and home screen entry points.
- `mobile/lib/config/app_config.dart` — Existing HTTP/WebSocket URL config.
- `mobile/lib/screens/conversation_screen.dart` — Existing draft/confirm conversation behavior and STT/TTS integration.
- `mobile/lib/services/sign_recognition_service.dart` — Existing Socket.io recognition client and connection streams.
- `mobile/lib/services/speech_transcription_service.dart` — Existing STT endpoint client.
- `mobile/lib/services/conversation_history_service.dart` — Existing text-only local history service.
- `mobile/pubspec.yaml` — Existing Flutter dependencies; planner must add LiveKit/push/browser-related dependencies deliberately.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- `src/lib/livekit.ts`: already generates LiveKit room tokens and can seed authenticated call-token endpoints.
- `src/app/lib/socket.ts`: already tracks user-specific Socket.io rooms and has an initial `call:incoming` event.
- `src/app/api/notifications/send/route.ts`: already stores notifications and emits foreground events; can be extended for call events and mobile push.
- `prisma/schema.prisma`: already has `DeviceToken` and `Notification`; Phase 4 likely needs call session/event persistence.
- `mobile/lib/main.dart`: existing route map can add incoming call, outgoing call, and active call screens.
- `mobile/lib/config/app_config.dart`: existing HTTP/WebSocket URL helpers can be extended with LiveKit URL config.
- `mobile/lib/screens/conversation_screen.dart`: source for draft/confirm text, TTS, STT, and transcript-save patterns.
- `mobile/lib/services/sign_recognition_service.dart`: source for sign recognition stream reuse inside calls.
- `mobile/lib/services/speech_transcription_service.dart`: source for speech subtitle transcription calls.

### Established Patterns

- Backend uses Next.js route handlers, Zod validation, Prisma, JWT auth, and Socket.io.
- Realtime foreground events use Socket.io user rooms named `user:{userId}`.
- Notifications are persisted server-side and emitted realtime when possible.
- LiveKit is already present in dependencies and Docker Compose.
- Flutter app uses explicit `MaterialApp` routes and service objects passed into screens.
- Phase 3 established a draft -> confirmed message lifecycle and explicit user-triggered TTS playback.

### Integration Points

- Add authenticated call endpoints for create/invite, accept, reject, cancel, end, token retrieval, and call event persistence.
- Add Socket.io call events for incoming, accepted, rejected, cancelled, ended, missed, and busy states.
- Add minimal mobile push send path for incoming calls using existing `DeviceToken` storage.
- Add Flutter screens for outgoing ringing, incoming ringing, active call, and ended/missed states.
- Add web user-facing call flow using the same backend contracts and LiveKit room/token model.
- Integrate existing sign recognition, STT, and TTS flows into active call UI overlays.

</code_context>

<specifics>
## Specific Ideas

- The call should feel like a real video call, not just joining a test room.
- The user explicitly wants web and mobile developed in parallel to avoid creating another process later.
- Web should be treated as a real user-facing feature for Phase 4, not a demo page.
- The app should preserve v1 privacy: text-only transcript can be saved by user choice; no video/audio recording.
- Accessibility for deaf users starts with clear visual/haptic incoming-call affordances and avoids flashing.

</specifics>

<deferred>
## Deferred Ideas

- Multi-participant video calling belongs to a future phase.
- Full web background push via service worker may be deferred unless it is low-risk during planning.
- Full call history, analytics, redial workflows, and call waiting can be future enhancements.
- User-customizable notification color/pattern settings can be handled in later app polish/settings work.
- 3D avatar signing remains v2+.

</deferred>

---

*Phase: 04-Video Calling*
*Context gathered: 2026-05-16*
