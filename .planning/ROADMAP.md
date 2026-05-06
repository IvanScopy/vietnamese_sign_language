# Roadmap — VSL Bridge

## Overview

This roadmap follows a dependency-driven approach, sequencing work from independent foundation features to the critical path (sign recognition), then building up to complete user workflows.

## Phase 1: Foundation & Authentication

**Duration**: 2 weeks  
**Focus**: Backend services, user accounts, and core STT/TTS infrastructure independent of sign recognition.

### Requirements in This Phase

| ID | Description |
|----|-------------|
| ACC-01 | User registration with email/password |
| ACC-02 | Login/logout with session persistence |
| ACC-03 | Profile management (name, age, user type) |
| NOTIF-01 | Visual push notifications for incoming video calls |
| NOTIF-02 | Visual notification for new SOS status |
| COMM-03 | Text-to-speech output converting text to natural Vietnamese audio |
| COMM-02 | Speech-to-text transcription of Vietnamese speech, displayed as subtitles within 1 second |

### Success Criteria

1. Users can successfully register, log in, and manage their profiles
2. Hearing user can speak Vietnamese and see text subtitles within 1 second
3. Text can be converted to Vietnamese speech output audible through device speakers
4. Push notification infrastructure is operational and can target specific users

### Plans

**Wave 1: Infrastructure**
- [ ] 01-01-INFRASTRUCTURE.md — Docker Compose, PostgreSQL, Redis, LiveKit, ML fallbacks

**Wave 2: Authentication**
- [ ] 01-02A-AUTH-INFRASTRUCTURE.md — Prisma schema, token service, JWT middleware, Redis blacklist
- [ ] 01-02B-AUTH-APPLICATION.md — Auth service, OAuth routes, profile management (includes OAuth per D-XX)

**Wave 3: STT/TTS & Notifications**
- [ ] 01-03-STT-TTS.md — Strategy pattern with Groq/Whisper.cpp and ElevenLabs/Coqui
- [ ] 01-04-NOTIFICATIONS.md — Socket.io + FCM/APNs hybrid, SOS priority

**Wave 5: Server & Integration**
- [ ] 01-05A-SERVER-BOOTSTRAP.md — Express server, health checks, error handling, OpenAPI
- [ ] 01-05B-TESTING-AND-MIDDLEWARE.md — Rate limiting, logging, Jest config, integration tests, package.json

---

## Phase 2: Core Sign Recognition

**Duration**: 3 weeks  
**Focus**: The critical path - sign recognition pipeline with feedback mechanism. Highest risk, highest priority.

### Requirements in This Phase

| ID | Description |
|----|-------------|
| COMM-01 | Real-time sign language recognition for 100-200 VSL signs via camera input, displaying recognized text within 500ms |
| COMM-06 | AI-assisted sign feedback for practice exercises (camera-guided sign recognition with accuracy scoring) |

### Success Criteria

1. Users can successfully recognize 100+ VSL signs with >80% accuracy in controlled conditions
2. Sign recognition response time is consistently under 500ms from gesture completion to text display
3. Deaf child can practice a sign through camera and receive accuracy feedback within 5 seconds
4. Recognition system gracefully handles poor lighting, angles, and partial occlusion

---

## Phase 3: Communication & Emergency Features

**Duration**: 2 weeks  
**Focus**: Build on sign recognition to enable real-time conversation and safety features.

### Requirements in This Phase

| ID | Description |
|----|-------------|
| COMM-04 | Split-screen conversation mode showing camera preview and conversation text/speech output |
| ACC-04 | Emergency contacts linking (phone numbers for SOS) |
| EMERG-01 | SOS button sends SMS with GPS location to emergency contacts |
| EMERG-02 | SOS button also triggers local emergency services (dial 115 in Vietnam) |
| HIST-01 | Text-only conversation history stored locally on device |
| HIST-02 | View past conversations with timestamps |
| HIST-03 | Search within conversation history |
| HIST-04 | Share conversation via copy text or export |
| MOB-04 | Location services for SOS GPS |
| MOB-05 | SMS sending capability for SOS |

### Success Criteria

1. Deaf child and hearing parent can have a face-to-face conversation using split-screen mode, with signs converting to speech and speech converting to text
2. SOS button sends location-based SMS to emergency contacts within 10 seconds of activation
3. Emergency call to local services (115) initiates automatically after SOS activation
4. Conversation history persists across app restarts and supports text search
5. Users can export and share conversation logs

---

## Phase 4: Video Calling Infrastructure

**Duration**: 3 weeks  
**Focus**: WebRTC implementation for 1:1 video calls between registered users.

### Requirements in This Phase

