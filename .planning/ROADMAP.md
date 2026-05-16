# Roadmap — VSL Bridge v1

## Source of Truth

- `.planning/REQUIREMENTS.md` owns the requirement catalog and v1/v1.x/v2 scope.
- `.planning/ROADMAP.md` owns the current milestone phase sequence.
- `.planning/STATE.md` owns current execution status.
- 3D avatar signing (`AVATAR-*`) is deferred to v2+ and is not part of the v1 workflow.
- Older research notes are background context only when they conflict with this roadmap.

---

## Phase Overview

| Phase | Name | Goal | Requirements | Status |
|-------|------|------|--------------|--------|
| 1 | Foundation & Authentication | Set up backend, auth, profiles, STT/TTS provider abstraction, and notification infrastructure | ACC-01 through ACC-04, COMM-02, COMM-03, PLAT-01 through PLAT-03 | Completed |
| 2 | Sign Recognition MVP | Deliver camera-to-text sign recognition pipeline with confidence feedback and TTS handoff | COMM-01, COMM-06, MOB-03 | Implemented, validation pending |
| 3 | Face-to-Face Conversation & History | Build one-device split-screen conversation mode and local text conversation history | COMM-04, HIST-01 through HIST-04 | Completed |
| 4 | Video Calling | Add 1:1 video calling with integrated subtitles, sign recognition output, and TTS output | COMM-05, WEB-02, NOTIF-01 | Not Started |
| 5 | SOS Emergency & Safety | Complete SOS flow with emergency contacts, GPS, SMS, and visual status notifications | EMERG-01, EMERG-02, MOB-04, MOB-05, NOTIF-02 | Not Started |
| 6 | App, Dictionary & Admin Readiness | Finish production app shells, dictionary viewer, web parity, and admin management features | MOB-01, MOB-02, WEB-01, WEB-03, WEB-04, DICT-01 through DICT-04, ADMIN-01 through ADMIN-05 | Not Started |

---

## Phase 1: Foundation & Authentication

**Goal:** Establish the technical foundation with authentication, user profiles, STT/TTS services, notification infrastructure, and cross-platform scaffolding.

**Requirements:** ACC-01, ACC-02, ACC-03, ACC-04, COMM-02, COMM-03, PLAT-01, PLAT-02, PLAT-03

**Status:** Completed

**Success Criteria:**
1. Users can register, log in, refresh sessions, and log out.
2. User profiles and emergency contacts can be stored and retrieved.
3. Vietnamese STT and TTS endpoints work through swappable providers.
4. Notification infrastructure exists for foreground and background delivery.
5. Web and mobile app foundations can call the backend consistently.

**Notes:**
- Historical implementation artifacts use `AUTH-*` IDs for auth work. In the current requirement catalog, those capabilities map to `ACC-*`.
- Phase 1 is verified in `.planning/phases/01-foundation-authentication/01-VERIFICATION.md`.

---

## Phase 2: Sign Recognition MVP

**Goal:** Deliver the real-time VSL recognition pipeline from camera landmarks to recognized Vietnamese text, with confidence feedback and TTS handoff.

**Requirements:** COMM-01, COMM-06, MOB-03

**Status:** Implemented, validation pending

**Success Criteria:**
1. Camera frames are converted into hand/body landmarks on mobile.
2. Landmarks stream to the recognition service over Socket.io.
3. Recognition results display as Vietnamese text with confidence feedback.
4. Phrase completion triggers TTS output for hearing users.
5. Front/rear camera toggle is available on mobile.
6. Real-device latency and real model accuracy are measured before marking the phase complete.

**Dependencies:** Phase 1

**Remaining Validation:**
- Replace or validate the mock LSTM with a real VSL model.
- Run physical Android/iOS device tests.
- Measure end-to-end latency on device.
- Confirm recognition quality against the target sign vocabulary.

---

## Phase 3: Face-to-Face Conversation & History

