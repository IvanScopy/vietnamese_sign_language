# Phase 2: Sign Language Recognition - Discussion Log

**Context gathered:** 2026-05-08
**Areas discussed:** 8
**Decisions captured:** 34

## Discussion Flow

### Area: Inference Location

**Q1: Primary inference location?**
- Options: On-device, Server-side, Hybrid
- **Decision:** Hybrid (on-device landmarks, server-side classification)

**Q2: Landmark protocol?**
- Options: REST endpoint, WebSocket, Socket.io rooms
- **Decision:** Socket.io rooms (reuses Phase 1 infrastructure)

**Q3: Fallback behavior?**
- Options: Cached lightweight model, Graceful degradation (unknown), Full on-device fallback
- **Decision:** Graceful degradation — show "unknown" on failure

**Q4: Session semantics?**
- Options: Continuous mode, Triggered mode, Hold-to-speak
- **Decision:** Continuous mode (active streaming while camera on)

**Follow-up:** Continuous mode selected.

---

### Area: Architecture

**Q1: Core model approach?**
- Options: MediaPipe + LSTM, Pre-trained VSL model, MediaPipe Holistic
- **Decision:** Pre-trained VSL model (use as-is)

**Q2: Model adaptation?**
- Options: Use as-is, Light fine-tuning, Transfer learning
- **Decision:** Use as-is (simplest path)

**Q3: Model serving?**
- Options: Python microservice, Direct Node.js integration, Separate model server
- **Decision:** Python FastAPI microservice

**Q4: Landmark format?**
- Options: MediaPipe native, Normalized features, JSON with metadata
- **Decision:** MediaPipe native format

**Note:** User suggested embedding-based approach could be considered if model supports it — backend architecture should accommodate both classification and embedding outputs.

---

### Area: Sign Vocabulary

**Q1: Vocabulary size?**
- Options: 100 signs, 200 signs, 500 signs
- **Decision:** Depends on available pre-trained model coverage (research-dependent)

**Q2: Unknown signs handling?**
- Options: Silent reject, Visual feedback, Closest match
- **Decision:** Conditional — embedding: personal vocabulary addable; classification: visual feedback

**Q3: Compound signs?**
- Options: Yes support sequences, No single only, Defer to Phase 5
- **Decision:** Yes, support sequences (phrase building)

**Q4: Phrase boundary detection?**
- Options: Time-based pause, Pause gesture, Continuous
- **Decision:** Time-based pause (2-3 seconds inactivity)

---

### Area: Cross-Platform Implementation

**Q1: MediaPipe implementation?**
- Options: Shared WebAssembly, Platform-native, Server-only
- **Decision:** Platform-native (Web: JS package, Mobile: Flutter plugin)

**Q2: Camera preview layout?**
- Options: Full-screen, Split view, Picture-in-picture
- **Decision:** Split view (side-by-side camera and text)
- **Note:** Preview must accommodate both one-hand and two-hand VSL signs

**Q3: Frame processing rate?**
- Options: Every frame, 15 FPS, Adaptive
- **Decision:** 15 FPS (provisional, model-dependent)

**Q4: Hand tracking scope?**
- Options: Both hands, Primary hand only, Auto-detect
- **Decision:** Both hands simultaneously

**Clarification:** User confirmed split view choice.

---

### Area: Visual Feedback UI

**Q1: Hand skeleton overlay?**
- Options: Yes always on, No overlay, Optional toggle
- **Decision:** No overlay (clean camera preview)

**Q2: Processing feedback?**
- Options: Spinner only, Confidence meter, Both, None
- **Decision:** Confidence meter (shows recognition quality)

**Q3: Text display format?**
- Options: Instant replacement, Accumulating list, Editable text field
- **Decision:** 2 + 3 — Accumulating editable list (chat bubbles, user can edit before TTS)

**Q4: TTS trigger?**
- Options: Automatic, Manual button, Tap text, After phrase complete
- **Decision:** After phrase complete (prevents mid-phrase interruptions)

---

### Area: Performance Targets

**Q1: Latency target?**
- Options: <500ms, <1 second, <2 seconds
- **Decision:** <1 second (conversational pace)

**Q2: Recognition accuracy?**
- Options: >70%, >85%, >95%
- **Decision:** >70% (baseline MVP, users will adapt)

**Q3: Concurrent capacity?**
- Options: 10-20 users, 50-100 users, 500+ users
- **Decision:** 10-20 users (beta scale)

**Q4: Model size vs accuracy?**
- Options: Size priority, Accuracy priority, No preference
- **Decision:** No preference — use best available VSL model

---

### Area: Error Handling

**Q1: Low confidence results?**
- Options: Show "unclear", Best guess with %, Ask for confirmation
- **Decision:** Best guess with % confidence

**Q2: Socket.io disconnection?**
- Options: Auto-reconnect + buffer, Pause + notify, REST fallback
- **Decision:** Pause + notify (clear UI state)

**Q3: Camera permission denied?**
- Options: Guidance only, Text input fallback, Lock feature
- **Decision:** Show guidance explaining why camera needed, offer to grant permission, recognition features disabled until granted (other app features remain usable)

**Q4: Server errors?**
- Options: Generic retry, Specific message, Auto-retry
- **Decision:** Generic retry ("Recognition unavailable, please try again")

---

### Area: Camera Configuration

**Q1: Default camera?**
- Options: Rear camera, Front camera, User-selectable
- **Decision:** User-selectable (rear default with toggle to front)

**Q2: Resolution?**
- Options: Native/auto, 720p HD, 480p SD
- **Decision:** 720p HD (1280x720)

**Q3: Focus/exposure?**
- Options: Auto, Tap-to-focus, Lock-on-start
- **Decision:** Auto

**Q4: Buffer strategy?**
- Options: Real-time streaming, Double buffering, Triple buffering
- **Decision:** Real-time streaming (lowest latency)

---

## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
_None_

---

*End of discussion log*
