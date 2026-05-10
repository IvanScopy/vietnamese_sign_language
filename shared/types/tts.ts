/**
 * Vietnamese Text-to-Speech (TTS) Type Definitions
 * Shared between frontend (TypeScript) and backend (Python via Pydantic)
 */

export interface TTSRequest {
  text: string;
  voice?: string;  // e.g., 'vivos' for Piper, 'vi' for eSpeak
  speed?: number;  // 0.8-1.2, default 1.0
}

export interface TTSResponse {
  audio: string;   // Base64 encoded audio data (WAV/PCM)
  format: 'wav' | 'pcm';
  sampleRate: number;  // e.g., 22050
  duration: number;    // in seconds
}

export interface TTSError {
  provider: string;
  message: string;
  fallbackAttempted?: boolean;
}

/**
 * Socket.io event payload for phrase_complete with TTS audio
 */
export interface PhraseCompleteEvent {
  text: string;
  signs: Array<{
    sign: string;
    confidence: number;
    timestamp: number;
  }>;
  audio?: string;  // Base64 encoded WAV audio, optional if TTS fails
}
