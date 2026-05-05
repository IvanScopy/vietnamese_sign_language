# Requirements — VSL Communication Platform

## v1 Requirements

### Authentication & User Management (AUTH)

- [ ] **AUTH-01**: User can register with email, password, user type (deaf/hearing), age, and phone number
- [ ] **AUTH-02**: User can log in with email/password and maintain session across app restarts
- [ ] **AUTH-03**: User can log out from any page/screen
- [ ] **AUTH-04**: Deaf user can add emergency contact phone number for SOS notifications
- [ ] **AUTH-05**: User can view and edit their profile information

### Real-time Sign Recognition (SIGN)

- [ ] **SIGN-01**: System can recognize VSL gestures in real-time through device camera
- [ ] **SIGN-02**: Recognized signs are converted to Vietnamese text displayed on screen
- [ ] **SIGN-03**: Recognized text is spoken aloud using Vietnamese TTS for hearing users
- [ ] **SIGN-04**: System provides visual feedback when sign is being recognized
- [ ] **SIGN-05**: Recognition works with both front and rear cameras (if available)

### Speech Recognition + Subtitles (SPEECH)

- [ ] **SPEECH-01**: System recognizes Vietnamese speech in real-time and converts to text
- [ ] **SPEECH-02**: Recognized speech is displayed as subtitles on screen
- [ ] **SPEECH-03**: Subtitles are clear, readable, and update in near real-time (<2s delay)
- [ ] **SPEECH-04**: System handles continuous speech with appropriate segmentation

### 3D Avatar Signing (AVATAR)

- [ ] **AVATAR-01**: System displays a 3D avatar (male and female options) that can perform VSL gestures
- [ ] **AVATAR-02**: Avatar animates signs corresponding to Vietnamese text input (from speech recognition)
- [ ] **AVATAR-03**: Avatar displays hand, arm, and body movements appropriate for VSL
- [ ] **AVATAR-04**: Avatar animations are smooth and intelligible to deaf users
- [ ] **AVATAR-05**: User can toggle between male and female avatar models

### Face-to-Face Communication Mode (FACE2FACE)

- [ ] **F2F-01**: App provides split-screen UI optimized for two users facing each other
- [ ] **F2F-02**: Deaf user's side: camera input for sign recognition + hearing side's avatar/subtitles
- [ ] **F2F-03**: Hearing user's side: microphone for speech + deaf side's text/speech output
- [ ] **F2F-04**: Screen content is mirrored/rotated so each user reads naturally
- [ ] **F2F-05**: Clear visual indicators show which side (camera or mic) is active
- [ ] **F2F-06**: Users can easily toggle between sign mode and speech mode

### Video Calling (CALL)

- [ ] **CALL-01**: Users can initiate and receive 1-on-1 video calls within the app
- [ ] **CALL-02**: Call screen shows both users' video feeds
- [ ] **CALL-03**: During call, deaf user's sign recognition works (text → speech output for hearing user)
- [ ] **CALL-04**: During call, hearing user's speech shows subtitles + avatar for deaf user
- [ ] **CALL-05**: App shows incoming call notification when app is backgrounded/closed
- [ ] **CALL-06**: Users can accept, reject, or end calls

### VSL Dictionary (DICT)

- [ ] **DICT-01**: User can search Vietnamese words/phrases and see corresponding VSL sign demonstration (video/animation)
- [ ] **DICT-02**: User can perform a sign (via camera) and see the Vietnamese meaning
- [ ] **DICT-03**: Dictionary is organized by categories (greetings, medical, education, family, emotions, numbers, etc.)
- [ ] **DICT-04**: Each sign entry includes clear demonstration and description
- [ ] **DICT-05**: User can mark signs as "learning" or "mastered"

### VSL Learning System (LEARN)

- [ ] **LEARN-01**: App provides themed lessons (greetings, numbers, medical terms, etc.) with progressive content
- [ ] **LEARN-02**: Lessons include video demonstrations of signs with instructions
- [ ] **LEARN-03**: User can practice signs through camera-based exercises with recognition feedback (correct/incorrect)
- [ ] **LEARN-04**: System provides quizzes/tests to assess learning progress
- [ ] **LEARN-05**: User can track learning progress per theme/sign
- [ ] **LEARN-06**: Lessons are structured with prerequisites and completion order

