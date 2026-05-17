# VSL Bridge - Flutter Mobile App

Vietnamese Sign Language (VSL) Bridge mobile application for real-time two-way communication between deaf and hearing people.

## Features

- **Real-time Sign Recognition**: Uses MediaPipe Holistic to detect 67 landmarks (pose + both hands)
- **Server-based Classification**: Streams landmarks to backend for VSL classification
- **Text Display**: Shows recognized signs in an editable text panel
- **Audio Playback**: Plays TTS audio for completed phrases
- **Camera Toggle**: Switch between front and rear cameras

## Prerequisites

- Flutter SDK 3.11.5 or later
- Android Studio (for Android development) or Xcode (for iOS)
- Android emulator or physical device for testing

## Setup Instructions

### 1. Install Flutter

Follow the official Flutter installation guide: https://docs.flutter.dev/get-started/install

Verify installation:
```bash
flutter doctor
```

### 2. Clone and Dependencies

```bash
cd mobile
flutter pub get
```

### 3. Permissions

#### Android
The app automatically requests camera permission at runtime. The AndroidManifest.xml includes the required permissions.

#### iOS
The `Info.plist` includes `NSCameraUsageDescription` for camera access.

### 4. Generate Code

```bash
cd mobile
flutter pub run build_runner build
```

## Running the App

### Development Mode

```bash
cd mobile
flutter run
```

### Emulator Testing

#### Android Emulator

- The app is configured to use `10.0.2.2` as the default server URL for the Android emulator
- This special IP addresses the host machine's localhost from the emulator
- The backend server must be running on `localhost:8000`

```bash
# Terminal 1: Start the backend recognition service
cd recognition-service
# Follow the README in that directory to start the server

# Terminal 2: Run the Flutter app
cd mobile
flutter run
```

#### iOS Simulator

- For iOS simulator, use `localhost` or `127.0.0.1` as the server URL
- Update the configuration in `main.dart` or set environment variable:
  ```bash
  VSL_SERVER_URL=localhost flutter run
  ```

### Physical Device

For physical device testing:

1. Connect your device to the same network as the backend server
2. Find your computer's LAN IP address (e.g., `192.168.1.100`)
3. Run with:
   ```bash
   VSL_SERVER_URL=192.168.1.100 flutter run
   ```

## Environment Configuration

The app supports configuration via environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `VSL_SERVER_URL` | Recognition service host | `10.0.2.2` (dev) |
| `VSL_SERVER_PORT` | Recognition service port | `8000` |
| `VSL_ENV` | Environment: dev/staging/prod | `dev` |
| `VSL_USE_MOCK` | Use mock landmarks instead of MediaPipe | `false` |
| `VSL_USE_HOLISTIC` | Use full Holistic (pose+hands) vs hands-only | `true` |

### Environment-specific defaults

- **dev**: `10.0.2.2:8000` (Android emulator)
- **staging**: `staging-api.vsl-bridge.com:443`
- **prod**: `api.vsl-bridge.com:443`

## Project Structure

```
mobile/
├── lib/
│   ├── config/
│   │   └── app_config.dart       # Environment configuration
│   ├── models/
│   │   ├── landmark.dart         # Landmark data models (Landmark, HandLandmarks, PoseLandmarks, HolisticLandmarksPayload)
│   │   ├── landmark.g.dart       # Generated JSON serialization
│   │   └── ...
│   ├── screens/
│   │   └── recognition_screen.dart  # Main recognition UI
│   ├── services/
│   │   ├── buffer_manager.dart       # Client-side sliding window
│   │   └── sign_recognition_service.dart  # Socket.io connection
│   ├── widgets/
│   │   ├── camera_preview.dart       # Camera + MediaPipe Holistic integration (native Android plugin)
│   │   └── text_panel.dart           # Recognized signs display
│   └── main.dart                     # App entry point
├── android/
│   ├── app/
│   │   ├── build.gradle.kts          # Android build config with MediaPipe dependencies
│   │   └── src/main/
│   │       ├── AndroidManifest.xml   # Permissions (camera, internet)
│   │       ├── kotlin/co/vslbridge/  # Native plugin source
│   │       │   ├── MainActivity.kt
│   │       │   └── MediaPipeHolisticPlugin.kt
│   │       └── consumer-rules.pro    # ProGuard rules for MediaPipe
│   └── ...
├── test/
│   ├── services/
│   │   ├── buffer_manager_test.dart
│   │   └── sign_recognition_service_test.dart
│   └── widgets/
│       ├── camera_preview_test.dart
│       └── text_panel_test.dart
├── pubspec.yaml
└── README.md
```

