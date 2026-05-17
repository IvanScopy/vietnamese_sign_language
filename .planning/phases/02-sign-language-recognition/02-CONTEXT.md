# Phase 2: Sign Language Recognition - Context

**Gathered:** 2026-05-08
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers real-time Vietnamese Sign Language recognition:
- Camera input with on-device hand landmark extraction (MediaPipe)
- Socket.io streaming to backend classification service
- Recognized text displayed with confidence indicators
- Text-to-speech output for hearing users after phrase completion
- Support for one-handed and two-handed signs
- Compound sign sequences (phrases) with time-based boundary detection

The phase enables deaf users to sign and have their intent understood by hearing users through speech output.

</domain>

<decisions>
## Implementation Decisions

### Inference Location & Communication

- **D-01:** Hybrid inference — hand landmarks extracted on-device (mobile), classification runs server-side
- **D-02:** Socket.io rooms for real-time landmark streaming and result delivery
- **D-03:** Graceful degradation — show "unclear" or "unknown sign" on server failure (no on-device fallback classifier)
- **D-04:** Continuous recognition mode — active streaming while camera is on
- **D-05:** Time-based phrase completion — 2-3 seconds of inactivity ends phrase, triggers TTS

### Recognition Architecture

- **D-06:** Pre-trained VSL-specific model (use as-is, no fine-tuning)
- **D-07:** Python FastAPI microservice for model serving (separate from Node.js API)
- **D-08:** MediaPipe native format for landmarks — send raw landmark objects (21 points × 3D coordinates)
- **D-09:** Model flexibility required — backend architecture should support both classification (label + confidence) and embedding-based (vector similarity) model outputs, depending on what research finds

### Sign Vocabulary

- **D-10:** Vocabulary size depends on available pre-trained model coverage
- **D-11:** Unknown signs — embedding: allow personal vocabulary addition; classification: visual feedback only
- **D-12:** Compound signs supported — sequences form phrases
- **D-13:** Phrase detection by time-based pause

### Cross-Platform Implementation

- **D-14:** Platform-native MediaPipe — Web: @mediapipe/tasks-vision JS; Mobile: flutter_mediapipe plugin
- **D-15:** Split view layout — side-by-side camera preview and recognized text panel
- **D-16:** 15 FPS landmark extraction (provisional, may adjust after model characteristics known)
- **D-17:** Track both hands simultaneously — essential for two-handed VSL signs
- **D-18:** Camera preview must accommodate both one-hand and two-hand signs with adequate framing
- **D-19:** User-selectable camera (rear default with toggle to front)

### Visual Feedback UI

- **D-20:** No hand skeleton overlay — clean camera preview
- **D-21:** Confidence meter — display recognition confidence for user judgment
- **D-22:** Accumulating editable text list — signs build up as chat bubbles, user can edit before TTS
- **D-23:** TTS triggered after phrase completion (time pause)

### Performance Targets

- **D-24:** End-to-end latency <1 second (camera frame to recognized text)
- **D-25:** Recognition accuracy >70% for signs within vocabulary (baseline MVP)
- **D-26:** Concurrent capacity 10-20 users (beta scale)
- **D-27:** Model size — no preference (use best available VSL model)

### Error Handling

- **D-28:** Low confidence results — show best guess with confidence percentage
- **D-29:** Socket.io disconnect — pause recognition with clear notification, user manually resumes
- **D-30:** Camera permission denied — show guidance explaining why camera needed, offer to grant permission, recognition features disabled until granted (other app features remain usable)
- **D-31:** Server errors (5xx, timeout) — generic retry message ("Recognition unavailable, please try again")

### Camera Configuration

- **D-32:** Resolution: 720p HD (1280x720)
- **D-33:** Focus/exposure: Auto
- **D-34:** Buffer strategy: Real-time streaming (process frames as they arrive)

### Claude's Discretion

- Frame rate may be adjusted (from 15 FPS) after model characteristics are known
- Exact phrase timeout duration (2-3 seconds) can be tuned during testing
- Specific confidence thresholds for "low confidence" display

### Folded Todos
_None — no todos folded into this phase_

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Documentation

- `.planning/PROJECT.md` — Project overview, constraints, technology stack
- `.planning/REQUIREMENTS.md` — Full requirements catalog (SIGN-01 through SPEECH-04)
- `.planning/ROADMAP.md` — Phase 2 boundary, dependencies, success criteria
- `.planning/STATE.md` — Current project state and blockers

### Phase 1 Documentation

- `.planning/phases/01-foundation-authentication/01-CONTEXT.md` — Prior decisions (STT/TTS providers, Socket.io, JWT auth, Docker Compose)
- `.planning/phases/01-foundation-authentication/01-PATTERNS.md` — Code patterns (Next.js routes, provider strategy, Prisma usage)
- `.planning/phases/01-foundation-authentication/01-RESEARCH.md` — Technical research for backend patterns

### External References

- MediaPipe Tasks Vision documentation (hand landmark extraction)
- Socket.io documentation (rooms, real-time events)
- FastAPI documentation (Python microservice patterns)

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets

- Socket.io infrastructure (`src/app/lib/socket.ts`) — reuse for recognition events
- Provider strategy pattern (`src/app/lib/providers/`) — similar pattern for recognition model service
- Docker Compose setup — add Python FastAPI service for model serving
- Zod validation patterns — similar schemas for landmark payloads
- Next.js route handlers — pattern for Socket.io event handlers

### Established Patterns

- Environment-based provider selection (STT_PROVIDER, TTS_PROVIDER) — apply similar pattern for RECOGNITION_MODEL config
- Hybrid cloud/local fallback (STT/TTS) — informs error handling approach (though we chose graceful degradation here)
- Socket.io for real-time bidirectional communication — same pattern for landmark streaming
- TypeScript strict mode and Zod validation — apply to landmark payload schemas

### Integration Points

- New Socket.io namespace/rooms for recognition sessions
- Python FastAPI service alongside existing Node.js API (Docker Compose)
- New Prisma models: potentially RecognitionSession, SignVocabulary (if tracking)
- Client integration with MediaPipe (web: JS, mobile: Flutter plugin)

</code_context>

<specifics>
## Specific Ideas

- User mentioned preference for embedding-based approach (nearest-neighbor similarity) if model supports it, vs classification. Architecture should accommodate either.
- Split view layout chosen to provide simultaneous camera and text feedback — important for learning proper sign form.
- Accumulating editable text list allows user to see phrase build-up and correct errors before TTS — acknowledges that model accuracy is baseline (>70%).
- No hand skeleton overlay keeps preview clean — user may be self-conscious about being on camera; clean view less intimidating for beginners.
- Phrase detection by time-based pause chosen over explicit gesture — simpler for users to learn initially, can be refined later.

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope.

### Reviewed Todos (not folded)
_None_

</deferred>

---

*Phase: 2-Sign Language Recognition*
*Context gathered: 2026-05-08*
