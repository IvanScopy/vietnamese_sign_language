# Roadmap — VSL Communication Platform

## Phase Overview

| Phase | Name | Goal | Requirements | Success Criteria |
|-------|------|------|--------------|------------------|
| 1 | Foundation & Infrastructure | Set up project scaffolding, authentication, and core architecture | AUTH-01 through AUTH-05, PLAT-01 through PLAT-05 | Users can register, log in, and access the app on web and mobile |
| 2 | Sign Language Recognition | Integrate VSL recognition with camera input and text-to-speech output | SIGN-01 through SIGN-05, SPEECH-01 through SPEECH-04 | Deaf users can sign → system outputs Vietnamese speech that hearing users understand |
| 3 | 3D Avatar & Speech Integration | Build 3D avatar system that animates signs from speech input | AVATAR-01 through AVATAR-05, SPEECH-02 through SPEECH-04 | Hearing users can speak → deaf users see animated avatar signing the content |
| 4 | Real-time Communication Modes | Implement face-to-face split mode and video calling | F2F-01 through F2F-06, CALL-01 through CALL-06 | Users can have real-time conversations both in-person and remotely |
| 5 | Learning & Dictionary System | Enable VSL learning and dictionary lookup features | DICT-01 through DICT-05, LEARN-01 through LEARN-06 | Users can learn VSL signs and look up sign meanings |
| 6 | Emergency & Notifications | Add SOS emergency feature and notification system | SOS-01 through SOS-06, NOTIF-01 through NOTIF-05 | Users can trigger emergency alerts and receive call/learning notifications |
| 7 | Admin Panel & Analytics | Build web-based admin dashboard for management | ADMIN-01 through ADMIN-09 | Admins can manage users, content, and view system statistics |
| 8 | Polish & Production Readiness | Refine UX, optimize performance, and prepare for launch | All requirements | App is stable, performant, and ready for production deployment |

---

## Phase 1: Foundation & Infrastructure

**Goal:** Establish the technical foundation with authentication, database, and cross-platform setup.

**Requirements:** AUTH-01, AUTH-02, AUTH-03, AUTH-04, AUTH-05, PLAT-01, PLAT-02, PLAT-03, PLAT-04, PLAT-05

**Success Criteria:**
1. Users can register and log in on both web and mobile
2. User profiles can be created and edited
3. Emergency contacts can be added to deaf user profiles
4. Basic navigation and routing works on all platforms
5. Camera permissions work on web and mobile
6. Network error handling provides clear user feedback

**Dependencies:** None — this is the foundation

**Tech Decisions Needed:**
- Backend framework (Node.js/FastAPI/Go) with user management
- Database choice (PostgreSQL/Firebase/MongoDB)
- Mobile framework (React Native/Flutter)
- State management and API client architecture

---

## Phase 2: Sign Language Recognition

**Goal:** Integrate VSL recognition with camera input and output Vietnamese speech.

**Requirements:** SIGN-01, SIGN-02, SIGN-03, SIGN-04, SIGN-05, SPEECH-01, SPEECH-02, SPEECH-03, SPEECH-04

**Success Criteria:**
1. System captures video from device camera in real-time
2. VSL gestures are recognized and converted to Vietnamese text
3. Recognized text is displayed on screen
4. Text is spoken aloud using Vietnamese TTS
5. Recognition accuracy >70% on common signs (baseline)
6. System provides visual feedback during recognition processing

**Dependencies:** Phase 1 (authentication, camera infrastructure)

**Key Research Areas:**
- VSL recognition model selection (MediaPipe, custom CNN, existing GitHub repo)
- Vietnamese TTS service (Azure, Google, local)
- Real-time video processing pipeline optimization

---

## Phase 3: 3D Avatar & Speech Integration

**Goal:** Build 3D avatar system that converts speech input into signing animations.

**Requirements:** AVATAR-01, AVATAR-02, AVATAR-03, AVATAR-04, AVATAR-05, SPEECH-02, SPEECH-03, SPEECH-04

**Success Criteria:**
1. 3D avatar displays correctly on web and mobile
2. Avatar animates Vietnamese text as VSL gestures
3. Male and female avatar models are available
4. Avatar animations are smooth (>15 FPS) and intelligible
5. Avatar response time <2 seconds from speech to animation
6. Deaf users can understand avatar signs with >60% accuracy in testing

**Dependencies:** Phase 2 (speech recognition)

**Key Research Areas:**
- 3D rendering engine (Three.js, Babylon.js)
- VSL-to-animation mapping system
- Avatar model sources (Ready Player Me, custom)
- Animation pipeline from text to gestures

---

## Phase 4: Real-time Communication Modes

**Goal:** Implement face-to-face split-screen mode and video calling with integrated translation.

**Requirements:** F2F-01, F2F-02, F2F-03, F2F-04, F2F-05, F2F-06, CALL-01, CALL-02, CALL-03, CALL-04, CALL-05, CALL-06

