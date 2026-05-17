---
phase: 03-face-to-face-conversation-history
plan: 01
status: completed
completed_date: 2026-05-16
requirements:
  - COMM-04
  - HIST-01
  - HIST-02
  - HIST-03
  - HIST-04
tests:
  - "cd mobile && flutter analyze"
  - "cd mobile && flutter test"
---

# Phase 3 Plan 01 Summary: Conversation Mode & Local History

## What Was Delivered

### One-Device Conversation Mode

- Added `ConversationScreen` at `/conversation`.
- Added portrait top/bottom participant panels, with the top panel rotated 180 degrees for face-to-face use.
- Added center turn control for Sign/Speak mode, enforcing one active input mode at a time.
- Wired signer mode to the existing recognition service streams and camera landmark pipeline.
- Added editable drafts before confirmation, including low-confidence/unclear labeling.
- Added user-triggered Confirm and Confirm & Play flow for sign-side TTS audio.
- Added tap-to-start/tap-to-stop speech recording using `record`, then sends captured audio to the existing STT endpoint through `SpeechTranscriptionService`.
- Preserved manual text entry fallback when recognition or speech capture is unavailable.

### Local Text-Only History

- Added `ConversationMessage` and `ConversationSession` models with role, source, status, confidence, and timestamps.
- Added `ConversationHistoryService` backed by `SharedPreferences`.
- Stored only confirmed text messages; draft messages and media payloads are excluded.
- Added `/history` route with session list, timestamp preview, transcript detail, search, and plain-text copy.
- Export format includes session timestamp, message timestamp, role, and text.

### App Integration

- Home screen now routes to Conversation, Sign Recognition, and History.
- Added microphone permissions for Android and iOS.
- Added direct Flutter dependencies for `http`, `record`, and `path_provider`.

## Files Added

- `mobile/lib/models/conversation.dart`
- `mobile/lib/services/conversation_history_service.dart`
- `mobile/lib/services/speech_transcription_service.dart`
- `mobile/lib/screens/conversation_screen.dart`
- `mobile/lib/screens/conversation_history_screen.dart`
- `mobile/test/services/conversation_history_service_test.dart`
- `mobile/test/widgets/conversation_screen_test.dart`

## Files Modified

- `mobile/lib/main.dart`
- `mobile/pubspec.yaml`
- `mobile/pubspec.lock`
- `mobile/android/app/src/main/AndroidManifest.xml`
- `mobile/ios/Runner/Info.plist`

## Verification

```bash
cd mobile && flutter analyze
# No issues found

cd mobile && flutter test
# 39 tests passed
```

## Notes

- STT recording is implemented on the client, but real transcription still depends on the configured backend base URL exposing `/api/stt/transcribe`.
- Phase 2 recognition remains validation-pending, so Phase 3 keeps manual fallback and clear recognition/offline states.
