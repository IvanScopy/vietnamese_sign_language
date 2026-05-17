# Requirements — VSL Bridge

## Validated

(None yet — ship to validate)

## Active

### v1 Requirements (MVP + Video Calling + Web)

#### Communication Core

- [ ] **COMM-01**: Real-time sign language recognition for 100-200 VSL signs via camera input, displaying recognized text within 500ms
- [x] **COMM-02**: Speech-to-text transcription of Vietnamese speech, displayed as subtitles within 1 second
- [x] **COMM-03**: Text-to-speech output converting text to natural Vietnamese audio
- [x] **COMM-04**: Split-screen conversation mode showing camera preview and conversation text/speech output
- [ ] **COMM-05**: Video calling between registered users (1:1) using WebRTC with audio/video
- [ ] **COMM-06**: AI-assisted sign feedback for practice exercises (camera-guided sign recognition with accuracy scoring)

#### Sign Dictionary

- [ ] **DICT-01**: Sign dictionary with searchable index of 4,000 VSL gesture videos (MP4, 1280x720)
- [ ] **DICT-02**: Video playback with standard controls (play/pause/seek)
- [ ] **DICT-03**: Search functionality by Vietnamese text (partial match, Vietnamese language support)
- [ ] **DICT-04**: Category/tag browsing (family, food, school, emotions, etc.)

#### User Accounts & Safety

- [x] **ACC-01**: User registration with email/password (deaf or hearing user type selection)
- [x] **ACC-02**: Login/logout with session persistence
- [x] **ACC-03**: Profile management (name, age, user type)
- [x] **ACC-04**: Emergency contacts linking (phone numbers for SOS)
- [ ] **EMERG-01**: SOS button sends SMS with GPS location to emergency contacts
- [ ] **EMERG-02**: SOS button also triggers local emergency services (dial 115 in Vietnam)

#### Conversation History

- [x] **HIST-01**: Text-only conversation history stored locally on device
- [x] **HIST-02**: View past conversations with timestamps
- [x] **HIST-03**: Search within conversation history
- [x] **HIST-04**: Share conversation via copy text or export

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

This section is aligned to `.planning/ROADMAP.md`. Avatar requirements remain v2+ and are intentionally not assigned to a v1 phase.

| Requirement ID | Phase | Status |
|----------------|-------|--------|
| COMM-01 | 02 | Validation Pending |
| COMM-02 | 01 | Completed |
| COMM-03 | 01 | Completed |
| COMM-04 | 03 | Completed |
| COMM-05 | 04 | Pending |
| COMM-06 | 02 | Partial |
| DICT-01 | 06 | Pending |
| DICT-02 | 06 | Pending |
| DICT-03 | 06 | Pending |
| DICT-04 | 06 | Pending |
| ACC-01 | 01 | Completed |
| ACC-02 | 01 | Completed |
| ACC-03 | 01 | Completed |
| ACC-04 | 01 | Completed |
| AUTH-04 | 1 | Completed |
| AUTH-05 | 1 | Completed |
| EMERG-01 | 05 | Pending |
| EMERG-02 | 05 | Pending |
| HIST-01 | 03 | Completed |
| HIST-02 | 03 | Completed |
| HIST-03 | 03 | Completed |
| HIST-04 | 03 | Completed |
| NOTIF-01 | 04 | Pending |
| NOTIF-02 | 05 | Pending |
| MOB-01 | 06 | Pending |
| MOB-02 | 06 | Pending |
| MOB-03 | 02 | Validation Pending |
| PLAT-01 | 1 | Completed |
| PLAT-02 | 1 | Completed |
| PLAT-03 | 1 | Completed |
| PLAT-04 | 06 | Pending |
| PLAT-05 | 06 | Pending |
| MOB-04 | 05 | Pending |
| MOB-05 | 05 | Pending |
| WEB-01 | 06 | Pending |
| WEB-02 | 04 | Pending |
| WEB-03 | 06 | Pending |
| WEB-04 | 06 | Pending |
| ADMIN-01 | 06 | Pending |
| ADMIN-02 | 06 | Pending |
| ADMIN-03 | 06 | Pending |
| ADMIN-04 | 06 | Pending |
| ADMIN-05 | 06 | Pending |
