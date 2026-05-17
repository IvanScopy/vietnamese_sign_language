---
phase: 01-foundation-authentication
plan: 03
subsystem: STT/TTS Provider Abstraction
tags: [stt, tts, provider-pattern, groq, elevenlabs, whisper.cpp, coqui]
requires: [01-01]
provides: [COMM-02, COMM-03]
affects: [src/app/lib/providers/, src/app/api/stt/, src/app/api/tts/]
tech-stack:
  added:
    - "FormData API (built-in) for multipart file uploads"
    - "fetch API (built-in) for HTTP requests to cloud/local providers"
  patterns:
    - "Strategy Pattern for STT/TTS provider abstraction"
    - "Environment-based provider selection (STT_PROVIDER, TTS_PROVIDER)"
    - "Cloud-to-local fallback on provider failure"
key-files:
  created:
    - path: "src/app/lib/providers/stt-provider.ts"
      description: "STT provider interface and factory function"
    - path: "src/app/lib/providers/groq-stt.ts"
      description: "Groq Whisper API implementation (cloud primary)"
    - path: "src/app/lib/providers/whisper-cpp-stt.ts"
      description: "whisper.cpp local server implementation (fallback)"
    - path: "src/app/lib/providers/tts-provider.ts"
      description: "TTS provider interface and factory function"
    - path: "src/app/lib/providers/elevenlabs-tts.ts"
      description: "ElevenLabs TTS API implementation (cloud primary)"
    - path: "src/app/lib/providers/coqui-tts.ts"
      description: "Coqui TTS local server implementation (fallback)"
    - path: "src/app/lib/validators.ts"
      description: "Zod validation schemas for STT/TTS API inputs"
    - path: "src/app/api/stt/transcribe/route.ts"
      description: "STT API endpoint with cloud-to-local fallback"
    - path: "src/app/api/tts/synthesize/route.ts"
      description: "TTS API endpoint with cloud-to-local fallback"
  modified: []
decisions:
  - id: "01-03-01"
    decision: "Use Strategy Pattern for STT/TTS provider abstraction"
    rationale: "Allows swapping between cloud and local providers via environment variables without code changes"
    alternatives: ["Direct API calls without abstraction", "Configuration-based provider selection without interface"]
  - id: "01-03-02"
    decision: "Groq Whisper as primary STT provider, whisper.cpp as fallback"
    rationale: "Groq offers <500ms latency for Vietnamese via whisper-large-v3-turbo; whisper.cpp provides self-hosted fallback"
    alternatives: ["Vosk (offline only)", "Faster Whisper (Python-based)"]
  - id: "01-03-03"
    decision: "ElevenLabs as primary TTS provider, Coqui TTS as fallback"
    rationale: "ElevenLabs multilingual v2 model supports Vietnamese with high quality; Coqui TTS provides self-hosted fallback"
    alternatives: ["Google TTS", "Piper TTS", "VieNeu-TTS (not yet available)"]
  - id: "01-03-04"
    decision: "Implement cloud-to-local fallback in API endpoints rather than provider layer"
    rationale: "Allows API endpoints to catch provider failures and try fallback; simpler than building fallback into each provider"
    alternatives: ["Build fallback into provider factory", "Use circuit breaker pattern"]
metrics:
  duration: "30 minutes"
  completed_date: "2026-05-06"
  tasks_completed: 3
  files_created: 9
  files_modified: 0
---

# Phase 01 Plan 03: STT/TTS Provider Abstraction Summary

**One-liner:** Strategy pattern implementation for Vietnamese speech-to-text (Groq Whisper) and text-to-speech (ElevenLabs) with self-hosted whisper.cpp and Coqui TTS fallbacks.

## Objective

Implement STT (Speech-to-Text) and TTS (Text-to-Speech) provider abstraction with strategy pattern. Cloud primary (Groq Whisper for STT, ElevenLabs for TTS) with self-hosted fallback (whisper.cpp, Coqui TTS).

## Tasks Completed

| Task | Name | Commit | Files |
| ---- | ----- | ------ | ----- |
| 1 | Create STT provider abstraction and implementations | 8c63ae6 | stt-provider.ts, groq-stt.ts, whisper-cpp-stt.ts |
| 2 | Create TTS provider abstraction and implementations | c38877f | tts-provider.ts, elevenlabs-tts.ts, coqui-tts.ts |
| 3 | Implement STT and TTS API endpoints | 24902fc | validators.ts, stt/transcribe/route.ts, tts/synthesize/route.ts |

## Success Criteria Verification

- [x] STT provider interface with transcribe method; implementations for Groq Whisper and whisper.cpp
- [x] TTS provider interface with synthesize method; implementations for ElevenLabs and Coqui TTS
- [x] Provider selection via STT_PROVIDER and TTS_PROVIDER environment variables
- [x] STT endpoint accepts audio file, returns Vietnamese transcription
- [x] TTS endpoint accepts text, returns audio stream
- [x] Automatic fallback from cloud to local provider on failure
- [x] VieNeu-TTS noted as future option (not yet implemented per CONTEXT.md)
- [x] All provider files in src/app/lib/providers/ per RESEARCH.md Architectural Responsibility Map

## Deviations from Plan

### Auto-fixed Issues

None - plan executed exactly as written.

### Auth Gates

None encountered during execution.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: input_validation | src/app/api/stt/transcribe/route.ts | Audio file upload endpoint - verify file size limits via Next.js config |
| threat_flag: input_validation | src/app/api/tts/synthesize/route.ts | Text input endpoint - verify text length limits (reject >5000 chars per T-01-12) |
| threat_flag: api_keys | src/app/lib/providers/groq-stt.ts, elevenlabs-tts.ts | API keys stored in env vars - ensure .env is gitignored |
| threat_flag: fallback_logging | src/app/api/stt/transcribe/route.ts, tts/synthesize/route.ts | Fallback logic logs errors - ensure no API keys in logs |

## Known Stubs

None identified. All implementations are functional with proper error handling and fallback logic.

## Self-Check: PASSED

- [x] All 9 files exist in correct locations
- [x] All 3 commits exist with proper format (feat(01-03): ...)
- [x] Commit 8c63ae6: STT provider abstraction
- [x] Commit c38877f: TTS provider abstraction
- [x] Commit 24902fc: STT/TTS API endpoints
- [x] No unexpected file deletions in commits
- [x] All provider files in src/app/lib/providers/ per Architectural Responsibility Map
