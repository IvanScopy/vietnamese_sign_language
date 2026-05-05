# Requirements — VSL Bridge

## Validated

(None yet — ship to validate)

## Active

### v1 Requirements (MVP + Video Calling + Web)

#### Communication Core

- [ ] **COMM-01**: Real-time sign language recognition for 100-200 VSL signs via camera input, displaying recognized text within 500ms
- [ ] **COMM-02**: Speech-to-text transcription of Vietnamese speech, displayed as subtitles within 1 second
- [ ] **COMM-03**: Text-to-speech output converting text to natural Vietnamese audio
- [ ] **COMM-04**: Split-screen conversation mode showing camera preview and conversation text/speech output
- [ ] **COMM-05**: Video calling between registered users (1:1) using WebRTC with audio/video
- [ ] **COMM-06**: AI-assisted sign feedback for practice exercises (camera-guided sign recognition with accuracy scoring)

#### Sign Dictionary

- [ ] **DICT-01**: Sign dictionary with searchable index of 4,000 VSL gesture videos (MP4, 1280x720)
- [ ] **DICT-02**: Video playback with standard controls (play/pause/seek)
- [ ] **DICT-03**: Search functionality by Vietnamese text (partial match, Vietnamese language support)
- [ ] **DICT-04**: Category/tag browsing (family, food, school, emotions, etc.)

#### User Accounts & Safety

- [ ] **ACC-01**: User registration with email/password (deaf or hearing user type selection)
- [ ] **ACC-02**: Login/logout with session persistence
- [ ] **ACC-03**: Profile management (name, age, user type)
- [ ] **ACC-04**: Emergency contacts linking (phone numbers for SOS)
- [ ] **EMERG-01**: SOS button sends SMS with GPS location to emergency contacts
- [ ] **EMERG-02**: SOS button also triggers local emergency services (dial 115 in Vietnam)

#### Conversation History

- [ ] **HIST-01**: Text-only conversation history stored locally on device
- [ ] **HIST-02**: View past conversations with timestamps
- [ ] **HIST-03**: Search within conversation history
- [ ] **HIST-04**: Share conversation via copy text or export

#### Notifications

- [ ] **NOTIF-01**: Visual push notifications for incoming video calls (customizable patterns/colors)
- [ ] **NOTIF-02**: Visual notification for new SOS status (for emergency contacts)

#### Mobile App

- [ ] **MOB-01**: iOS app with production-quality UI/UX following accessibility guidelines
- [ ] **MOB-02**: Android app with production-quality UI/UX
- [ ] **MOB-03**: Camera access with real-time processing and overlay
- [ ] **MOB-04**: Location services for SOS GPS
- [ ] **MOB-05**: SMS sending capability for SOS

#### Web App

- [ ] **WEB-01**: Responsive web application with feature parity to mobile app
- [ ] **WEB-02**: WebRTC support for video calling (Chrome/Firefox/Safari)
- [ ] **WEB-03**: Webcam access for sign recognition in browser
- [ ] **WEB-04**: Shared account system with mobile app

#### Admin Panel (Web Only)

- [ ] **ADMIN-01**: Admin user management (view users, activate/deactivate, view SOS logs)
- [ ] **ADMIN-02**: Dictionary content management (add/edit/delete sign entries, upload videos)
- [ ] **ADMIN-03**: Lesson content management (create lesson structures, associate signs)
- [ ] **ADMIN-04**: SOS incident review and statistics dashboard
- [ ] **ADMIN-05**: Send notifications to users (broadcast/selective)

### v1.x Requirements (Post-MVP)

#### Enhanced Learning

- [ ] **LEARN-01**: Structured bilingual lessons organized by topic (family, food, school, numbers, etc.)
- [ ] **LEARN-02**: Quiz system with automated scoring based on sign recognition
- [ ] **LEARN-03**: Progress tracking dashboard showing learned signs, quiz scores, lesson completion
- [ ] **LEARN-04**: Parent dashboard to view child's learning progress

#### Social Features

- [ ] **SOCIAL-01**: Contact linking between users (follow/connect)
- [ ] **SOCIAL-02**: Shared conversation history synced across devices
- [ ] **SOCIAL-03**: Family member management (add/remove contacts)

#### Enhanced Communication

- [ ] **COMM-07**: Expanded sign recognition to 1,000+ signs
- [ ] **COMM-08**: Improved accuracy with non-manual markers (facial expressions)
- [ ] **COMM-09**: Multi-participant video calling (3+ people)
- [ ] **COMM-10**: Conference calling with signing support

### v2+ Requirements (Future Consideration)

#### Advanced Features

- [ ] **AVATAR-01**: 3D avatar signing system (text → animated VSL gestures)
- [ ] **AVATAR-02**: Male and female avatar options
- [ ] **AVATAR-03**: Real-time avatar animation synchronized with speech/text
- [ ] **ML-01**: On-device ML inference option (privacy-preserving, offline partial functionality)
- [ ] **ML-02**: Custom model training capabilities for organizations
- [ ] **ADV-01**: Multi-language support (beyond Vietnamese)
- [ ] **ADV-02**: Regional VSL dialect variations
- [ ] **ADV-03**: Advanced analytics dashboard for administrators
- [ ] **ADV-04**: Parental controls and content filtering
- [ ] **ADV-05**: Offline mode with cached dictionary and limited recognition

## Out of Scope

### v1 Exclusions

- **Model Training** - Using pre-trained sign recognition models; custom training is out of scope
- **3D Avatar Signing** - Deferred to v2+ due to technical complexity
- **On-Device Only ML** - Will use server-side for quality initially; device option deferred
- **Multi-Language Translation** - Vietnamese only; no translation to other languages
- **Video/Audio Recording** - Conversations stored as text only; no media retention for privacy
- **Offline Mode** - Requires internet connectivity for AI services; no offline-first implementation
- **Social Network Features** - No feeds, groups, or public content; direct contacts only
- **Advanced Analytics** - Basic usage metrics only; no complex data visualization
- **Multiple Emergency Contacts Escalation** - Single contact per SOS; escalation chains deferred
- **Custom Model Training UI** - No user-facing model training; pre-trained model only
- **Video Recording of Learning Progress** - Quiz scores and text feedback only

---

*Last updated: 2026-05-05 after requirements definition*

## Traceability

This section populated by roadmap creation.

| Requirement ID | Phase | Status |
|----------------|-------|--------|
| COMM-01 | — | — |
| COMM-02 | — | — |
| COMM-03 | — | — |
| COMM-04 | — | — |
| COMM-05 | — | — |
| COMM-06 | — | — |
| DICT-01 | — | — |
| DICT-02 | — | — |
| DICT-03 | — | — |
| DICT-04 | — | — |
| ACC-01 | — | — |
| ACC-02 | — | — |
| ACC-03 | — | — |
| ACC-04 | — | — |
| EMERG-01 | — | — |
| EMERG-02 | — | — |
| HIST-01 | — | — |
| HIST-02 | — | — |
| HIST-03 | — | — |
| HIST-04 | — | — |
| NOTIF-01 | — | — |
| NOTIF-02 | — | — |
| MOB-01 | — | — |
| MOB-02 | — | — |
| MOB-03 | — | — |
| MOB-04 | — | — |
| MOB-05 | — | — |
| WEB-01 | — | — |
| WEB-02 | — | — |
| WEB-03 | — | — |
| WEB-04 | — | — |
| ADMIN-01 | — | — |
| ADMIN-02 | — | — |
| ADMIN-03 | — | — |
| ADMIN-04 | — | — |
| ADMIN-05 | — | — |