**Success Criteria:**
1. Split-screen UI works correctly on phone and tablet (180° rotation support)
2. Video calls connect reliably between two app users
3. During face-to-face mode: deaf user's signs → hearing user hears speech
4. During face-to-face mode: hearing user's speech → deaf user sees avatar + subtitles
5. During video call: both translation directions work seamlessly
6. Call connection time <5 seconds
7. Call quality: video >15 FPS, audio clear, translation latency <2s

**Dependencies:** Phase 2 (sign recognition), Phase 3 (avatar), Phase 1 (users)

**Key Research Areas:**
- WebRTC implementation (self-hosted or service like Agora/Twilio)
- Real-time synchronization of translation during calls
- Call state management and signaling server

---

## Phase 5: Learning & Dictionary System

**Goal:** Enable VSL learning through lessons, practice, and dictionary lookup.

**Requirements:** DICT-01, DICT-02, DICT-03, DICT-04, DICT-05, LEARN-01, LEARN-02, LEARN-03, LEARN-04, LEARN-05, LEARN-06

**Success Criteria:**
1. Dictionary contains at least 500 common VSL signs
2. Users can search dictionary by text or camera
3. Lessons cover at least 10 themed categories (greetings, numbers, medical, etc.)
4. Practice mode provides accurate feedback on user's signing
5. Quiz system tracks scores and progress
6. Users can see their learning progress dashboard

**Dependencies:** Phase 2 (sign recognition for practice mode)

**Content Needs:**
- VSL dictionary data (signs, meanings, demonstration videos/animations)
- Lesson content creators (VSL experts)
- Quiz and assessment design

---

## Phase 6: Emergency & Notifications

**Goal:** Add SOS emergency feature and comprehensive notification system.

**Requirements:** SOS-01, SOS-02, SOS-03, SOS-04, SOS-05, SOS-06, NOTIF-01, NOTIF-02, NOTIF-03, NOTIF-04, NOTIF-05

**Success Criteria:**
1. SOS button is clearly visible on all main screens
2. SOS sends SMS with GPS location within 10 seconds
3. Emergency contacts receive the alert
4. Users receive push notifications for incoming calls
5. Deaf users get visual notifications (vibration/flash)
6. Admin broadcast notifications reach all users

**Dependencies:** Phase 1 (user emergency contacts), PLAT-05 (network handling)

**Key Decisions:**
- Push notification service (Firebase Cloud Messaging, APNs)
- SMS gateway for Vietnam (local provider needed)
- GPS accuracy requirements

---

## Phase 7: Admin Panel & Analytics

**Goal:** Build comprehensive admin dashboard for user and content management.

**Requirements:** ADMIN-01, ADMIN-02, ADMIN-03, ADMIN-04, ADMIN-05, ADMIN-06, ADMIN-07, ADMIN-08, ADMIN-09

**Success Criteria:**
1. Admin can view all users with filtering and search
2. Admin can suspend/delete user accounts
3. Admin can manage dictionary entries (CRUD operations)
4. Admin can create and edit lessons/quizzes
5. Dashboard shows key metrics: daily active users, feature usage, sign popularity
6. SOS history is accessible with location and timestamp data
7. Admin can send notifications to all or targeted user groups
8. Role-based permissions work correctly (Super Admin, Admin, Moderator)

**Dependencies:** All previous phases (need data to display)

**Platform:** Web only (desktop/laptop browsers)

---

## Phase 8: Polish & Production Readiness

**Goal:** Refine user experience, optimize performance, and prepare for production launch.

**Requirements:** All v1 requirements (comprehensive validation)

**Success Criteria:**
1. App is stable: <1% crash rate, graceful error handling
2. Performance: recognition latency <1.5s, avatar animations smooth
3. UX improvements based on user testing feedback
4. Accessibility features meet WCAG 2.1 AA standards
5. Security audit completed (user data, API security)
6. Documentation complete (user guides, admin manual, deployment guide)
7. Monitoring and logging infrastructure in place
8. Beta testing with 50+ deaf and hearing users completed

**Activities:**
- User acceptance testing (UAT) with target audience
- Performance optimization and profiling
- Bug fixing and edge case handling
- UI/UX refinements based on feedback
- Security hardening
- Load testing and scalability preparation
- Deployment pipeline setup

---

## Requirements Traceability