## Architecture

### Recognition Pipeline

1. **Camera Frame Capture** (`CameraPreviewWithMediaPipe`)
   - Captures YUV frames at configurable FPS (default 15)
   - Sends frames to native Android MediaPipe Holistic plugin via MethodChannel
   - Receives holistic landmarks via EventChannel (67 total landmarks)

2. **Feature Extraction** (`BufferManager`)
   - Accumulates frames into sliding window (default 30 frames)
   - Extracts 201-dimensional feature vector (67 landmarks × 3D coordinates)
   - Emits sign events when window is full

3. **Server Communication** (`SignRecognitionService`)
   - Streams landmarks via Socket.io with JWT authentication
   - Receives recognition results and phrase completion events
   - Handles connection lifecycle and reconnection

4. **UI Updates** (`RecognitionScreen`)
   - Displays recognized signs in editable text panel
   - Shows connection status
   - Plays TTS audio on phrase completion

### Data Flow

```
Camera → Native MediaPipe Holistic → HolisticLandmarksPayload → BufferManager → SignRecognitionService
                                                                                ↓
                                                                        Recognition Results
                                                                                ↓
                                                                        TextPanel + Audio
```

### Feature Vector Format (201 dimensions)

```
[pose25×3, left_hand21×3, right_hand21×3]
  75       63             63          = 201
```

## Android Setup Requirements

### MediaPipe Dependencies

The Android build includes MediaPipe Holistic via Maven:

```kotlin
// android/app/build.gradle.kts
dependencies {
    implementation("com.google.mediapipe:holistic:0.10.14")
    implementation("com.google.mediapipe:solution_utils:0.1.0")
}
```

### Native Plugin

The `MediaPipeHolisticPlugin.kt` provides:
- MethodChannel for initialization and frame processing
- EventChannel for streaming landmark results
- GPU-accelerated inference via MediaPipe

### Build Considerations

- **APK Size**: MediaPipe adds ~15-20MB to the APK
- **Memory**: Holistic model uses ~100-150MB RAM during processing
- **GPU**: Enable GPU delegate for best performance (enabled by default)
- **ProGuard**: Consumer rules included to preserve MediaPipe classes

## Testing

Run unit tests:

```bash
cd mobile
flutter test
```

Run with coverage:

```bash
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html
```

### Test Coverage

- `buffer_manager_test.dart`: Sliding window logic, phrase timeout
- `sign_recognition_service_test.dart`: Socket.io connection, message parsing
- `text_panel_test.dart`: UI rendering, audio playback
- `camera_preview_test.dart`: Camera widget, config handling

## Backend Service

The mobile app requires the VSL Bridge recognition service running. See the `recognition-service/` directory for:

- Socket.io server with WebSocket support
- Faster Whisper STT integration
- Piper TTS for Vietnamese audio
- JWT authentication

Start the backend:

```bash
cd recognition-service
# See README in that directory
```

## Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| flutter | ^3.11.5 | UI framework |
| camera | ^0.12.0+1 | Camera access |
| socket_io_client | ^3.1.4 | WebSocket communication |
| shared_preferences | ^2.3.3 | Token storage |
| audioplayers | ^6.4.0 | TTS audio playback |
| permission_handler | ^12.0.1 | Runtime permissions |
| json_annotation | ^4.11.0 | JSON serialization |

## Performance Targets

| Metric | Target | Measurement |
|--------|--------|-------------|
| Landmark detection FPS | 15 | `targetFps` config |
| Round-trip latency | <1000ms | Console logs |
| App startup time | <2s | Cold start |
| Memory usage | <200MB | Android Profiler |

## Platform-Specific Notes

### Android

- Minimum SDK: 21 (Android 5.0)
- Camera2 API used via camera plugin
- GPU acceleration for MediaPipe recommended
- MediaPipe Holistic delivered via AAR from Google Maven

### iOS

- **Status**: Not yet implemented (Phase 2B planned)
- Minimum iOS version will be 12.0
- Native iOS MediaPipe Holistic plugin needed

## Known Issues

| Issue | Workaround |
|-------|------------|
| Large APK size (~25MB) | Expected due to MediaPipe; use app bundles |
| High memory usage on low-end devices | Reduce `targetFps` in config |
| Front camera mirrored | Coordinate transformation needed |
| YUV→RGB conversion overhead | Consider native YUV processing in future |

## License

[To be determined - will match project license]

## Contributing

[Project contribution guidelines will be added]
