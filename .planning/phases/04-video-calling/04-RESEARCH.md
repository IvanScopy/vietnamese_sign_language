# Phase 04: Video Calling - Research

**Researched:** 2026-05-16  
**Domain:** 1:1 WebRTC video calling, LiveKit, Socket.io signaling, Flutter/Next.js clients, mobile push notifications  
**Confidence:** HIGH for architecture and LiveKit patterns; MEDIUM for push-provider operational setup because Firebase/APNs credentials are not present locally.

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions
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

### Deferred Ideas (OUT OF SCOPE)

- Multi-participant video calling belongs to a future phase.
- Full web background push via service worker may be deferred unless it is low-risk during planning.
- Full call history, analytics, redial workflows, and call waiting can be future enhancements.
- User-customizable notification color/pattern settings can be handled in later app polish/settings work.
- 3D avatar signing remains v2+.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| COMM-05 | Video calling between registered users (1:1) using WebRTC with audio/video. [CITED: .planning/REQUIREMENTS.md] | Use LiveKit rooms for media, backend call sessions for lifecycle authority, and platform clients that join only after accept. [CITED: docs.livekit.io/frontends/build/authentication/] |
| WEB-02 | WebRTC support for video calling on Chrome/Firefox/Safari. [CITED: .planning/REQUIREMENTS.md] | Use LiveKit React/client SDK components on the Next.js app and browser permission prompts for camera/microphone. [CITED: docs.livekit.io/reference/components/react/component/livekitroom/] [CITED: docs.livekit.io/transport/media/publish/] |
| NOTIF-01 | Visual push notifications for incoming video calls. [CITED: .planning/REQUIREMENTS.md] | Use Socket.io user rooms for foreground delivery and FCM/APNs via stored device tokens for mobile background delivery. [CITED: socket.io/docs/v4/rooms/] [CITED: firebase.google.com/docs/cloud-messaging/send/admin-sdk] |
</phase_requirements>

## Summary

Phase 04 should be planned as a three-tier call system: backend-owned call state, LiveKit-owned audio/video media, and client-owned rendering/permission UX. [VERIFIED: codebase grep] The existing repo already has Prisma users/device tokens/notifications, Socket.io user rooms, LiveKit token helpers, Flutter recognition/STT/TTS services, and a self-hosted LiveKit container, so planning should extend those assets instead of creating a parallel call stack. [VERIFIED: codebase grep]

The core implementation decision is to make `CallSession` the authoritative lifecycle object and treat LiveKit rooms as media transport that only become joinable after `accept`. [ASSUMED] LiveKit documentation requires frontend access tokens to be generated by a backend because API keys are secret, and clients connect with a room token and server URL. [CITED: docs.livekit.io/frontends/build/authentication/] Socket.io rooms are a standard server-side mechanism for sending events to every device/tab for one user, which matches this app's existing `user:{userId}` room pattern. [CITED: socket.io/docs/v4/rooms/] [VERIFIED: codebase grep]

**Primary recommendation:** Build a backend call state machine (`initiated -> ringing -> accepted/active -> ended | rejected | cancelled | missed | busy | failed`) with race-safe endpoints, emit Socket.io lifecycle events from those endpoints, issue short-lived LiveKit participant tokens only after accept, and keep transcript persistence explicit and text-only. [ASSUMED]

## Project Constraints (from AGENTS.md)

No `AGENTS.md` exists at the repository root, verified by `test -f AGENTS.md`. [VERIFIED: codebase grep]

No project-local `.codex/skills/` or `.agents/skills/` directory exists, verified by `find .codex/skills .agents/skills -maxdepth 2 -name SKILL.md`. [VERIFIED: codebase grep]

