# 🎯 Vietnamese Sign Language (VSL) Communication Platform

## What This Is

A **bidirectional communication platform** connecting deaf and hearing individuals using **Vietnamese Sign Language (VSL)**. The system supports real-time sign language recognition, speech synthesis, 3D avatar signing, and video calling capabilities across Web and Mobile platforms.

**Core Value:** Enable seamless, real-time communication between deaf and hearing Vietnamese speakers through AI-powered sign language translation and 3D avatar visualization.

---

## Users & Context

### Primary Users
- **Deaf/Hard-of-hearing individuals** who use VSL as their primary communication method
- **Hearing individuals** (doctors, teachers, family members, general public) who need to communicate with deaf users

### Context of Use
- **Healthcare:** Hospital/clinic visits, emergency situations
- **Education:** Classroom settings, learning environments
- **Daily life:** Home, public spaces, social interactions
- **Learning:** Teaching and practicing VSL

---

## Problem Statement

Deaf individuals in Vietnam face significant communication barriers with the hearing majority. Existing solutions are often:
- Expensive human interpreters in short supply
- Generic sign language apps that don't support VSL specifically
- Not designed for real-time, face-to-face conversations

This platform solves this by:
1. **Real-time VSL recognition** through device camera
2. **Instant text-to-speech** output for hearing users
3. **3D avatar signing** to visualize spoken language for deaf users
4. **In-app video calling** with integrated communication aids
5. **VSL learning tools** for education

---

## Key Requirements

### User Types & Authentication
- Users register as either `deaf` or `hearing`
- Basic email/password authentication
- Profile management
- Emergency contact linking (for deaf users' family notifications)

### Real-time Communication Modes
- **Face-to-Face Mode:** Single device, split-screen interface (like Google Translate conversation)
- **Video Call Mode:** Two-way video calling with real-time sign/speech translation

### Sign Language Recognition (VSL → Text → Speech)
- Camera-based real-time VSL gesture recognition
- Converts recognized signs to Vietnamese text
- Text-to-speech output for hearing users
- Supports facial expressions if training data includes them

### Speech Recognition + 3D Avatar (Speech → Text → Sign)
- Vietnamese speech-to-text recognition
- Real-time subtitle display
- 3D avatar (male/female models) performs corresponding VSL gestures
- Avatar detail level depends on training data quality

### Video Calling
- Peer-to-peer video calls within the app
- Real-time sign recognition during calls (deaf side)
- Real-time avatar + subtitles during calls (hearing side)
- Call notifications

### VSL Dictionary
- Search signs by Vietnamese text → view gesture video/animation
- Search by performing sign → app recognizes and shows meaning
- Categorized by themes (greetings, medical, education, family, emotions)
- Learning progress tracking

### VSL Learning System
- Themed lesson plans (greetings, numbers, medical terms, etc.)
- Practice quizzes and tests
- Camera-based practice with recognition feedback
- Progress tracking

### Emergency SOS
- Prominent SOS button
- Sends SMS to pre-configured emergency contacts
- Includes GPS location
- Optional emergency service contact

### Notifications
- Video call incoming notifications
- SOS alerts to emergency contacts
- Admin announcements
- Learning reminders
- Visual alerts for deaf users (vibration, flash)

### Admin Panel (Web Only)
- User management (view, suspend, delete accounts)
- Dictionary management (add/edit/delete signs)
- Lesson/content management
- Usage statistics and analytics
- SOS history review
- Broadcast notifications
- Multi-admin support with role-based permissions

---

## Out of Scope (v1)

- Multi-party group video calls (1-on-1 only)
- SMS/call integration with Vietnamese emergency services (may require partnership)
- Advanced facial expression recognition (only if data supports)
- Support for other sign languages (VSL only)
- Wearable device integration
- OAuth/social login (email/password only)
- Offline mode (requires internet for AI processing)
- Voice/video call with non-app users (app-to-app only)

---

## Constraints & Assumptions

### Technical Constraints
- Real-time AI processing requires stable internet connection
- 3D avatar quality depends on available training data and models
- Sign language accuracy depends on training dataset quality
- Mobile camera quality affects recognition performance

### Data Constraints
- Need VSL training dataset (still searching GitHub)
- Need 3D avatar models for signing animation
- Vietnamese speech-to-text model selection pending research

### Timeline Considerations
- AI model selection and integration is the key unknown
- 3D avatar animation pipeline may require custom development
- Video calling requires WebRTC expertise

---

## Success Metrics

### User Experience
- Deaf users can successfully initiate communication in under 30 seconds
- Hearing users understand avatar signs with >90% accuracy
- System response time <2 seconds for real-time modes

### Technical
- VSL recognition accuracy >85% on common signs
- Speech-to-text accuracy >90% for Vietnamese
- Video call connection time <5 seconds
- App stability: <1% crash rate

### Business
- 1,000+ active users within 3 months of launch
- Average session duration >10 minutes
- Learning feature engagement >60% of users

---

## Stakeholders

- **Deaf community** — Primary beneficiaries
- **Hearing family members** — Secondary users
- **Healthcare providers** — Use case validation
- **Educators** — Learning content contributors
- **VSL experts** — Training data and validation

---

## Open Questions

1. **VSL Dataset:** Which open-source VSL recognition model/dataset will be used? (Currently searching GitHub)
2. **3D Avatar:** Use pre-built models or custom development? What animation fidelity is achievable?
3. **Speech-to-Text:** Which Vietnamese STT service? (Azure, Google, local model?)
4. **Video Calling:** Self-hosted WebRTC or third-party service (Twilio, Agora)?
5. **Deployment:** Cloud provider selection? (AWS, GCP, Azure, VN-based?)
6. **Offline capability:** Any features should work offline?

---

## Key Decisions (Pending)

| Decision | Options | Status |
|----------|---------|--------|
| VSL Recognition Model | MediaPipe, custom CNN, existing VSL repo | Under research |
| STT Engine | Google Cloud, Azure, VOSK, local model | Under research |
| 3D Avatar Engine | Three.js, Babylon.js, Unity WebGL, Ready Player Me | Under research |
| Video Calling | WebRTC self-hosted, Agora, Twilio | Under research |
| Backend Framework | Node.js, Python/FastAPI, Go | Under research |
| Mobile Framework | React Native, Flutter, native | Under research |
| Database | PostgreSQL, Firebase, MongoDB | Under research |

---

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

---

*Last updated: 2026-05-05 after initialization*
