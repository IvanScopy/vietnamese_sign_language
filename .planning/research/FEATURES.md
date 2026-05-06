# Feature Research

**Domain:** Vietnamese Sign Language (VSL) Bridge Application
**Researched:** 2026-05-05
**Confidence:** HIGH

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist. Missing these = product feels incomplete or unusable.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Real-time sign recognition (camera → text/speech) | Core value proposition - without this, no bridge exists | HIGH | Requires MediaPipe/LSTM pipeline; depends on quality VSL model coverage; sub-second latency critical |
| Speech-to-text transcription (speech → text) | Hearing users need to see what they say; enables two-way comms | LOW-MEDIUM | Mature tech (Whisper, Vosk); language: Vietnamese required |
| Text-to-speech output (text → audio) | Deaf child recipient needs to hear parent's voice | LOW | Standard TTS (eSpeak, Piper); Vietnamese voice |
| Sign dictionary with video library | Essential learning reference; users expect to look up signs | MEDIUM | 4,000 VSL videos provided; tagging/search system needed |
| User profiles/accounts | Standard app pattern; enables data persistence | LOW | Basic auth, profile storage |
| Emergency SOS with GPS | Safety-critical; parents expect emergency capability | MEDIUM | Requires location permissions, SMS integration, contact management |
| Split-screen conversation mode | Face-to-face communication pattern is intuitive | LOW | Two-pane layout with camera and text output |
| Video calling between users | Modern communication expectation | HIGH | WebRTC, signaling server, NAT traversal; complex infrastructure |
| Progress tracking in learning | Educational apps must show progress | LOW-MEDIUM | Simple persistence of completed lessons/quizzes |

### Differentiators (Competitive Advantage)

Features that set the product apart. Not required, but valuable for market position.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| 3D avatar signing system | Novel "text-to-sign" output; inclusive for deaf-blind or low-bandwidth | VERY HIGH | Requires VSL animation rig, motion generation; major technical challenge |
| AI-assisted sign feedback (learning) | "Auto-grading" of student signs; reduces parent teaching burden | HIGH | Sign recognition + comparison algorithm; feedback UX design |
| Family/contact linking | Enables parent-child learning together remotely | LOW-MEDIUM | Social graph; simplified by focusing on direct contacts only |
| Shared conversation history | Educational value; review past communications | LOW | Text storage with search |
| Bilingual learning lessons (VSL ↔ Vietnamese) | Structured curriculum for non-signing parents | MEDIUM | Lesson design, progression system |
| Visual notification system | Accessibility-first; deaf users don't miss calls | LOW | Custom notification patterns/colors |
| Cross-platform parity (mobile + web) | Unusual commitment; most go mobile-only | HIGH | Two complete UIs; coordinated release burden |
| Open-source stack preference | Cost control, community trust, transparency | VARIES | May increase integration effort but reduces vendor lock-in |
| On-device ML inference option | Privacy-preserving; works offline partially | VERY HIGH | Model quantization, optimization; accuracy trade-offs |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good but create problems or scope creep.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Video/audio recording of conversations | "For review" or sharing moments | Privacy nightmare; GDPR/child protection; storage costs | Text-only history with user consent |
| Offline sign recognition | No internet needed | VSL models are large; accuracy suffers; update impossible | Online-first; cache only dictionaries |
| Multi-language translation | "International appeal" | Dilutes focus; Vietnamese-specific model needed | Stay focused on VSL ↔ Vietnamese only |
| Social network features (feeds, groups) | Engagement/retention | Scope explosion; moderation nightmare | Direct contacts only; no public content |
| Custom model training UI | Users want personalized recognition | Requires expert labeling; quality degradation | Pre-trained model only; focus on inference |
| Real-time sign-to-sign translation (e.g., VSL → ASL) | "Help more users" | Requires full second model; accuracy unknown | Single sign language focus only |
| Video recording of learning progress | Parents want to see child's improvement | Storage costs; privacy concerns | Quiz scores + text feedback only |
| Advanced admin analytics dashboard | Data-driven decisions | Scope creep; low value to users | Basic usage metrics only |
| Push-to-talk walkie-talkie mode | Quick communication | Obsoleted by video call; redundant | Full video call feature |

## Feature Dependencies

```
Real-time sign recognition
    ├──requires──> VSL gesture recognition model (pre-trained)
    └──requires──> MediaPipe hand/pose tracking

3D avatar signing system
    ├──requires──> Sign dictionary video corpus (for motion reference)
    └──conflicts──> On-device ML inference (avatar needs server rendering)

Video calling
    ├──requires──> WebRTC infrastructure
    ├──requires──> User accounts (identity)
    └──conflicts──> Low-bandwidth mode (video requires bandwidth)

Emergency SOS
    ├──requires──> User accounts (emergency contacts)
    └──enhances──> GPS location services

Learning system
    ├──requires──> Sign dictionary
    └──enhances──> AI-assisted sign feedback (optional)

Cross-platform (mobile + web)
    ├──requires──> Shared backend API
    └──enhances──> All features (broader reach)

On-device ML inference
    ├──requires──> Quantized models
    └──conflicts──> 3D avatar (server-side rendering)
```

### Dependency Notes

- **Real-time sign recognition requires VSL model:** Without a pre-trained VSL recognition model, the core feature cannot exist. This is the critical path item.
- **Video calling requires WebRTC:** Full implementation requires STUN/TURN servers and signaling infrastructure. Can be simplified to 1:1 only initially.
- **3D avatar conflicts with on-device inference:** Avatar rendering requires computational resources; choose server-side for quality OR device-side for privacy.
- **Learning system depends on dictionary:** Cannot have lessons without signs to teach.
- **Cross-platform amplifies costs:** Every feature must be implemented twice (mobile + web).

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed to validate the concept with real deaf children and parents.