Graphify is disabled for this project, so no semantic graph relationships were available for Phase 04 research. [VERIFIED: codebase grep]

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Call lifecycle and race resolution | API / Backend | Database / Storage | Backend must own caller/receiver eligibility, 30s timeout, busy response, and accepted/ended state so mobile and web share semantics. [ASSUMED] |
| LiveKit room/token issuance | API / Backend | LiveKit service | LiveKit docs state token generation requires API keys and should happen on a backend server. [CITED: docs.livekit.io/frontends/build/authentication/] |
| Audio/video transport | LiveKit / WebRTC service | Browser / Mobile clients | LiveKit SDKs publish and subscribe to camera/microphone tracks, while clients render tracks and handle permissions. [CITED: docs.livekit.io/transport/media/publish/] |
| Foreground ringing and call events | API / Backend | Socket.io clients | Socket.io rooms support broadcasting to subsets of clients, and the current app already joins `user:{userId}` rooms. [CITED: socket.io/docs/v4/rooms/] [VERIFIED: codebase grep] |
| Mobile background incoming call path | API / Backend | Mobile OS push layer | Firebase Admin SDK can send to device registration tokens, and Flutter FCM handles notification-open routing. [CITED: firebase.google.com/docs/cloud-messaging/send/admin-sdk] [CITED: firebase.google.com/docs/cloud-messaging/flutter/receive-messages] |
| Web call UI | Browser / Client | API / Backend | Next.js web must render a real call flow and request LiveKit tokens from shared backend contracts. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] |
| Mobile call UI | Mobile Client | API / Backend | Flutter app owns haptics, native permissions, route handling, and LiveKit track rendering. [CITED: docs.livekit.io/transport/sdk-platforms/flutter/] |
| Sign/speech overlays | Mobile/Web Clients | Recognition/STT/TTS services | Existing Phase 3 services already produce sign text, STT subtitles, and TTS audio; Phase 04 should reuse the flow as in-call overlays. [VERIFIED: codebase grep] |
| Transcript save | Mobile/Web Clients | Local/backend storage chosen by plan | User decision allows only explicit text transcript saving and forbids video/audio recording. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `livekit-server-sdk` [ASSUMED: slopcheck unavailable] | 2.15.3 latest; repo currently has ^2.15.2. [VERIFIED: npm registry] | Generate backend LiveKit participant tokens and room-scoped grants. [CITED: docs.livekit.io/reference/server-sdk-js/classes/AccessToken.html] | LiveKit's JS Server SDK exposes `AccessToken.addGrant` and `VideoGrant` permissions such as `roomJoin`, `canPublish`, and `canSubscribe`. [CITED: docs.livekit.io/reference/server-sdk-js/interfaces/VideoGrant.html] |
| `@livekit/components-react` [ASSUMED: slopcheck unavailable] | 2.9.21. [VERIFIED: npm registry] | React UI primitives and room context for the Next.js call UI. [CITED: docs.livekit.io/reference/components/react/component/livekitroom/] | `LiveKitRoom` provides room context and accepts `token`, `serverUrl`, `connect`, `audio`, and `video` props. [CITED: docs.livekit.io/reference/components/react/component/livekitroom/] |
| `livekit-client` [ASSUMED: slopcheck unavailable] | 2.19.0. [VERIFIED: npm registry] | Lower-level browser Room APIs when custom web layout needs more control than prebuilt components. [CITED: npmjs.com/package/livekit-client] | The SDK supports Room connection, event handlers, adaptive stream, and dynacast in browser clients. [CITED: npmjs.com/package/livekit-client] |
| `livekit_client` [ASSUMED: slopcheck unavailable] | 2.7.0. [VERIFIED: pub.dev dry-run] | Flutter LiveKit room connection, media publishing, and track rendering. [CITED: docs.livekit.io/transport/sdk-platforms/flutter/] | Official LiveKit Flutter quickstart installs `livekit_client` and shows `Room.connect`, `setCameraEnabled`, and `setMicrophoneEnabled`. [CITED: docs.livekit.io/transport/sdk-platforms/flutter/] |
| `socket.io` | ^4.8.3 existing. [VERIFIED: codebase grep] | Foreground call signaling and per-user event fanout. [CITED: socket.io/docs/v4/rooms/] | Socket.io rooms can broadcast events to every socket for a user; the app already uses `user:{userId}` rooms. [CITED: socket.io/docs/v4/rooms/] [VERIFIED: codebase grep] |
| `firebase-admin` [ASSUMED: slopcheck unavailable] | 13.10.0. [VERIFIED: npm registry] | Backend send path for FCM messages to mobile device tokens. [CITED: firebase.google.com/docs/cloud-messaging/send/admin-sdk] | Firebase Admin SDK sends messages to device registration tokens and supports multicast responses for failed-token cleanup. [CITED: firebase.google.com/docs/cloud-messaging/send/admin-sdk] |
| `firebase_core` [ASSUMED: slopcheck unavailable] | 4.9.0. [VERIFIED: pub.dev dry-run] | Flutter Firebase initialization. [CITED: pub.dev/packages/firebase_core] | FlutterFire packages require Firebase app initialization before messaging use. [CITED: firebase.google.com/docs/cloud-messaging/flutter/receive-messages] |
| `firebase_messaging` [ASSUMED: slopcheck unavailable] | 16.2.2. [VERIFIED: pub.dev dry-run] | Flutter FCM token registration, foreground/background messages, and notification-open routing. [CITED: firebase.google.com/docs/cloud-messaging/flutter/receive-messages] | FCM Flutter docs expose `getInitialMessage()` and `onMessageOpenedApp` for terminated/background notification interactions. [CITED: firebase.google.com/docs/cloud-messaging/flutter/receive-messages] |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| Prisma / `@prisma/client` | ^7.8.0 existing. [VERIFIED: codebase grep] | Add `CallSession`, `CallEvent`, optional `CallTranscript` models. [ASSUMED] | Use for durable call lifecycle, missed/rejected/ended event persistence, and user/device-token relations. [VERIFIED: codebase grep] |
| `zod` | ^4.4.3 existing. [VERIFIED: codebase grep] | Validate call endpoint payloads and signaling payload shape. [VERIFIED: codebase grep] | Required for create/accept/reject/cancel/end/token endpoints to prevent invalid user IDs and state transitions. [ASSUMED] |
| `permission_handler` | ^12.0.1 existing. [VERIFIED: codebase grep] | Flutter camera/microphone/notification permission handling. [VERIFIED: codebase grep] | Use before joining LiveKit and before registering push notifications. [ASSUMED] |
| Existing STT/TTS/recognition services | Local code. [VERIFIED: codebase grep] | In-call subtitle and sign/TTS overlays. [VERIFIED: codebase grep] | Reuse `SignRecognitionService`, `SpeechTranscriptionService`, and Phase 3 draft/confirm/TTS behavior. [VERIFIED: codebase grep] |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| LiveKit SFU | Direct peer-to-peer WebRTC | Rejected by locked decision; direct WebRTC would require custom signaling, ICE/TURN handling, reconnection, and browser/mobile edge cases. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] [ASSUMED] |
| FCM for mobile push | Direct APNs plus FCM for Android | The locked decision says FCM/APNs; Firebase Cloud Messaging can bridge Android and iOS via platform setup, while direct APNs adds separate credential and payload code. [CITED: firebase.google.com/docs/cloud-messaging/send/admin-sdk] [ASSUMED] |
| Web background push in Phase 04 | Service worker web push | Deferred unless trivial; web foreground and browser notification permission are enough for Phase 04 parity decision. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] |

