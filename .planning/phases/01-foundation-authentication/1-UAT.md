---
status: testing
phase: 01-foundation-authentication
source: [01-00-SUMMARY.md, 01-01-SUMMARY.md, 01-02-SUMMARY.md, 01-03-SUMMARY.md, 01-04-SUMMARY.md, 01-05-SUMMARY.md, 01-06-SUMMARY.md]
started: 2026-05-07T00:00:00.000Z
updated: 2026-05-07T00:00:00.000Z
---

## Current Test

<!-- OVERWRITE each test - shows where we are -->

number: 1
name: Cold Start Smoke Test
expected: |
  Kill any running server/service. Clear ephemeral state (temp DBs, caches, lock files). Start the application from scratch. Server boots without errors, any seed/migration completes, and a primary query (health check, homepage load, or basic API call) returns live data.
awaiting: user response

## Tests

### 1. Cold Start Smoke Test
expected: Kill any running server/service. Clear ephemeral state (temp DBs, caches, lock files). Start the application from scratch. Server boots without errors, any seed/migration completes, and a primary query (health check, homepage load, or basic API call) returns live data.
result: [pending]

### 2. User Registration
expected: Navigate to the registration page or API endpoint. Submit a form with valid email, password, name, and userType. Receive a success response (201) with user data (without password). A new user is created in the database with hashed password.
result: [pending]

### 3. User Login (Email/Password)
expected: Submit login form with valid registered email and password. Receive success response with access and refresh tokens set as httpOnly cookies. The tokens are valid JWTs with correct user claims (userId, email, userType).
result: [pending]

### 4. JWT Token Structure and Expiry
expected: After login, decode the access token (15-min expiry) and refresh token (7-day expiry). Verify both contain userId, email, and userType claims. Access token expires in 15 minutes, refresh token in 7 days.
result: [pending]

### 5. Refresh Token Rotation
expected: Call POST /api/auth/refresh with a valid refresh token cookie. Receive new access and refresh tokens. The old refresh token is invalidated in the database (updated record). New tokens are valid JWTs.
result: [pending]

### 6. Protected Profile Endpoint (GET)
expected: Call GET /api/user/profile with valid access token cookie. Receive 200 with user data (id, email, name, userType, emergencyContacts, createdAt). Password is not returned. Invalid or missing token returns 401.
result: [pending]

### 7. Profile Update (PUT)
expected: Call PUT /api/user/profile with valid access token and JSON body { name?: string, userType?: "DEAF" | "HEARING" | "PARENT" | "TEACHER" }. Only provided fields are updated. Returns updated user with emergency contacts.
result: [pending]

### 8. STT Endpoint with Cloud Provider
expected: Call POST /api/stt/transcribe with audio file (multipart form data). Primary provider (Groq Whisper) processes the audio and returns Vietnamese transcription text. Response status 200 with transcription field.
result: [pending]

### 9. STT Fallback to Local Provider
expected: When the primary STT provider (Groq) fails, the endpoint automatically falls back to the local provider (whisper.cpp). A successful transcription is still returned. Error is logged but user receives valid response.
result: [pending]

### 10. TTS Endpoint with Cloud Provider
expected: Call POST /api/tts/synthesize with JSON body { text: "Xin chào", language?: "vi" }. Primary provider (ElevenLabs) processes and returns audio stream (audio/mpeg or audio/wav). Response status 200 with audio data.
result: [pending]

### 11. TTS Fallback to Local Provider
expected: When the primary TTS provider (ElevenLabs) fails, the endpoint automatically falls back to the local provider (Coqui TTS). Audio is still returned. Error is logged but user receives valid audio response.
result: [pending]

### 12. Real-time Notification Registration
expected: Connect to Socket.io server. Emit 'register' event with userId and userType. Server acknowledges and maps socket to user. Disconnecting removes the socket mapping.
result: [pending]

### 13. In-App Notification Delivery
expected: With two connected clients (sender and receiver), sender calls POST /api/notifications/send with { toUserId, title, body, type }. Receiver gets real-time notification via Socket.io event (io.to user room). Notification is also stored in database.
result: [pending]

### 14. SOS Alert with Visual Config
expected: Emit 'sos:alert' event via Socket.io with alert data. Receiving client gets notification with high-priority visualConfig (red color, pulse animation, custom vibration pattern for deaf users). Alert is stored for offline persistence.
result: [pending]

### 15. Health Check Endpoint
expected: Call GET /api/health. Response returns JSON with status: "ok" or "degraded", timestamp in ISO format, and services object checking api, database, redis, livekit status. Returns 200 when healthy, 503 when degraded.
result: [pending]

### 16. Google OAuth Login (Skipped - Out of Scope)
expected: Google OAuth endpoints exist (GET /api/auth/google redirects to Google, POST /api/auth/google handles callback). Tests are skipped per CONTEXT.md decision to defer OAuth to later phase.
result: [pending]

## Summary

total: 16
passed: 0
issues: 0
pending: 16
skipped: 0

## Gaps

[none yet]