| ID | Description |
|----|-------------|
| COMM-05 | Video calling between registered users (1:1) using WebRTC with audio/video |
| WEB-02 | WebRTC support for video calling (Chrome/Firefox/Safari) |

### Success Criteria

1. Registered users can initiate and receive video calls with stable audio/video connection
2. Video calls support at least 5 minutes of continuous conversation without disconnection
3. Sign recognition works during video calls (recognizer processes remote participant's signs)
4. WebRTC implementation works across Chrome, Firefox, and Safari browsers
5. Connection quality adapts to network conditions (bandwidth throttling)

---

## Phase 5: Cross-Platform Polish

**Duration**: 3 weeks  
**Focus**: Mobile app polish, web application feature parity, and admin panel.

### Requirements in This Phase

| ID | Description |
|----|-------------|
| MOB-01 | iOS app with production-quality UI/UX following accessibility guidelines |
| MOB-02 | Android app with production-quality UI/UX |
| MOB-03 | Camera access with real-time processing and overlay |
| WEB-01 | Responsive web application with feature parity to mobile app |
| WEB-03 | Webcam access for sign recognition in browser |
| WEB-04 | Shared account system with mobile app |
| ADMIN-01 | Admin user management (view users, activate/deactivate, view SOS logs) |
| ADMIN-02 | Dictionary content management (add/edit/delete sign entries, upload videos) |
| ADMIN-03 | Lesson content management (create lesson structures, associate signs) |
| ADMIN-04 | SOS incident review and statistics dashboard |
| ADMIN-05 | Send notifications to users (broadcast/selective) |

### Success Criteria

1. iOS and Android apps are production-ready with polished UI, smooth animations, and accessibility compliance
2. Web application provides same core functionality as mobile apps (conversation mode, sign recognition, video calling)
3. Users can access their accounts seamlessly across mobile and web platforms
4. Admin panel allows complete user, content, and SOS management workflows
5. Sign recognition works reliably on both mobile camera and webcam inputs

---

## Phase 6: Learning System

**Duration**: 2 weeks  
**Focus**: Educational features including dictionary and structured lessons.

### Requirements in This Phase

| ID | Description |
|----|-------------|
| DICT-01 | Sign dictionary with searchable index of 4,000 VSL gesture videos |
| DICT-02 | Video playback with standard controls |
| DICT-03 | Search functionality by Vietnamese text |
| DICT-04 | Category/tag browsing |
| LEARN-01 | Structured bilingual lessons organized by topic |
| LEARN-02 | Quiz system with automated scoring based on sign recognition |
| LEARN-03 | Progress tracking dashboard showing learned signs, quiz scores, lesson completion |
| LEARN-04 | Parent dashboard to view child's learning progress |

### Success Criteria

1. All 4,000 VSL gesture videos are accessible with smooth playback and searchable by Vietnamese text
2. Users can browse signs by category (family, food, school, emotions, etc.)
3. Learning lessons with at least 5 topics are available, each with structured progression
4. Quiz system uses camera-based sign recognition to provide scores within 3 seconds of completion
5. Progress tracking shows learned signs count, quiz history, and lesson completion status
6. Parents can view their child's learning dashboard with detailed progress metrics

---

## Phase Boundaries & Dependencies

```
Phase 1: Foundation (Independent)
    ├── Authentication & Profiles
    ├── STT/TTS Infrastructure
    └── Notification System

Phase 2: Core Recognition (Critical Path)
    └── Depends on: Phase 1
    └── Delivers: Sign recognition capability
    
Phase 3: Communication & Safety
    └── Depends on: Phase 1, Phase 2
    └── Delivers: Conversation workflows, SOS

Phase 4: Video Calling
    └── Depends on: Phase 1, Phase 3
    └── Delivers: Real-time video communication

Phase 5: Cross-Platform Polish
    └── Depends on: Phase 1, Phase 2, Phase 3
    └── Delivers: Production mobile + web + admin

Phase 6: Learning System
    └── Depends on: Phase 2 (for recognition-based quizzes)
    └── Delivers: Educational content and progress tracking
```

---

## Out-of-Scope for v1

As documented in REQUIREMENTS.md, the following are explicitly out of scope for v1:
- 3D avatar signing system (AVATAR-01 through AVATAR-03)
- On-device ML inference (ML-01)
- Custom model training UI (ML-02)
- Multi-language support (ADV-01)
- Regional VSL dialects (ADV-02)
- Offline mode (ADV-05)
- Multi-participant video calling (COMM-09, COMM-10)
- Expanded sign recognition beyond 200 signs (COMM-07, COMM-08)

These will be considered for v2+ after validating core functionality with real users.

---

*Last updated: 2026-05-06*