**Installation:**

```bash
npm install @livekit/components-react livekit-client firebase-admin
cd mobile && flutter pub add livekit_client firebase_core firebase_messaging
```

**Version verification:** `npm view` succeeded with escalated network access for npm packages. [VERIFIED: npm registry] `flutter pub add --dry-run` succeeded with escalated access for Flutter packages. [VERIFIED: pub.dev dry-run] `slopcheck` was unavailable after best-effort install, so all new packages are still tagged `[ASSUMED]` per the package legitimacy protocol. [VERIFIED: codebase grep]

## Package Legitimacy Audit

| Package | Registry | Age | Downloads | Source Repo | slopcheck | Disposition |
|---------|----------|-----|-----------|-------------|-----------|-------------|
| `@livekit/components-react` [ASSUMED] | npm | Multi-year package; latest modified 2026-05-05. [VERIFIED: npm registry] | npm page reported 126,004 weekly downloads for a prior crawled version. [CITED: npmjs.com/package/%40livekit/components-react] | github.com/livekit/components-js. [VERIFIED: npm registry] | unavailable | Approved with planner human-verify checkpoint |
| `livekit-client` [ASSUMED] | npm | Multi-year package; latest modified 2026-05-13. [VERIFIED: npm registry] | npm page reported established package metadata. [CITED: npmjs.com/package/livekit-client] | github.com/livekit/client-sdk-js. [VERIFIED: npm registry] | unavailable | Approved with planner human-verify checkpoint |
| `firebase-admin` [ASSUMED] | npm | Multi-year package; latest modified 2026-05-14. [VERIFIED: npm registry] | npm page reported 2,356,842 weekly downloads for a prior crawled version. [CITED: npmjs.com/package/firebase-admin] | github.com/firebase/firebase-admin-node. [VERIFIED: npm registry] | unavailable | Approved with planner human-verify checkpoint |
| `livekit_client` [ASSUMED] | pub.dev | Published 44 days before crawl for 2.7.0. [CITED: pub.dev/packages/livekit_client] | pub.dev lists package metadata; exact weekly downloads not shown in fetched snippet. [CITED: pub.dev/packages/livekit_client] | LiveKit GitHub repository linked from pub.dev. [CITED: pub.dev/packages/livekit_client] | unavailable | Approved with planner human-verify checkpoint |
| `firebase_core` [ASSUMED] | pub.dev | Version 4.9.0 published 26 hours before crawl. [CITED: pub.dev/packages/firebase_core] | pub.dev lists 4.0k likes. [CITED: pub.dev/packages/firebase_core] | Firebase/FlutterFire repository linked from pub.dev. [CITED: pub.dev/packages/firebase_core] | unavailable | Approved with planner human-verify checkpoint |
| `firebase_messaging` [ASSUMED] | pub.dev | Version 16.2.2 published 33 hours before crawl. [CITED: pub.dev/packages/firebase_messaging] | pub.dev lists 1.97M downloads and 3.9k likes. [CITED: pub.dev/packages/firebase_messaging] | Firebase/FlutterFire repository linked from pub.dev. [CITED: pub.dev/packages/firebase_messaging] | unavailable | Approved with planner human-verify checkpoint |

**Packages removed due to slopcheck [SLOP] verdict:** none; slopcheck unavailable. [VERIFIED: codebase grep]  
**Packages flagged as suspicious [SUS]:** all new packages require human verification only because slopcheck was unavailable, not because any registry/source signal was suspicious. [ASSUMED]

## Architecture Patterns

### System Architecture Diagram

```text
Caller client
  -> POST /api/calls {calleeId}
  -> Backend validates auth, callee, busy state, creates CallSession(ringing, expiresAt=now+30s)
  -> Socket.io emit call:incoming to user:{calleeId}
  -> FCM/APNs send incoming-call notification to callee mobile tokens
  -> Caller receives call:ringing

Callee client
  -> Accept or Reject
  -> POST /api/calls/{id}/accept or /reject
  -> Backend atomically transitions state
  -> On accept: backend issues room-scoped LiveKit tokens for participants
  -> Socket.io emits call:accepted to both users
  -> Both clients connect to LiveKit room and publish camera/mic

Active call
  -> LiveKit transports audio/video tracks
  -> Existing sign recognition stream produces draft sign text
  -> Confirm / Confirm & Play sends text/TTS to hearing side overlay/audio path
  -> Existing STT endpoint produces speech subtitles for deaf side overlay
  -> End by either participant calls POST /api/calls/{id}/end
  -> Backend marks ended, emits call:ended, clients disconnect LiveKit and offer text transcript save

Timeout/error paths
  -> 30s timer or scheduled check marks ringing call missed
  -> Caller cancel marks cancelled and dismisses receiver prompt
  -> Busy receiver returns busy without creating competing active room
  -> Permission/network failures keep call recoverable or failed without media retention
```

### Recommended Project Structure

