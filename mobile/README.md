# VSL Bridge - Flutter Mobile App

Vietnamese Sign Language (VSL) Bridge mobile application for real-time two-way communication between deaf and hearing people.

## Features

- **Real-time Sign Recognition**: Uses MediaPipe HandLandmarker to detect hand gestures
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
The app automatically requests camera permission at runtime. No additional setup needed.

#### iOS
The `Info.plist` includes `NSCameraUsageDescription` for camera access.

### 4. Add MediaPipe Model

Download the hand landmarker model:

1. Download from: https://storage.googleapis.com/mediapipe-models/hand_landmarker/hand_landmarker/float16/1/hand_landmarker.task
2. Place the file in `mobile/assets/hand_landmarker.task`
3. The model file is referenced in `pubspec.yaml`

**Note:** The model file is NOT included in the repository due to size. You must download it separately.

### 5. Generate Code

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
│   │   ├── landmark.dart         # Hand landmark data models
│   │   ├── landmark.g.dart       # Generated JSON serialization
│   │   ├── recognition_event.dart
│   │   └── recognition_event.g.dart
│   ├── screens/
│   │   └── recognition_screen.dart  # Main recognition UI
│   ├── services/
│   │   ├── buffer_manager.dart       # Client-side sliding window
│   │   └── sign_recognition_service.dart  # Socket.io connection
│   ├── widgets/
│   │   ├── camera_preview.dart       # Camera + MediaPipe integration
│   │   └── text_panel.dart           # Recognized signs display
│   └── main.dart                     # App entry point
├── assets/
│   └── hand_landmarker.task      # MediaPipe model (download separately)
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
   - Processes frames through MediaPipe HandLandmarker
   - Emits normalized landmark data (21 points per hand)

2. **Feature Extraction** (`BufferManager`)
   - Accumulates frames into sliding window (default 30 frames)
   - Extracts 126-dimensional feature vector (x,y,z for 21 landmarks per hand)
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
Camera → MediaPipe → LandmarksPayload → BufferManager → SignRecognitionService
                                                              ↓
                                                      Recognition Results
                                                              ↓
                                                      TextPanel + Audio
```

## Adding the Real VSL Model

The current implementation uses **mock landmarks** for architecture demonstration. To enable real VSL recognition:

1. **Download the MediaPipe model** (see Setup step 4)

2. **Uncomment MediaPipe code** in `lib/widgets/camera_preview.dart`:

   ```dart
   // In _initializeHandLandmarker() and _processFrame(), uncomment the MediaPipe code
   ```

3. **Update the backend** (`recognition-service/`) to use the actual VSL classification model

4. **Test the pipeline**:

   ```bash
   flutter run --verbose
   ```

   Check logs for:
   - `MediaPipe HandLandmarker initialized successfully`
   - Landmark coordinates being emitted
   - Recognition results appearing in the text panel

## Debugging

### View Latency Metrics

Latency measurements are logged to console in debug mode:

```
[Latency] Current processing delay: Xms, Average: Yms
[Latency WARNING] Processing latency Zms exceeds 1000ms threshold!
```

### Enable Verbose Logging

```bash
flutter run --verbose
```

### Common Issues

| Issue | Solution |
|-------|----------|
| Camera not initializing | Check camera permissions in Android/iOS settings |
| No landmarks detected | Ensure adequate lighting, hand visible to camera |
| Connection refused | Verify backend server is running at configured URL/port |
| Model not loading | Confirm `assets/hand_landmarker.task` exists |
| High latency (>1s) | Reduce `targetFps`, ensure backend has GPU support |

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
| flutter_mediapipe | ^0.0.7 | Hand landmark detection |
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

### iOS

- Minimum iOS version: 12.0
- Camera permission must be in Info.plist (included)
- GPU delegate for MediaPipe automatically used on A12+ devices

## License

[To be determined - will match project license]

## Contributing

[Project contribution guidelines will be added]