### Emergency SOS (SOS)

- [ ] **SOS-01**: Prominent SOS button accessible from main screens
- [ ] **SOS-02**: When activated, app sends SMS to pre-configured emergency contacts
- [ ] **SOS-03**: SMS includes user's current GPS location
- [ ] **SOS-04**: SOS sends at minimum: "Emergency! I need help. My location: [GPS]"
- [ ] **SOS-05**: App provides visual confirmation SOS was sent
- [ ] **SOS-06**: SOS requires deliberate action (confirmation dialog) to prevent accidental triggers

### Notifications (NOTIF)

- [ ] **NOTIF-01**: App sends push notification for incoming video calls
- [ ] **NOTIF-02**: Deaf users receive visual notifications (vibration, flash) for important alerts
- [ ] **NOTIF-03**: Admin can send broadcast notifications to users
- [ ] **NOTIF-04**: App sends learning reminder notifications (configurable frequency)
- [ ] **NOTIF-05**: SOS sends notifications to emergency contacts

### Conversation History (HISTORY)

- [ ] **HIST-01**: App saves conversation history as text (no audio/video recording)
- [ ] **HIST-02**: User can view past conversations organized by date/time
- [ ] **HIST-03**: User can search within conversation history
- [ ] **HIST-04**: User can share conversation text with others (share via other apps)
- [ ] **HIST-05**: User can delete conversation history

### Admin Panel (ADMIN) — Web Only

- [ ] **ADMIN-01**: Admin can view list of all registered users
- [ ] **ADMIN-02**: Admin can suspend or delete user accounts
- [ ] **ADMIN-03**: Admin can add, edit, or delete dictionary entries (VSL signs)
- [ ] **ADMIN-04**: Admin can create, edit, or delete lessons and quiz content
- [ ] **ADMIN-05**: Admin can view usage statistics (active users, feature usage, popular signs)
- [ ] **ADMIN-06**: Admin can view SOS incident history
- [ ] **ADMIN-07**: Admin can send notification messages to users
- [ ] **ADMIN-08**: Admin panel supports multiple admin users with role-based permissions
- [ ] **ADMIN-09**: Super Admin can manage admin user accounts and permissions

### Platform Support (PLATFORM)

- [ ] **PLAT-01**: Web application works on modern browsers (Chrome, Firefox, Safari, Edge)
- [ ] **PLAT-02**: Mobile app available for iOS and Android
- [ ] **PLAT-03**: Both web and mobile share same feature set (except admin web-only)
- [ ] **PLAT-04**: Camera works on both webcam (web) and device camera (mobile)
- [ ] **PLAT-05**: App handles network connectivity issues with appropriate user feedback

---

## v2 / Future Requirements (Deferred)

### Advanced Features
- Group video calls (multi-party)
- Offline mode with cached dictionary/lessons
- OAuth/social login integration
- Voice/video call with non-app users
- Advanced facial expression recognition
- Support for regional VSL dialects
- Custom avatar creation
- Call recording (with consent)
- Multi-language support beyond Vietnamese

### Platform Extensions
- Wearable companion app
- Desktop app (Electron)
- Progressive Web App (PWA) support
- Smart TV interface for large-screen use

---

## Out of Scope — Rationale

| Exclusion | Reason |
|-----------|--------|
| SMS/call integration with Vietnamese emergency services (115) | Requires partnership with government/emergency services — may be pursued in v2 |
| Multi-party video calls | v1 focus is on 1-on-1 communication; group calls add significant complexity |
| Offline AI processing | Requires local ML models too heavy for mobile; keep v1 simple with online-first |
| Other sign languages (ASL, CSL, etc.) | VSL is the focus; other languages would require separate models and data |
| Wearable integration | Out of scope for MVP; could integrate with smartwatches later |
| OAuth/social login | Email/password is sufficient for v1; social login adds auth complexity |
| Non-app user calls | WebRTC requires both parties to have the app for full features |
| Advanced facial expression recognition | Depends on training data availability; basic sign recognition first |
| Voice-only emergency calls | SOS sends SMS with location; direct voice call would need telecom integration |

---

## Traceability Matrix

| Requirement | Phase | Status |
|-------------|-------|--------|
| All v1 requirements | TBD | Pending |

---

*Last updated: 2026-05-05 after initialization*
