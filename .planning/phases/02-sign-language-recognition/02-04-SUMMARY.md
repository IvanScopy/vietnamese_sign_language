# Phase 2 Wave 3 Summary: Flutter Frontend Integration

**Completed:** 2026-05-10
**Status:** Implementation complete, pending physical device testing

---

## Overview

Wave 3 delivered the Flutter mobile frontend for sign language recognition. The implementation provides a split-view interface with live camera preview and real-time sign recognition, streaming landmarks to the backend via Socket.io.

## Flutter MediaPipe Integration

### Current State
- **Package:** `flutter_mediapipe 0.0.7` added to dependencies
- **Status:** Basic camera integration complete; MediaPipe landmark detection pending API stabilization
- **Placeholder:** Mock landmarks are currently emitted to demonstrate the pipeline architecture

### Camera Configuration
- **Resolution:** `ResolutionPreset.high` (720p minimum)
- **Image Format:** YUV 4:2:0 (`ImageFormatGroup.yuv420`)
- **Target FPS:** 15 frames per second for landmark processing
- **Throttling:** Frame processing throttled to avoid overwhelming the pipeline

### Implementation Details
The `CameraPreviewWithMediaPipe` widget:
- Requests camera permission on initialization using `permission_handler`
- Supports both front and rear camera selection
- Streams `CameraImage` frames via `startImageStream()`
- Processes frames asynchronously with FPS throttling
- Emits `LandmarksPayload` via callback to parent

**TODO:** Replace mock landmark generation with actual MediaPipe `HandLandmarker.process()` call once the package API is confirmed stable.

## Socket.io Connection Handling

### Service Architecture
`SignRecognitionService` manages the WebSocket connection:
- Uses `socket_io_client 3.1.4` with WebSocket-only transport
- JWT authentication via `Authorization: Bearer <token>` header
- Connection lifecycle: connect → handshake → stream → disconnect
- Reconnection logic: manual retry via UI button (automatic reconnection can be added)

### Stream-based Event Model
- `signStream`: emits `RecognitionResult` for each recognized sign
- `phraseStream`: emits `PhraseComplete` when phrase boundary detected
- `connectionStream`: broadcasts connection status changes

### Error Handling
- Connection failures surface via `_errorMessage` and UI retry button
- Socket errors logged to console (TODO: replace with proper logging service)
- Automatic disconnection on service dispose

## Client-Side Buffer Management

### BufferManager Implementation
Located at `lib/services/buffer_manager.dart`:
- **Window Size:** 30 frames (matches server configuration)
- **Feature Extraction:** **201-dimensional vector** (67 landmarks × 3D coordinates = 25 upper body pose + 21 left hand + 21 right hand)
- **Sliding Window:** Continuous recognition; each new frame after buffer fills emits a sign
- **Phrase Detection:** 2.5-second timeout after last sign triggers phrase completion
- **State:** Maintains phrase buffer for accumulating signs before TTS

### Stream Contract
- `signStream`: broadcasts `RecognitionResult` when window completes
- `phraseStream`: broadcasts `PhraseComplete` after inactivity timeout
- `clear()`: resets all buffers and cancels timers

### Test Coverage
Unit tests cover:
- Buffer accumulation and emission thresholds
- Phrase timeout detection and reset
- Clear operation
- Stream event ordering

## Split-View UI Layout

### RecognitionScreen Structure
```
Row(
  children: [
    Expanded(child: CameraPreviewWithMediaPipe(...)), // Left 50%
    VerticalDivider(),
    Expanded(child: TextPanel(...)), // Right 50%
  ],
)
```

### TextPanel Features
- Displays accumulated signs as editable text fields
- Confidence indicator (colored dot: green ≥80%, orange ≥60%, red <60%)
- Phrase complete banner with optional audio playback button
- Supports inline editing with tap-to-edit (basic implementation)

### Bottom Controls
- Camera toggle button (front/rear)
- Connection status indicator (green/red)
- Clear phrase button

## Authentication Integration