```text
src/app/api/calls/
├── route.ts                 # create/list minimal call events
├── [callId]/accept/route.ts # atomic accept + token response
├── [callId]/reject/route.ts
├── [callId]/cancel/route.ts
├── [callId]/end/route.ts
└── [callId]/token/route.ts  # reissue token for accepted participants only

src/app/lib/
├── calls.ts                 # call state machine and Prisma helpers
├── call-signaling.ts        # Socket.io event emit helpers
├── push.ts                  # FCM send + failed token cleanup
└── livekit.ts               # token helpers, updated for async toJwt

src/app/calls/
├── page.tsx                 # web call entry
└── [callId]/page.tsx        # active/ringing call UI

mobile/lib/screens/calls/
├── call_entry_screen.dart
├── incoming_call_screen.dart
├── outgoing_call_screen.dart
├── active_call_screen.dart
└── call_result_screen.dart

mobile/lib/services/
├── call_api_service.dart
├── call_signaling_service.dart
├── livekit_call_service.dart
└── push_notification_service.dart
```

### Pattern 1: Backend-Owned Call State Machine

**What:** Store a `CallSession` row with caller, callee, room name, state, timestamps, and terminal reason. [ASSUMED]  
**When to use:** Every call lifecycle action, including timeout, cancel, reject, accept, busy, and end. [ASSUMED]  
**Example:**

```typescript
// Source: existing Prisma + route-handler pattern in this repo; state names are recommended.
const next = await prisma.callSession.updateMany({
  where: { id: callId, calleeId: user.id, state: 'RINGING', expiresAt: { gt: new Date() } },
  data: { state: 'ACCEPTED', acceptedAt: new Date() },
});
if (next.count !== 1) return NextResponse.json({ error: 'Call unavailable' }, { status: 409 });
```

### Pattern 2: Token Issuance Only After Accept

**What:** Generate room-scoped LiveKit tokens from authenticated backend endpoints after call state allows joining. [CITED: docs.livekit.io/frontends/build/authentication/]  
**When to use:** Accept response and token refresh/retry for participants in accepted/active calls. [ASSUMED]  
**Example:**

```typescript
// Source: LiveKit AccessToken/VideoGrant docs; toJwt returns a Promise in SDK reference.
const token = new AccessToken(process.env.LIVEKIT_API_KEY, process.env.LIVEKIT_API_SECRET, {
  identity: `user-${userId}`,
  name: displayName,
});
token.addGrant({ roomJoin: true, room: roomName, canPublish: true, canSubscribe: true });
return token.toJwt();
```

### Pattern 3: Socket.io Emits from Server-Side Mutations

**What:** REST endpoints mutate call state, then emit lifecycle events to `user:{id}` rooms. [VERIFIED: codebase grep]  
**When to use:** Incoming, accepted, rejected, cancelled, ended, missed, busy, and failed events. [ASSUMED]  
**Example:**

```typescript
// Source: Socket.io rooms docs and existing src/app/lib/socket.ts user room pattern.
io.to(`user:${calleeId}`).emit('call:incoming', { callId, fromUserId, expiresAt, type: 'VIDEO_CALL' });
io.to(`user:${callerId}`).emit('call:accepted', { callId, roomName });
```

### Pattern 4: LiveKit Client Rendering

**What:** Web wraps call UI in `LiveKitRoom`; Flutter uses `Room.connect`, publishes camera/mic, and renders remote/local tracks. [CITED: docs.livekit.io/reference/components/react/component/livekitroom/] [CITED: docs.livekit.io/transport/sdk-platforms/flutter/]  
**When to use:** Only after accept and permission checks. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md]  
**Example:**

```tsx
// Source: LiveKit React LiveKitRoom docs.
<LiveKitRoom token={token} serverUrl={liveKitUrl} connect audio video>
  <ActiveCallCanvas />
</LiveKitRoom>
```

```dart
// Source: LiveKit Flutter quickstart.
final room = Room();
await room.connect(url, token, roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
await room.localParticipant?.setCameraEnabled(true);
await room.localParticipant?.setMicrophoneEnabled(true);
```

### Anti-Patterns to Avoid

- **Client-created call truth:** Do not let mobile/web emit `call:incoming` directly as the source of truth; clients can spoof or race states. [ASSUMED]
- **Joining LiveKit before accept:** This violates the locked flow and can open camera/mic before receiver consent. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md]
- **Persisting media:** Do not add LiveKit Egress, recording, or raw media storage in Phase 04. [CITED: .planning/REQUIREMENTS.md]
- **Using notification rows as call sessions:** Notifications are durable user messages, not enough for race-safe active/busy/timeout state. [ASSUMED]
- **One-off web demo:** Web must share API contracts and be user-facing, not a separate LiveKit sample page. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md]

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| WebRTC media transport | Custom peer connections, SDP exchange, ICE candidate signaling | LiveKit SDKs and self-hosted LiveKit server | LiveKit handles SFU transport, SDK room state, track publish/subscribe, and TURN integration. [CITED: docs.livekit.io/transport/media/publish/] [CITED: docs.livekit.io/transport/self-hosting/deployment/] |
| LiveKit auth tokens | Client-side API key use or unsigned ad hoc tokens | `livekit-server-sdk` backend `AccessToken` | LiveKit says token generation requires API keys and must happen on backend. [CITED: docs.livekit.io/frontends/build/authentication/] |
| Push delivery protocol | Raw APNs/FCM HTTP from scratch | `firebase-admin` for FCM sends | Firebase Admin SDK sends to registration tokens and returns failure details for cleanup. [CITED: firebase.google.com/docs/cloud-messaging/send/admin-sdk] |
| In-call sign recognition | New recognition pipeline | Existing `SignRecognitionService` and Phase 3 draft flow | Existing Flutter service exposes recognition, phrase, and connection streams. [VERIFIED: codebase grep] |
| STT/TTS | New speech stack | Existing `/api/stt/transcribe`, `/api/tts/synthesize`, and `SpeechTranscriptionService` | Phase 1/3 already implemented Vietnamese STT/TTS endpoints and client service. [VERIFIED: codebase grep] |
| Call race handling | Client timers as authority | Backend atomic Prisma transitions | Accept/reject/cancel/timeout/end races require a single authoritative persistence layer. [ASSUMED] |

