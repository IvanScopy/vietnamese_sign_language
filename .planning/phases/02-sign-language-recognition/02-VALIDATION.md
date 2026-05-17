# Phase 02 — Validation Strategy

## Scope

Phase 02 delivers the Sign Recognition MVP:

- camera/MediaPipe landmark extraction
- Socket.io landmark streaming
- server-side recognition pipeline
- confidence feedback
- phrase completion and TTS handoff
- mobile camera UI

Phase 02 is implemented but remains validation-pending until real-device and real-model checks are complete.

## Requirement Gates

| Req ID | Gate | Validation Type | Status |
|--------|------|-----------------|--------|
| COMM-01 | Landmark sequence produces recognized Vietnamese text | unit + integration | Partial: mock LSTM implemented |
| COMM-01 | Real-device end-to-end latency measured | performance | Pending |
| COMM-01 | Recognition accuracy measured against target vocabulary | UAT/model validation | Pending |
| COMM-06 | Confidence scoring is surfaced to the user | unit + UI integration | Partial |
| MOB-03 | Camera access works on Android/iOS device | manual device test | Pending |
| MOB-03 | Front/rear camera toggle works | manual device test | Implemented, pending device verification |
| COMM-03 | Phrase completion can trigger TTS playback | integration | Implemented, pending device audio verification |

## Automated Checks

| Check | Command | Expected Result |
|-------|---------|-----------------|
| Recognition service tests | `pytest recognition-service/tests -v` | All tests pass |
| Backend/API tests | `npm test` | All relevant Phase 1/2 tests pass |
| Flutter static checks | `flutter analyze` | No blocking analyzer errors |
| Flutter tests | `flutter test` | All widget/unit tests pass |

## Manual / UAT Checks

| Check | Method | Pass Criteria |
|-------|--------|---------------|
| Android camera pipeline | Run app on physical Android device | Camera opens, landmarks stream, results display |
| iOS camera pipeline | Run app on physical iOS device | Camera opens, landmarks stream, results display |
| Audio playback | Complete phrase and trigger TTS | User hears synthesized Vietnamese output |
| Latency | Measure camera frame to displayed text | Meets roadmap target or documented fallback |
| Recognition quality | Test target sign vocabulary with fluent signer or curated samples | Accuracy result recorded before full completion |

## Known Gaps

- Real VSL model is not yet selected; mock LSTM is a placeholder.
- Physical device testing is not yet recorded.
- End-to-end latency has not been measured on device.
- Accuracy has not been measured against a real VSL vocabulary.

## Completion Rule

Phase 02 can be marked fully complete only after the known gaps above are either resolved or explicitly accepted as v1 limitations in `STATE.md`.