- [ ] **Sign Recognition (basic)** - 100-200 most common VSL signs; camera → text display; >80% accuracy in good lighting
- [ ] **Speech-to-text transcription** - Vietnamese speech recognition for hearing parent speech
- [ ] **Text-to-speech output** - Vietnamese TTS for spoken output to deaf child
- [ ] **Split-screen conversation mode** - Face-to-face communication with real-time captioning
- [ ] **Sign dictionary (viewer only)** - 4,000 VSL videos with search; no learning features yet
- [ ] **Basic user accounts** - Login/registration; profile storage
- [ ] **Mobile app (iOS/Android)** - Polished but single-platform initially
- [ ] **Emergency SOS** - GPS location + SMS to pre-set contacts (single emergency contact)
- [ ] **Text-only conversation history** - Store and review past conversations locally
- [ ] **Visual notifications** - Customizable for deaf users

### Add After Validation (v1.x)

Features to add once core is working and validated with users.

- [ ] **AI-assisted sign feedback** - Camera-guided practice with accuracy scoring
- [ ] **Learning lessons** - Structured curriculum organized by topic (family, food, school)
- [ ] **Progress tracking** - Learned signs count, quiz scores
- [ ] **Video calling** - 1:1 calls between registered users
- [ ] **Contact linking** - Connect with family members in the app
- [ ] **Shared conversation history** - Sync across devices
- [ ] **Expanded sign recognition** - Increase to 1,000+ signs

### Future Consideration (v2+)

Features to defer until product-market fit is established.

- [ ] **3D avatar signing** - Technically complex; defer until v2
- [ ] **Web app** - Mobile-first success; web as separate phase
- [ ] **On-device inference option** - Privacy variant for advanced users
- [ ] **Extended emergency features** - Multiple contacts, escalation protocols
- [ ] **Parent dashboard** - Child's learning progress overview

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority | Dependencies |
|---------|------------|---------------------|----------|--------------|
| Speech-to-text transcription | HIGH | LOW | P1 | None |
| Text-to-speech output | HIGH | LOW | P1 | None |
| Sign dictionary (viewer) | HIGH | MEDIUM | P1 | None |
| Split-screen conversation mode | HIGH | LOW | P1 | Sign recognition + STT |
| Sign recognition (basic) | VERY HIGH | HIGH | P1 | VSL model |
| Basic user accounts | HIGH | LOW | P1 | None |
| Emergency SOS | HIGH | MEDIUM | P1 | User accounts + GPS |
| Text history | MEDIUM | LOW | P1 | User accounts |
| Visual notifications | MEDIUM | LOW | P1 | None |
| AI sign feedback | HIGH | HIGH | P2 | Sign recognition |
| Learning lessons | HIGH | MEDIUM | P2 | Dictionary |
| Video calling | MEDIUM | HIGH | P2 | User accounts + WebRTC |
| Progress tracking | MEDIUM | LOW | P2 | Learning lessons |
| Contact linking | MEDIUM | LOW | P2 | User accounts |
| 3D avatar | LOW-MEDIUM | VERY HIGH | P3 | Dictionary + motion tech |
| On-device inference | MEDIUM | VERY HIGH | P3 | Model optimization |
| Web app | MEDIUM | HIGH | P3 | Backend API |

**Priority key:**
- P1: Must have for launch (MVP)
- P2: Should have, add after validation (v1.x)
- P3: Nice to have, future consideration (v2+)

## Competitor Feature Analysis

| Feature | Competitor Pattern | Our Approach |
|---------|-------------------|--------------|
| Sign recognition | Cloud-based APIs (Google, Azure) with general ASL coverage | VSL-specific model; focus on Vietnamese signs; aim for higher accuracy on target vocabulary |
| Speech recognition | General-purpose STT (Whisper) | Vietnamese-language optimization |
| Dictionary | Static video library | Interactive with search + integration into learning |
| Avatar signing | Rare (SignAll experimental) | Defer to v2; prioritize text+speech first |
| Learning system | Gamified apps (Duolingo-style) | Bilingual parent-child focus; structured by real-world topics |
| Emergency features | Not commonly found | First-class feature with GPS + SMS integration |
| Platform parity | Mobile-only dominant | Commit to both mobile + web from v1 |

## Key Technical Considerations

### Sign Recognition Architecture
- **Recommended stack:** MediaPipe Hands → landmark extraction → LSTM classification
- **Model source:** Seek pre-trained VSL model (critical dependency)
- **Latency target:** <500ms for natural conversation flow
- **Accuracy target:** >85% on top 200 signs in controlled conditions

### Speech Technologies
- **STT:** Whisper (OpenAI) or Vosk (offline capable) with Vietnamese model
- **TTS:** Piper or eSpeak with Vietnamese voice
- **Latency target:** <1s for full pipeline

### Infrastructure
- **Backend:** Simple REST API for accounts, history, SOS
- **Real-time:** WebSocket for conversation sync; WebRTC for calls
- **Storage:** Text-only for privacy compliance; no media retention

### Complexity Ratings Explained
- **LOW:** <1 week implementation, proven technology
- **MEDIUM:** 1-3 weeks, some integration work
- **HIGH:** 1-3 months, significant technical challenge
- **VERY HIGH:** 3+ months, novel R&D or complex infrastructure

## Sources

- Project context: `/home/ivan/vsl-final-5days/.planning/PROJECT.md`
- MediaPipe documentation: /google-ai-edge/mediapipe (hand tracking, gesture recognition)
- Domain knowledge: Sign language technology landscape (ASL/VSL translation systems)
- Existing apps analysis: Ava, RogerVoice, MotionSavvy industry patterns

---

*Feature research for: Vietnamese Sign Language Bridge*
*Researched: 2026-05-05*