**Key insight:** LiveKit should own realtime media, but it should not own product call state; the app's backend must own whether a call exists, who may join, and what terminal event gets persisted. [ASSUMED]

## Common Pitfalls

### Pitfall 1: LiveKit Token Helper May Be Sync-Wrong
**What goes wrong:** Current `src/lib/livekit.ts` returns `token.toJwt()` as a string, but the LiveKit SDK reference documents `toJwt(): Promise<string>`. [VERIFIED: codebase grep] [CITED: docs.livekit.io/reference/server-sdk-js/classes/AccessToken.html]  
**Why it happens:** Existing helper likely predates or ignores current SDK typing. [ASSUMED]  
**How to avoid:** Planner should include a Wave 0 task to make token helpers async and update tests. [ASSUMED]  
**Warning signs:** TypeScript compile errors, token response serializes `{}` or a Promise-like value. [ASSUMED]

### Pitfall 2: `call:incoming` Is Currently Client-Emittable
**What goes wrong:** Current Socket.io handler accepts `call:incoming` from clients and forwards it. [VERIFIED: codebase grep]  
**Why it happens:** Phase 1 created a placeholder notification event. [VERIFIED: codebase grep]  
**How to avoid:** Remove or restrict client-originating call mutation events; only authenticated REST endpoints should emit call lifecycle events. [ASSUMED]  
**Warning signs:** A mobile client can ring arbitrary `toUserId` without backend call persistence. [ASSUMED]

### Pitfall 3: Busy State Across Multiple Devices
**What goes wrong:** A user logged in on mobile and web might accept on one device while the other still shows incoming. [ASSUMED]  
**Why it happens:** Phase 1 allows multiple concurrent sessions. [CITED: .planning/phases/01-foundation-authentication/01-CONTEXT.md]  
**How to avoid:** Emit accepted/cancelled/ended to every `user:{id}` socket and require state refresh on call-screen focus. [CITED: socket.io/docs/v4/rooms/]  
**Warning signs:** Receiver gets two active screens or caller sees ringing after accept. [ASSUMED]

### Pitfall 4: Mobile Push Cannot Be Fully Validated in Simulator
**What goes wrong:** Background/terminated push and APNs integration fail despite foreground Socket.io working. [ASSUMED]  
**Why it happens:** FlutterFire notes APNs works only with real devices and platform setup is required. [CITED: firebase.flutter.dev/docs/messaging/apple-integration/]  
**How to avoid:** Plan real-device UAT for Android and iOS, and keep Phase 04 push path minimal. [ASSUMED]  
**Warning signs:** `onMessageOpenedApp` works on Android but iOS terminated notifications do not route to the incoming screen. [ASSUMED]

### Pitfall 5: TURN Not Configured for Real Networks
**What goes wrong:** Calls work locally but fail behind corporate/mobile NATs. [ASSUMED]  
**Why it happens:** WebRTC deployment requires UDP ports, public IP awareness, trusted TLS, and TURN for restrictive networks. [CITED: docs.livekit.io/transport/self-hosting/deployment/]  
**How to avoid:** Keep local LiveKit config for dev, but add production notes for domain, trusted SSL, `use_external_ip`, Redis, and embedded TURN/TLS or TURN/UDP. [CITED: docs.livekit.io/transport/self-hosting/deployment/]  
**Warning signs:** Signaling connects but media never appears, or only one participant receives video. [ASSUMED]

## Code Examples

### Backend Call Event Contract

```typescript
// Source: Existing Socket.io user rooms + Phase 04 context.
type CallEvent =
  | { type: 'call:incoming'; callId: number; fromUserId: number; expiresAt: string }
  | { type: 'call:accepted'; callId: number; roomName: string }
  | { type: 'call:rejected' | 'call:cancelled' | 'call:missed' | 'call:ended' | 'call:busy'; callId: number };
```

### Prisma Schema Shape

```prisma
// Source: Recommended extension of existing prisma/schema.prisma.
model CallSession {
  id         Int       @id @default(autoincrement())
  roomName   String    @unique
  callerId   Int
  calleeId   Int
  state      CallState @default(RINGING)
  expiresAt  DateTime
  acceptedAt DateTime?
  endedAt    DateTime?
  createdAt  DateTime  @default(now())
}

enum CallState {
  RINGING
  ACTIVE
  ENDED
  REJECTED
  CANCELLED
  MISSED
  BUSY
  FAILED
}
```

### Mobile Push Open Handling

