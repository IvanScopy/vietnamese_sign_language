# Phase 3: Face-to-Face Conversation & History - Context

**Gathered:** 2026-05-12
**Status:** Ready for planning

<domain>
## Phase Boundary

This phase delivers the v1 one-device face-to-face conversation experience:

- A portrait split-screen mode for a deaf user and a hearing user sharing one phone.
- Sign recognition output, speech subtitles, TTS playback, and manual correction in one conversation flow.
- A shared conversation timeline mirrored for both users with correct 180-degree orientation.
- Text-only local conversation history with search and plain-text sharing.

This phase must work even while Phase 2 recognition remains validation-pending. It should use the existing recognition pipeline where available, but it must not depend on a real VSL model being complete.

Out of scope:
- 3D avatar signing. Avatar work is v2+.
- Remote video calling. Video calling is Phase 4.
- SOS/SMS flows. SOS is Phase 5.
- Messenger-style chat/inbox between accounts.

</domain>

<decisions>
## Implementation Decisions

### One-Device Layout
- **D-01:** Use a portrait top/bottom split-screen layout.
- **D-02:** Rotate one half 180 degrees so two people can sit opposite each other and read their own side naturally.
- **D-03:** Each side has its own input and output area rather than a single shared panel.
- **D-04:** Each side sees a correctly oriented copy of the same conversation timeline.
- **D-05:** Optimize for mobile-first usage; landscape support is not required in Phase 3.

### Turn-Taking Between Signing and Speaking
- **D-06:** Use a clear manual toggle to switch between signing mode and speaking mode.
- **D-07:** Put the active-turn control in one shared center position.
- **D-08:** Only one input mode is active at a time.
- **D-09:** Switching turns automatically finalizes the current in-progress phrase and adds it to the timeline as a draft or confirmed message according to the message lifecycle.
- **D-10:** Speech-to-text during the hearing user's turn uses tap-to-start/tap-to-stop recording. Do not keep the microphone always listening.

### Conversation Timeline
- **D-11:** Display conversation messages as chat bubbles grouped by role.
- **D-12:** Message roles distinguish the signing user from the speaking user.
- **D-13:** Recognized sign text is editable before it is confirmed, played, or saved.
- **D-14:** TTS does not auto-play on phrase completion. The user must tap "Play" or "Confirm & Play".
- **D-15:** Messages move through a `draft -> confirmed` lifecycle.
- **D-16:** Only confirmed messages are eligible for history storage.
- **D-17:** Sign recognition messages should preserve confidence metadata when available.

### Text-Only History
- **D-18:** Store only confirmed messages in history.
- **D-19:** History is local-device only for v1. Do not sync Phase 3 history to the backend.
- **D-20:** Group history by conversation session and timestamp.
- **D-21:** Search uses full-text matching across confirmed transcript messages.
- **D-22:** Share/export uses plain text copy/share, not file export in Phase 3.
- **D-23:** Plain-text share format should include timestamp, role, and text.

### Recognition Fallback
- **D-24:** Low-confidence or unknown recognition should display an "unclear" state and offer manual text entry/editing.
- **D-25:** Manually entered or corrected text is recorded with `source = manual`.
- **D-26:** If the recognition service disconnects or errors, pause sign input but keep speech and manual entry available.
- **D-27:** Provide a demo/manual-friendly mode with clear labeling so Phase 3 UX can be tested before the real VSL model is ready.
- **D-28:** Do not pretend mock recognition is production recognition; demo/mock output must be visually labeled.

### the agent's Discretion
- Exact confidence thresholds can be chosen during planning based on existing Phase 2 values.
- Exact local storage mechanism can be selected during research/planning as long as it remains local-device only.
- Exact labels and microcopy can be refined for accessibility, but they must not introduce avatar/video-call/SOS scope.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project Scope
- `.planning/ROADMAP.md` — Phase 3 boundary, success criteria, dependencies, and out-of-scope items.
- `.planning/REQUIREMENTS.md` — Requirement IDs `COMM-04`, `HIST-01`, `HIST-02`, `HIST-03`, `HIST-04`.
- `.planning/STATE.md` — Current status: Phase 2 implemented but validation-pending; avatar deferred to v2+.
- `BRIEF.md` — Product vision and v1 note that avatar is deferred.

### Prior Phase Context
- `.planning/phases/01-foundation-authentication/01-CONTEXT.md` — Auth, STT/TTS, Socket.io, notification, and mobile/web API decisions.
- `.planning/phases/02-sign-language-recognition/02-CONTEXT.md` — Recognition pipeline decisions, phrase completion, confidence handling, and Phase 2 constraints.
- `.planning/phases/02-sign-language-recognition/02-VALIDATION.md` — Validation gaps that Phase 3 must not assume are solved.

### Existing Code
- `mobile/lib/screens/recognition_screen.dart` — Existing camera + recognition split view; likely starting point or reference for conversation mode.
- `mobile/lib/widgets/text_panel.dart` — Existing editable recognized-sign panel with audio playback hook.
- `mobile/lib/services/sign_recognition_service.dart` — Socket.io recognition client and connection status stream.
- `mobile/lib/models/recognition_event.dart` — Existing `RecognitionResult` and `PhraseComplete` models.
- `mobile/lib/main.dart` — Current Flutter app routing and `SharedPreferences` usage.
- `src/app/api/stt/transcribe/route.ts` — Existing Vietnamese STT endpoint.
- `src/app/api/tts/synthesize/route.ts` — Existing Vietnamese TTS endpoint.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- `RecognitionScreen`: already wires camera, recognition service streams, current signs, phrase completion, connection status, and camera toggle.
- `TextPanel`: already displays editable recognized sign bubbles, confidence indicators, and optional audio playback.
- `SignRecognitionService`: already exposes `signStream`, `phraseStream`, and `connectionStream` for recognition events and disconnect handling.
- `RecognitionResult` / `PhraseComplete`: can seed Phase 3 conversation message models, but Phase 3 likely needs additional fields like `role`, `source`, `status`, and `timestamp`.
- `SharedPreferences`: already used for auth token loading; local history may use a stronger local store if planner determines `SharedPreferences` is too limited.
- STT/TTS API routes: provide speech transcription and speech output capabilities for the hearing-user side.

### Established Patterns
- Flutter app uses `MaterialApp` routes and stateful screens.
- Phase 2 uses stream-based services for real-time recognition state.
- TTS playback is user-triggered in `TextPanel`, matching the Phase 3 decision to avoid automatic playback.
- Socket.io connection state already maps naturally to the Phase 3 fallback requirement.

### Integration Points
- Add a new conversation mode route/screen instead of overloading the Phase 2 recognition screen directly.
- Reuse recognition streams for sign-side input.
- Integrate STT for hearing-side input with tap-to-start/tap-to-stop controls.
- Add local conversation session/message storage.
- Add history list/detail/search/share screens or views.

</code_context>

<specifics>
## Specific Ideas

- The target layout is similar to Google Translate conversation mode: one phone, two people, opposite reading orientations.
- The app should stay usable in real situations such as school or hospital contexts even if sign recognition confidence is low.
- Manual correction is a first-class part of v1, not a hidden debug tool.
- History is a transcript of face-to-face sessions, not chat messages between accounts.

</specifics>

<deferred>
## Deferred Ideas

- Messenger/Discord-style chat between accounts belongs to a future phase if needed.
- Backend-synced conversation history belongs to a future phase if multi-device history becomes necessary.
- 3D avatar signing remains v2+.

</deferred>

---

*Phase: 3-Face-to-Face Conversation & History*
*Context gathered: 2026-05-12*
