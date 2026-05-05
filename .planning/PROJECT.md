# Vietnamese Sign Language (VSL) Bridge

## What This Is

A bilingual communication and learning application that enables real-time two-way communication between deaf and hearing people using Vietnamese Sign Language (VSL). The app uses AI to recognize sign language gestures and convert them to speech/text, and converts speech to text with a 3D avatar signing the response. The platform serves deaf children, their parents, and hearing peers, with a focus on educational accessibility and emotional connection.

## Core Value

Enable deaf children and hearing people (parents, peers) to communicate and learn VSL together, bridging the communication gap through technology.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] **COMM-01**: Real-time sign language recognition (camera input → text + speech output)
- [ ] **COMM-02**: Speech recognition and text display (speech → text subtitles)
- [ ] **COMM-03**: 3D avatar signing system (text → animated VSL gestures)
- [ ] **COMM-04**: Video calling with integrated communication features
- [ ] **COMM-05**: Split-screen real-time conversation mode (face-to-face)
- [ ] **DICT-01**: Sign language dictionary with 4,000 VSL gesture videos
- [ ] **LEARN-01**: Learning system with lessons organized by topic
- [ ] **LEARN-02**: Quizzes and practice exercises with camera feedback
- [ ] **LEARN-03**: Progress tracking for learned signs
- [ ] **EMERG-01**: SOS emergency functionality with GPS location
- [ ] **EMERG-02**: SMS notifications to emergency contacts
- [ ] **ACC-01**: User account management and profiles
- [ ] **ACC-02**: Link emergency contacts to account
- [ ] **HIST-01**: Conversation history stored as text
- [ ] **HIST-02**: Search and review past conversations
- [ ] **HIST-03**: Share conversations with others
- [ ] **NOTIF-01**: Push notifications for video calls and messages
- [ ] **NOTIF-02**: Visual notification options for deaf users
- [ ] **MOB-01**: Mobile app (iOS/Android) - polished production quality
- [ ] **WEB-01**: Web app - polished production quality
- [ ] **ADMIN-01**: Admin panel for user management
- [ ] **ADMIN-02**: Admin panel for dictionary/content management
- [ ] **ADMIN-03**: Admin panel for lesson management
- [ ] **ADMIN-04**: Admin panel for SOS logs and statistics

### Out of Scope

- **Model Training** - Will use pre-trained sign recognition models; training custom models is out of scope for v1
- **Multiple Sign Dialects** - Standard VSL only; regional variations are out of scope
- **Advanced Social Features** - No social network, groups, or public feeds beyond basic contact linking
- **Multi-language Translation** - Vietnamese only; translation to other languages is out of scope
- **Video Recording** - Conversations stored as text only; video/audio recording is out of scope
- **Offline Mode** - Requires internet connectivity for AI services; offline functionality is out of scope

## Context

**Target Users:**
- Deaf children (primary) - need intuitive, engaging interface
- Parents of deaf children - want to communicate and learn with their children
- Hearing peers - classmates and friends who want to include deaf children

**Use Cases:**
- Face-to-face communication in daily life (home, school, public places)
- Educational settings - learning VSL in structured way
- Video calls between users
- Emergency situations - quick SOS activation
- Dictionary lookup for unfamiliar signs

**Technical Assets:**
- 4,000 labeled VSL gesture videos (MP4, 1280x720) - for learning/dictionary features
- Each video represents a single gesture with detailed annotations

**Platform Strategy:**
- Mobile is primary (camera access, portability) but both mobile and web must be production-ready in v1
- Considering VPS for backend infrastructure
- Preference for open-source solutions (STT, TTS, etc.)

**Key Dependencies & Uncertainties:**
- **VSL Recognition Model** - Critical path dependency; actively searching for suitable pre-trained model
  - Target architecture: LSTM with MediaPipe landmarks
  - Concern: Pre-trained models may have limited coverage of VSL
  - Latency requirement: Comparable to texting (sub-second response)
- **3D Avatar System** - Important but potentially cuttable if technical challenges prove too difficult
- **Inference Location** - Undecided: device-side vs server-side (smartphone capability for LSTM+MediaPipe unknown)

**Known Challenges:**
- Sign language recognition accuracy is typically lower than speech recognition due to dataset limitations
- 3D avatar signing animation quality directly impacts usability
- Balancing real-time performance with model complexity
- Ensuring the learning system is engaging for children

## Constraints

- **Mobile Performance**: Sign recognition must be responsive enough for natural conversation flow (ideally <1 second)
- **Platform Parity**: Both mobile and web must feel polished and professional in v1
- **Data Usage**: Only text history stored; no video/audio retention for privacy
- **Open Source**: Preference for open-source components where feasible (STT, TTS, potentially recognition)
- **VSL Specificity**: Must use Vietnamese Sign Language, not generic sign language models

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Mobile-first with web secondary | Camera access and portability essential for real-world use | — Pending |
| Use pre-trained recognition model | Model training is too complex for v1 timeline | — Pending |
| 3D avatar included if feasible | Significant user experience impact; may be cut if technically prohibitive | — Pending |
| Open-source stack preferred | Cost control and community support | — Pending |

---

*Last updated: 2026-05-05 after initialization*

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state