```dart
// Source: Firebase Flutter receive messages docs.
final initial = await FirebaseMessaging.instance.getInitialMessage();
if (initial?.data['type'] == 'VIDEO_CALL') {
  navigatorKey.currentState?.pushNamed('/calls/incoming', arguments: initial!.data);
}

FirebaseMessaging.onMessageOpenedApp.listen((message) {
  if (message.data['type'] == 'VIDEO_CALL') {
    navigatorKey.currentState?.pushNamed('/calls/incoming', arguments: message.data);
  }
});
```

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Direct peer-to-peer WebRTC per app | SFU-backed LiveKit rooms with SDKs for web and mobile | Locked before Phase 04 planning. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] | Planner should not design custom SDP/ICE signaling. [ASSUMED] |
| Client-side token generation | Backend-generated LiveKit JWT token endpoints | Current LiveKit docs. [CITED: docs.livekit.io/frontends/build/authentication/] | API keys stay server-side; token issuance can enforce call state. [ASSUMED] |
| Web background parity with mobile | Mobile push first; web foreground/browser notifications first | Locked before Phase 04 planning. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] | Avoid over-scoping service-worker push unless low-risk. [ASSUMED] |
| Auto-play TTS on phrase completion | Draft -> Confirm / Confirm & Play | Established in Phase 3 and locked for Phase 4. [VERIFIED: codebase grep] [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] | Protects hearing participant from raw recognition errors. [ASSUMED] |

**Deprecated/outdated:**
- Current placeholder `socket.on('call:incoming')` as a client-originating event should be replaced for Phase 04 with server-emitted lifecycle events from authenticated endpoints. [VERIFIED: codebase grep] [ASSUMED]
- Current `livekit.yaml` is development-only because production LiveKit needs domain, trusted SSL, public IP/TURN configuration, and Redis recommendation. [VERIFIED: codebase grep] [CITED: docs.livekit.io/transport/self-hosting/deployment/]

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `CallSession` should be authoritative and LiveKit should only transport media. | Summary / Patterns | If wrong, planner might overbuild backend state; if omitted, clients can race and spoof call state. |
| A2 | State enum names and table shapes are recommended, not locked. | Architecture / Code Examples | Planner may need to rename to match local conventions. |
| A3 | All new packages require human verification because slopcheck was unavailable. | Package Legitimacy Audit | Planner must add checkpoint tasks before installation. |
| A4 | Web background push should remain deferred unless trivial. | Standard Stack / Pitfalls | If product needs full parity now, planning scope expands significantly. |
| A5 | Backend atomic transitions are needed for call accept/reject/cancel/timeout races. | Don't Hand-Roll / Pitfalls | If ignored, duplicate active calls and stale ringing screens are likely. |

## Open Questions

1. **Should text transcripts be local-only like Phase 3 or optionally backend-synced?**
   - What we know: Phase 04 allows explicit text transcript saving and forbids media recording. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md]
   - What's unclear: The storage location for video-call transcript text is not locked. [ASSUMED]
   - Recommendation: Keep mobile transcript save local-only for parity with Phase 3 unless web requires backend persistence; if web saves transcripts, create explicit `CallTranscript` rows with confirmed text only. [ASSUMED]

2. **Which Firebase project/APNs credentials exist?**
   - What we know: `DeviceToken` storage exists and FCM/APNs is locked as minimal mobile background path. [VERIFIED: codebase grep] [CITED: .planning/phases/04-video-calling/04-CONTEXT.md]
   - What's unclear: No Firebase service account or mobile Firebase config files were found during research. [VERIFIED: codebase grep]
   - Recommendation: Plan an environment/config checkpoint and make push implementation gracefully no-op in dev when credentials are missing. [ASSUMED]

3. **What is the production LiveKit deployment target?**
   - What we know: Docker Compose contains local LiveKit with HTTP/WS/UDP ports and simple `livekit.yaml`. [VERIFIED: codebase grep]
   - What's unclear: Production domain, TLS, TURN domain, and firewall rules are not specified. [ASSUMED]
   - Recommendation: Phase 04 should implement local/dev support and document production TURN/TLS requirements rather than blocking feature work on deployment provisioning. [ASSUMED]

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Node.js | Next.js backend/web | yes | v20.20.2 [VERIFIED: codebase grep] | none needed |
| npm | package verification/install | yes | 10.8.2 [VERIFIED: codebase grep] | none needed |
| Flutter CLI | mobile build/tests | partial | command exists but sandbox read-only cache blocked normal run. [VERIFIED: codebase grep] | escalated `flutter pub add --dry-run` worked for package verification. [VERIFIED: pub.dev dry-run] |
| Dart CLI | mobile build/tests | partial | command exists but Flutter cache write blocked normal run. [VERIFIED: codebase grep] | use approved Flutter command or repair SDK cache permissions. [ASSUMED] |
| PostgreSQL client | migrations/manual DB checks | yes | psql 16.13 [VERIFIED: codebase grep] | Docker Compose postgres for service runtime. [VERIFIED: codebase grep] |
| Docker | local LiveKit/Postgres/Redis | not confirmed | `docker --version` produced no output in probe. [VERIFIED: codebase grep] | install/start Docker or run services externally. [ASSUMED] |
| LiveKit server | video media | configured, not running-verified | Docker Compose image `livekit/livekit-server:latest`. [VERIFIED: codebase grep] | LiveKit Cloud or separate self-hosted server. [ASSUMED] |
| Firebase credentials | mobile push | not found | none [VERIFIED: codebase grep] | foreground Socket.io still works; background push no-ops until configured. [ASSUMED] |
| Context7 CLI | docs lookup | no | `ctx7 not found`. [VERIFIED: codebase grep] | official docs via web were used. [VERIFIED: docs.livekit.io] |
| slopcheck | package legitimacy | no | install attempt ended unavailable. [VERIFIED: codebase grep] | planner human-verifies all new packages before install. [ASSUMED] |