### Current Approach
- JWT token passed to `SignRecognitionService` constructor
- Token sent via Socket.io connection `extraHeaders`
- TODO: Integrate with Phase 1 auth service to obtain real token

### Route Guard
- Route `/recognition` added to app router
- No guard currently implemented; will integrate with Phase 1 session management

## Device Compatibility Considerations

### Permissions
- Android: Camera permission declared in `AndroidManifest.xml` (TODO: verify manifest)
- iOS: Camera permission required in `Info.plist` (TODO: add `NSCameraUsageDescription`)

### Performance
- 15 FPS target provides balance between responsiveness and CPU/GPU load
- Mock landmarks currently simulate ~1ms processing; real MediaPipe will add ~15-30ms per frame on GPU
- Memory: Camera buffers released on widget dispose

### Known Limitations
1. **MediaPipe integration incomplete** - awaiting package API verification
2. **No hand skeleton overlay** - per D-20, clean preview shown instead
3. **Mock landmarks** - not real sign recognition until MediaPipe integrated
4. **Audio playback not implemented** - TTS audio from backend not yet played

## Testing

### Unit Tests (All Passing)
- `test/services/buffer_manager_test.dart` - 9 tests
- `test/services/sign_recognition_service_test.dart` - 8 tests
- `test/widgets/text_panel_test.dart` - 7 tests

### Widget Tests
- `TextPanel` rendering and state changes
- Confidence indicator colors
- Phrase complete banner visibility

### Manual Testing (Pending)
The checkpoint at the end of Wave 3 is designated for user manual testing on physical device. Expected verification:
1. Camera opens with permission flow
2. Landmarks stream to server (mock → real pipeline)
3. Recognized signs appear in text panel
4. TTS audio plays after phrase completion (backend-dependent)
5. Camera toggle works smoothly
6. Latency <1 second (measured end-to-end)

## Dependencies Added

| Package | Version | Purpose |
|---------|---------|---------|
| `flutter_mediapipe` | 0.0.7 | Hand landmark detection |
| `socket_io_client` | 3.1.4 | Socket.io WebSocket client |
| `camera` | 0.12.0+1 | Camera access and preview |
| `permission_handler` | 12.0.1 | Runtime permission requests |
| `json_annotation` | 4.11.0 | JSON serialization |

## File Changes Summary

```
mobile/
├── lib/
│   ├── main.dart                         # App entry, routing
│   ├── models/
│   │   ├── landmark.dart                 # Landmark, HandLandmarks, LandmarksPayload
│   │   ├── landmark.g.dart               # Generated serialization
│   │   ├── recognition_event.dart        # RecognitionResult, PhraseComplete
│   │   └── recognition_event.g.dart      # Generated serialization
│   ├── services/
│   │   ├── buffer_manager.dart          # Client-side sliding window
│   │   └── sign_recognition_service.dart # Socket.io client
│   ├── widgets/
│   │   ├── camera_preview.dart          # Camera + MediaPipe integration
│   │   └── text_panel.dart              # Recognized signs display
│   └── screens/
│       └── recognition_screen.dart      # Main recognition UI
├── test/
│   ├── services/
│   │   ├── buffer_manager_test.dart
│   │   └── sign_recognition_service_test.dart
│   └── widgets/
│       └── text_panel_test.dart
└── pubspec.yaml                          # Dependencies updated
```

## Next Steps

1. **Physical device testing** - verify camera, MediaPipe, and Socket.io on actual Android/iOS device
2. **Integrate real MediaPipe** - replace mock landmarks with actual `HandLandmarker.process()` call
3. **Audio playback** - implement base64 audio decoding and playback for phrase complete
4. **Authentication wiring** - connect to Phase 1 auth service for JWT token
5. **Error UX** - improve error messages and recovery flows
6. **Performance optimization** - measure actual latency; tune FPS and resolution if needed

---

**Phase 2 Wave 3 Deliverable Status:** ✅ Complete (architecture implemented, tests passing, UI functional with mock data)