**Goal:** Build the one-device conversation experience for a deaf user and a hearing user, using split-screen UI, sign recognition output, speech subtitles, TTS output, and local text history.

**Requirements:** COMM-04, HIST-01, HIST-02, HIST-03, HIST-04

**Status:** Completed

**Success Criteria:**
1. Split-screen mode shows the camera/sign side and speech/text side clearly on mobile.
2. Recognized signs, spoken subtitles, and TTS responses appear in a single conversation timeline.
3. Conversation history is stored locally as text only.
4. Users can view past conversations with timestamps.
5. Users can search and share/copy conversation text.

**Dependencies:** Phase 1, Phase 2

**Out of Scope:**
- 3D avatar signing. Avatar work belongs to v2+.
- Remote video calling. That is Phase 4.

---

## Phase 4: Video Calling

**Goal:** Add 1:1 in-app video calls between registered users, with integrated translation surfaces but no v1 avatar dependency.

**Requirements:** COMM-05, WEB-02, NOTIF-01

**Status:** Not Started

**Plans:** 5 plans

Plans:
- [ ] 04-01-PLAN.md — Backend data layer: Prisma CallSession model, call state machine, async LiveKit token fix, test scaffolds
- [ ] 04-02-PLAN.md — Backend API endpoints: create/accept/reject/cancel/end/token routes, Socket.io signaling, FCM push helper
- [ ] 04-03-PLAN.md — Mobile Flutter: call screens (incoming/outgoing/active/result), call services, push notification routing
- [ ] 04-04-PLAN.md — Web call pages: entry page, dynamic call page, LiveKit room integration, incoming call modal, reusable components
- [ ] 04-05-PLAN.md — Translation surfaces: sign draft overlay, STT subtitles, in-call TTS, transcript save endpoint

**Success Criteria:**
1. Registered users can initiate, receive, accept, reject, and end 1:1 calls.
2. Both video feeds render reliably during a call.
3. Deaf user's signs can be shown as text and/or TTS output to the hearing user.
4. Hearing user's speech can be shown as subtitles to the deaf user.
5. Incoming call notifications work when the app is foregrounded and have a path for background delivery.
6. Call setup and teardown handle permission and network errors gracefully.

**Dependencies:** Phase 1, Phase 2

**Key Decisions Needed:**
- LiveKit vs direct WebRTC implementation.
- TURN server strategy for real-world NAT traversal.
- Scope of web support for the first v1 call release.

---

## Phase 5: SOS Emergency & Safety

**Goal:** Complete safety-critical SOS workflows with emergency contacts, GPS location, SMS sending, and accessible visual feedback.

**Requirements:** EMERG-01, EMERG-02, MOB-04, MOB-05, NOTIF-02

**Status:** Not Started

**Success Criteria:**
1. Deaf users can configure emergency contact phone numbers.
2. SOS flow requests and uses device GPS location.
3. SOS sends SMS with location to emergency contact(s).
4. SOS can trigger the local emergency call flow where platform rules allow.
5. The app provides clear visual/haptic confirmation and failure states.

**Dependencies:** Phase 1

**Key Decisions Needed:**
- SMS provider or native SMS strategy.
- Vietnam emergency dialing behavior by platform.
- Manual testing protocol for safety-critical behavior.

---

## Phase 6: App, Dictionary & Admin Readiness

**Goal:** Finish the v1 product surfaces that make the app usable across mobile and web: production app polish, dictionary viewer, web feature parity, and admin management.

**Requirements:** MOB-01, MOB-02, WEB-01, WEB-03, WEB-04, DICT-01, DICT-02, DICT-03, DICT-04, ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05

**Status:** Not Started

**Success Criteria:**
1. iOS and Android app shells meet production UI/accessibility expectations.
2. Web app provides responsive access to supported v1 features.
3. Dictionary can search, browse, and play VSL video entries.
4. Admin users can manage users, dictionary content, lesson content placeholders, SOS logs, and broadcasts.
5. Web/mobile account state is shared consistently.