**Missing dependencies with no fallback:**
- Firebase/APNs credentials block real background mobile push delivery validation. [ASSUMED]
- A working Docker/LiveKit runtime blocks end-to-end local media tests if not available during execution. [ASSUMED]

**Missing dependencies with fallback:**
- Context7 missing; official docs and registry sources were used. [VERIFIED: docs.livekit.io]
- Flutter normal invocation is blocked by read-only SDK cache in sandbox; escalated commands can verify packages, but planner should include an environment repair/checkpoint before mobile test execution. [VERIFIED: codebase grep]

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Backend framework | Jest 29.7.0 with ts-jest 29.4.9. [VERIFIED: codebase grep] |
| Backend config file | `jest.config.ts`. [VERIFIED: codebase grep] |
| Backend quick run command | `npm test -- --runInBand src/__tests__/calls/call-lifecycle.test.ts` [ASSUMED] |
| Backend full suite command | `npm test` [VERIFIED: codebase grep] |
| Mobile framework | `flutter_test` with existing widget/service tests. [VERIFIED: codebase grep] |
| Mobile quick run command | `cd mobile && flutter test test/services/call_api_service_test.dart test/widgets/active_call_screen_test.dart` [ASSUMED] |
| Mobile full suite command | `cd mobile && flutter test` [VERIFIED: codebase grep] |

### Phase Requirements -> Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| COMM-05 | create, accept, reject, cancel, timeout, busy, and end call transitions | backend unit/integration | `npm test -- --runInBand src/__tests__/calls/call-lifecycle.test.ts` | no - Wave 0 |
| COMM-05 | LiveKit token only issued to accepted call participants | backend unit | `npm test -- --runInBand src/__tests__/calls/livekit-token.test.ts` | no - Wave 0 |
| COMM-05 | Flutter active call renders local/remote video placeholders and teardown states | widget | `cd mobile && flutter test test/widgets/active_call_screen_test.dart` | no - Wave 0 |
| COMM-05 | Sign draft -> Confirm / Confirm & Play overlay behavior in calls | widget/service | `cd mobile && flutter test test/widgets/call_translation_overlay_test.dart` | no - Wave 0 |
| WEB-02 | Web call page renders accepted LiveKit room and handles media device failure callback | React/unit | `npm test -- --runInBand src/__tests__/web/call-page.test.tsx` | no - Wave 0 |
| NOTIF-01 | Foreground Socket.io incoming-call event reaches all user sockets | backend unit | `npm test -- --runInBand src/__tests__/calls/call-signaling.test.ts` | no - Wave 0 |
| NOTIF-01 | FCM send helper formats VIDEO_CALL data payload and handles failed tokens | backend unit | `npm test -- --runInBand src/__tests__/notifications/call-push.test.ts` | no - Wave 0 |
| NOTIF-01 | Flutter notification open routes to incoming call screen | widget/service | `cd mobile && flutter test test/services/push_notification_service_test.dart` | no - Wave 0 |

### Sampling Rate

- **Per task commit:** Run the narrow backend or Flutter test for touched call module. [ASSUMED]
- **Per wave merge:** Run `npm test` and `cd mobile && flutter test` when Flutter environment is writable/approved. [VERIFIED: codebase grep]
- **Phase gate:** Full backend suite, full Flutter suite, local two-client call smoke test, and real-device push UAT for at least Android; iOS if credentials are available. [ASSUMED]

### Wave 0 Gaps

- [ ] `src/__tests__/calls/call-lifecycle.test.ts` - covers COMM-05 lifecycle races. [ASSUMED]
- [ ] `src/__tests__/calls/livekit-token.test.ts` - covers accepted participant token gating. [ASSUMED]
- [ ] `src/__tests__/calls/call-signaling.test.ts` - covers Socket.io user room emissions. [ASSUMED]
- [ ] `src/__tests__/notifications/call-push.test.ts` - covers FCM payload helper. [ASSUMED]
- [ ] `src/__tests__/web/call-page.test.tsx` - covers web call UI shell. [ASSUMED]
- [ ] `mobile/test/services/call_api_service_test.dart` - covers mobile API client. [ASSUMED]
- [ ] `mobile/test/services/push_notification_service_test.dart` - covers notification-open routing. [ASSUMED]
- [ ] `mobile/test/widgets/active_call_screen_test.dart` - covers active call UI states. [ASSUMED]
- [ ] `mobile/test/widgets/call_translation_overlay_test.dart` - covers subtitle/sign overlay behavior. [ASSUMED]

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | yes | Require existing JWT auth on every call endpoint; never trust `userId` from request body for caller identity. [VERIFIED: codebase grep] [ASSUMED] |
| V3 Session Management | yes | Respect existing multi-device sessions and emit lifecycle events to all sockets for the same user. [CITED: .planning/phases/01-foundation-authentication/01-CONTEXT.md] |
| V4 Access Control | yes | Authorize caller/callee only; reject token issuance for non-participants and terminal calls. [ASSUMED] |
| V5 Input Validation | yes | Use Zod schemas for call IDs, callee IDs, device tokens, and action payloads. [VERIFIED: codebase grep] |
| V6 Cryptography | yes | Use LiveKit signed JWTs through server SDK; do not expose API secret to clients. [CITED: docs.livekit.io/frontends/build/authentication/] |
| V7 Error Handling | yes | Return generic unavailable/failed states to clients while logging server detail. [ASSUMED] |
| V8 Data Protection | yes | Persist text transcript only by explicit action; do not record audio/video. [CITED: .planning/REQUIREMENTS.md] |
| V9 Communications | yes | Use HTTPS/WSS in production and trusted TLS for LiveKit. [CITED: docs.livekit.io/transport/self-hosting/deployment/] |

