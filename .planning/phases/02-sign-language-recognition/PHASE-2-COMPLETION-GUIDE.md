# Phase 2 Completion Guide: Sign Language Recognition

## Current Status

**✅ Completed:**
- Wave 1 (02-01): Backend foundation - shared types, sliding window, mock LSTM, Docker
- Wave 2 (02-02 + 02-03): Socket.io API with JWT auth, TTS service (Piper + eSpeak)
- All 74 tests passing

**⏳ Pending:**
- Wave 3 (02-04): Flutter mobile client integration

**Blockers:**
- Flutter SDK not installed
- Flutter project not created

---

## Prerequisites for Wave 3

### 1. Install Flutter SDK

**Version:** Flutter 3.24.3 (stable) or 3.22.0 (LTS)

```bash
# Download Flutter Linux
cd ~
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.24.3-stable.tar.xz
tar xf flutter_linux_3.24.3-stable.tar.xz

# Add to PATH
export PATH="$HOME/flutter/bin:$PATH"
flutter doctor

# Accept licenses
flutter doctor --android-licenses
```

**Verify:** `flutter --version` should show 3.24.3+

### 2. Create Flutter Project

```bash
cd /home/ivan/vsl-final-5days
flutter create --org com.vsl --platforms ios,android mobile
```

This creates `mobile/` directory with Flutter project structure.

### 3. Install Flutter Dependencies

Update `mobile/pubspec.yaml` with required dependencies (see Phase 2 plan 02-04 for full list):
- flutter_mediapipe
- socket_io_client
- camera
- permission_handler
- riverpod
- go_router

Then run:
```bash
cd mobile
flutter pub get
```

---

## Continue Phase 2 Execution

Once Flutter is ready, run:

```bash
cd /home/ivan/vsl-final-5days
gsd-execute-phase 2 --wave 3
```

This will:
- Execute Plan 02-04 (Flutter integration)
- Add MediaPipe dependencies
- Implement CameraPreview, BufferManager, RecognitionScreen
- Wire up Socket.io client
- Create integration tests

---

## Manual Steps After Wave 3

### 1. Configure Backend URL

In mobile app settings, set recognition service URL:
```
ws://<your-server-ip>:8000/socket.io
```

### 2. Run Backend Services

```bash
cd /home/ivan/vsl-final-5days
docker compose up -d recognition  # Start Python recognition service
# Node.js API should already be running from Phase 1
```

### 3. Test on Physical Device

```bash
cd mobile
flutter run --release
```

- Grant camera permission
- Navigate to recognition screen
- Test sign gestures
- Verify end-to-end flow

---

## Troubleshooting

### Flutter not found after install
Add to `~/.zshrc` or `~/.bashrc`:
```bash
export PATH="$HOME/flutter/bin:$PATH"
```
Then `source ~/.zshrc`

### MediaPipe plugin errors
Ensure Flutter version >= 3.22.0 for Impeller support.

### Socket.io connection fails
- Check recognition service is running: `curl http://localhost:8000/health`
- Verify JWT token from auth flow
- Check firewall/network

### Camera not working
- Physical device required (not emulator)
- Check permissions in AndroidManifest.xml / Info.plist
- Run `flutter doctor` for missing dependencies

---

## Rollback & Recovery

If Wave 3 fails or needs rework:

```bash
# Reset to pre-wave-3 state
git checkout 02-01-02-03-completed

# Or create new branch for re-attempt
git checkout -b phase/02-sign-language-recognition-wave3-retry
```

All completed work (Wave 1 & 2) is committed and can be restored.

---

## Next Phases After Phase 2

- Phase 3: Face-to-Face Conversation & History
- Phase 4: Video Calling
- Phase 5: SOS Emergency & Safety
- Phase 6: App, Dictionary & Admin Readiness

Avatar signing is deferred to v2+ and should not be planned as Phase 3 work.

See ROADMAP.md for full timeline.

---

## Support & Resources

- GSD commands: `/gsd-help`
- Phase patterns: `.planning/phases/02-sign-language-recognition/02-*-PLAN.md`
- Backend code: `recognition-service/`
- Shared types: `shared/types/`