**Dependencies:** Phase 1, Phase 2, Phase 5

**Out of Scope:**
- Full structured learning curriculum. Learning remains v1.x unless explicitly promoted.
- 3D avatar signing. Avatar remains v2+.

---

## Post-v1 Candidates

### v1.x

- LEARN-01 through LEARN-04: structured lessons, quiz scoring, progress tracking, parent dashboard.
- SOCIAL-01 through SOCIAL-03: contact/family linking beyond v1 essentials.
- COMM-07 through COMM-10: larger vocabularies and multi-participant calls.

### v2+

- AVATAR-01 through AVATAR-03: 3D avatar signing system, male/female avatar options, real-time animation synchronized with speech/text.
- ML-01 through ML-02: on-device inference and custom model training capabilities.
- ADV-01 through ADV-05: multi-language support, regional dialects, advanced analytics, parental controls, offline mode.

---

## Requirements Traceability

| Req ID | Description | Phase | Status |
|--------|-------------|-------|--------|
| ACC-01 | User registration with email/password and user type | 1 | Completed |
| ACC-02 | Login/logout with session persistence | 1 | Completed |
| ACC-03 | Profile management | 1 | Completed |
| ACC-04 | Emergency contact linking | 1 | Completed |
| COMM-01 | Real-time sign recognition | 2 | Validation Pending |
| COMM-02 | Vietnamese speech-to-text subtitles | 1 | Completed |
| COMM-03 | Vietnamese text-to-speech output | 1 | Completed |
| COMM-04 | Split-screen conversation mode | 3 | Completed |
| COMM-05 | 1:1 video calling | 4 | Pending |
| COMM-06 | AI-assisted sign feedback | 2 | Partial |
| HIST-01 | Store text conversation history locally | 3 | Completed |
| HIST-02 | View past conversations | 3 | Completed |
| HIST-03 | Search conversation history | 3 | Completed |
| HIST-04 | Share/export conversation text | 3 | Completed |
| WEB-02 | WebRTC support for video calling | 4 | Pending |
| NOTIF-01 | Incoming call visual/push notifications | 4 | Pending |
| EMERG-01 | SOS sends SMS with GPS | 5 | Pending |
| EMERG-02 | SOS triggers local emergency services flow | 5 | Pending |
| MOB-04 | Location services for SOS GPS | 5 | Pending |
| MOB-05 | SMS sending capability for SOS | 5 | Pending |
| NOTIF-02 | Visual SOS status notifications | 5 | Pending |
| MOB-01 | Production-quality iOS UI/UX | 6 | Pending |
| MOB-02 | Production-quality Android UI/UX | 6 | Pending |
| MOB-03 | Camera access and real-time overlay | 2 | Validation Pending |
| WEB-01 | Responsive web application | 6 | Pending |
| WEB-03 | Browser webcam access for recognition | 6 | Pending |
| WEB-04 | Shared web/mobile account system | 6 | Pending |
| DICT-01 | Searchable VSL dictionary | 6 | Pending |
| DICT-02 | Dictionary video playback | 6 | Pending |
| DICT-03 | Vietnamese text search | 6 | Pending |
| DICT-04 | Category/tag browsing | 6 | Pending |
| ADMIN-01 | Admin user management | 6 | Pending |
| ADMIN-02 | Admin dictionary content management | 6 | Pending |
| ADMIN-03 | Admin lesson content management | 6 | Pending |
| ADMIN-04 | SOS incident review/statistics | 6 | Pending |
| ADMIN-05 | Admin broadcast notifications | 6 | Pending |
| AVATAR-01 | 3D avatar signing system | v2+ | Deferred |
| AVATAR-02 | Male and female avatar options | v2+ | Deferred |
| AVATAR-03 | Real-time avatar animation | v2+ | Deferred |

---

*Last updated: 2026-05-16 — Phase 3 conversation and local history completed.*