### Known Threat Patterns for Phase 04

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Unauthorized room join | Elevation of privilege | Issue LiveKit tokens only for authenticated participants in accepted calls; room-scoped `roomJoin` grant. [CITED: docs.livekit.io/reference/server-sdk-js/interfaces/VideoGrant.html] |
| Caller spoofing via Socket.io | Spoofing | Remove client-originating call lifecycle mutations; derive user from JWT-authenticated API. [VERIFIED: codebase grep] [ASSUMED] |
| Ring spam / harassment | Denial of service | Enforce one active/ringing call per user and rate-limit call creation. [ASSUMED] |
| Stale push opens ended call | Tampering / UX safety | Incoming screen must fetch current call state before showing Accept. [ASSUMED] |
| Media retention privacy breach | Information disclosure | Do not configure LiveKit egress/recording; save confirmed text only on explicit user action. [CITED: .planning/phases/04-video-calling/04-CONTEXT.md] |
| Token leakage | Information disclosure | Short token TTL and participant/room-specific grants; never persist LiveKit tokens in notification payloads. [ASSUMED] |
| Push payload PII leakage | Information disclosure | Keep push payload minimal: `type`, `callId`, caller display name if acceptable, expiration timestamp; no transcript/media. [ASSUMED] |

## Sources

### Primary (HIGH confidence)

- LiveKit Authentication docs - backend token generation requirement and frontend token flow: https://docs.livekit.io/frontends/build/authentication/
- LiveKit React `LiveKitRoom` docs - web room context, token/server URL props, media callbacks: https://docs.livekit.io/reference/components/react/component/livekitroom/
- LiveKit media publish docs - camera/microphone publish and platform permissions: https://docs.livekit.io/transport/media/publish/
- LiveKit Flutter quickstart - `livekit_client`, permissions, `Room.connect`, camera/microphone publishing: https://docs.livekit.io/transport/sdk-platforms/flutter/
- LiveKit self-hosting deployment docs - TLS, TURN, Redis, production config: https://docs.livekit.io/transport/self-hosting/deployment/
- LiveKit JS Server SDK AccessToken and VideoGrant reference: https://docs.livekit.io/reference/server-sdk-js/classes/AccessToken.html and https://docs.livekit.io/reference/server-sdk-js/interfaces/VideoGrant.html
- Socket.io rooms docs - server-side rooms and user room fanout: https://socket.io/docs/v4/rooms/
- Firebase Cloud Messaging Admin SDK send docs: https://firebase.google.com/docs/cloud-messaging/send/admin-sdk
- Firebase Cloud Messaging Flutter receive/open docs: https://firebase.google.com/docs/cloud-messaging/flutter/receive-messages
- Local files: `.planning/phases/04-video-calling/04-CONTEXT.md`, `.planning/phases/04-video-calling/04-UI-SPEC.md`, `.planning/REQUIREMENTS.md`, `.planning/STATE.md`, `.planning/ROADMAP.md`, `prisma/schema.prisma`, `src/app/lib/socket.ts`, `src/lib/livekit.ts`, `mobile/lib/screens/conversation_screen.dart`, `mobile/lib/services/sign_recognition_service.dart`, `mobile/lib/services/speech_transcription_service.dart`. [VERIFIED: codebase grep]

### Secondary (MEDIUM confidence)

- npm registry queries via `npm view` for `livekit-server-sdk`, `@livekit/components-react`, `livekit-client`, and `firebase-admin`. [VERIFIED: npm registry]
- Flutter package dry-runs for `livekit_client`, `firebase_core`, and `firebase_messaging`. [VERIFIED: pub.dev dry-run]
- npmjs.com and pub.dev package pages for downloads/source metadata. [CITED: npmjs.com] [CITED: pub.dev]

### Tertiary (LOW confidence)

- Assumed backend state-machine model and recommended table names; no official app-specific docs can verify this because it is product architecture. [ASSUMED]

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH for LiveKit/Socket.io/Firebase package choice from official docs; MEDIUM for package legitimacy because slopcheck was unavailable. [CITED: docs.livekit.io] [CITED: firebase.google.com] [ASSUMED]
- Architecture: HIGH for tier ownership and LiveKit token/media flow; MEDIUM for exact schema/event names because those are recommended conventions. [CITED: docs.livekit.io] [ASSUMED]
- Pitfalls: HIGH for current code gaps (`call:incoming`, token helper async risk, dev LiveKit config); MEDIUM for operational push/TURN risks until deployment credentials and real devices are available. [VERIFIED: codebase grep] [CITED: docs.livekit.io/transport/self-hosting/deployment/]

**Research date:** 2026-05-16  
**Valid until:** 2026-06-15 for architecture; re-check package versions and Firebase/LiveKit docs before install if planning starts after that date.