| Req ID | Description | Phase | Status |
|--------|-------------|-------|--------|
| AUTH-01 | Register with email/password/user type | 1 | Pending |
| AUTH-02 | Login with session persistence | 1 | Pending |
| AUTH-03 | Logout functionality | 1 | Pending |
| AUTH-04 | Emergency contact linking | 1 | Pending |
| AUTH-05 | Profile view/edit | 1 | Pending |
| SIGN-01 | Real-time VSL recognition via camera | 2 | Pending |
| SIGN-02 | Convert signs to Vietnamese text | 2 | Pending |
| SIGN-03 | TTS output for hearing users | 2 | Pending |
| SIGN-04 | Visual recognition feedback | 2 | Pending |
| SIGN-05 | Front/rear camera support | 2 | Pending |
| SPEECH-01 | Vietnamese speech-to-text | 2 | Pending |
| SPEECH-02 | Display speech as subtitles | 2 | Pending |
| SPEECH-03 | Clear, readable subtitles <2s delay | 2 | Pending |
| SPEECH-04 | Continuous speech handling | 2 | Pending |
| AVATAR-01 | 3D avatar (male/female) | 3 | Pending |
| AVATAR-02 | Avatar animates text as signs | 3 | Pending |
| AVATAR-03 | Hand/arm/body movements for VSL | 3 | Pending |
| AVATAR-04 | Smooth, intelligible animations | 3 | Pending |
| AVATAR-05 | Toggle male/female models | 3 | Pending |
| F2F-01 | Split-screen UI for two users | 4 | Pending |
| F2F-02 | Deaf side: camera + hearing avatar/subtitles | 4 | Pending |
| F2F-03 | Hearing side: mic + deaf text/speech | 4 | Pending |
| F2F-04 | Screen rotation for natural reading | 4 | Pending |
| F2F-05 | Active mode indicators | 4 | Pending |
| F2F-06 | Toggle between sign/speech modes | 4 | Pending |
| CALL-01 | Initiate/receive 1-on-1 video calls | 4 | Pending |
| CALL-02 | Display both video feeds | 4 | Pending |
| CALL-03 | Deaf user's signs → hearing's speech during call | 4 | Pending |
| CALL-04 | Hearing's speech → deaf's avatar/subtitles during call | 4 | Pending |
| CALL-05 | Incoming call notifications (background) | 4 | Pending |
| CALL-06 | Accept/reject/end calls | 4 | Pending |
| DICT-01 | Search text → sign demonstration | 5 | Pending |
| DICT-02 | Perform sign → find meaning | 5 | Pending |
| DICT-03 | Categorized dictionary | 5 | Pending |
| DICT-04 | Clear demonstrations with descriptions | 5 | Pending |
| DICT-05 | Mark signs as learning/mastered | 5 | Pending |
| LEARN-01 | Themed lessons with progression | 5 | Pending |
| LEARN-02 | Video demonstrations in lessons | 5 | Pending |
| LEARN-03 | Camera practice with feedback | 5 | Pending |
| LEARN-04 | Quizzes and tests | 5 | Pending |
| LEARN-05 | Progress tracking dashboard | 5 | Pending |
| LEARN-06 | Structured lesson order | 5 | Pending |
| SOS-01 | Prominent SOS button | 6 | Pending |
| SOS-02 | SMS to emergency contacts | 6 | Pending |
| SOS-03 | Include GPS location in SOS | 6 | Pending |
| SOS-04 | SOS message content | 6 | Pending |
| SOS-05 | Visual SOS confirmation | 6 | Pending |
| SOS-06 | Confirmation to prevent accidental trigger | 6 | Pending |
| NOTIF-01 | Incoming call push notifications | 6 | Pending |
| NOTIF-02 | Visual notifications for deaf users | 6 | Pending |
| NOTIF-03 | Admin broadcast notifications | 6 | Pending |
| NOTIF-04 | Learning reminder notifications | 6 | Pending |
| NOTIF-05 | SOS notifications to contacts | 6 | Pending |
| HISTORY-01 | Save conversations as text | 6 | Pending |
| HISTORY-02 | View past conversations by date | 6 | Pending |
| HISTORY-03 | Search in conversation history | 6 | Pending |
| HISTORY-04 | Share conversation text | 6 | Pending |
| HISTORY-05 | Delete conversation history | 6 | Pending |
| ADMIN-01 | View all users list | 7 | Pending |
| ADMIN-02 | Suspend/delete user accounts | 7 | Pending |
| ADMIN-03 | Manage dictionary entries | 7 | Pending |
| ADMIN-04 | Create/edit/delete lessons and quizzes | 7 | Pending |
| ADMIN-05 | View usage statistics | 7 | Pending |
| ADMIN-06 | View SOS incident history | 7 | Pending |
| ADMIN-07 | Send notifications to users | 7 | Pending |
| ADMIN-08 | Multi-admin support with roles | 7 | Pending |
| ADMIN-09 | Super Admin manages admin permissions | 7 | Pending |
| PLAT-01 | Web browser support (Chrome, Firefox, Safari, Edge) | 8 | Pending |
| PLAT-02 | iOS and Android mobile apps | 8 | Pending |
| PLAT-03 | Feature parity between web and mobile | 8 | Pending |
| PLAT-04 | Camera works on all platforms | 8 | Pending |
| PLAT-05 | Network error handling with user feedback | 8 | Pending |

---

## State File

```
{
  "current_phase": null,
  "phase_progress": {
    "1": { "started": null, "completed": null },
    "2": { "started": null, "completed": null },
    "3": { "started": null, "completed": null },
    "4": { "started": null, "completed": null },
    "5": { "started": null, "completed": null },
    "6": { "started": null, "completed": null },
    "7": { "started": null, "completed": null },
    "8": { "started": null, "completed": null }
  },
  "requirements_traceability": {},
  "notes": ""
}
```

---

*Last updated: 2026-05-05 after initialization*
