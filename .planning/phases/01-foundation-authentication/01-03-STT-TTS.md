---
phase: 01-foundation-authentication
plan: 03
type: execute
wave: 3
depends_on:
  - 01
  - 02
files_modified:
  - src/config/stt.ts
  - src/config/tts.ts
  - src/services/stt.service.ts
  - src/services/tts.service.ts
  - src/routes/stt.routes.ts
  - src/routes/tts.routes.ts
  - .env.example
autonomous: true
requirements:
  - COMM-02
  - COMM-03
must_haves:
  truths:
    - "STT endpoint accepts audio buffer and returns Vietnamese text"
    - "TTS endpoint accepts text and returns audio buffer"
    - "Groq Whisper is used as primary STT provider"
    - "Whisper.cpp is used as fallback STT when Groq fails"
    - "ElevenLabs is used as primary TTS provider"
    - "Coqui TTS is used as fallback TTS when ElevenLabs fails"
    - "Vietnamese language code 'vi' is explicitly specified to all providers"
    - "Provider health checks work and report status"
    - "Strategy pattern correctly falls back on primary provider failure"
  artifacts:
    - path: "src/config/stt.ts"
      provides: "STT provider abstraction with Groq and Whisper.cpp implementations"
      exports:
        - "interface STTProvider"
        - "class GroqSTT"
        - "class WhisperCppSTT"
        - "class STTManager"
    - path: "src/config/tts.ts"
      provides: "TTS provider abstraction with ElevenLabs and Coqui implementations"
      exports:
        - "interface TTSProvider"
        - "class ElevenLabsTTS"
        - "class CoquiTTS"
        - "class TTSManager"
    - path: "src/routes/stt.routes.ts"
      provides: "POST /api/v1/stt/transcribe endpoint"
    - path: "src/routes/tts.routes.ts"
      provides: "POST /api/v1/tts/synthesize endpoint"
  key_links:
    - from: "src/routes/stt.routes.ts"
      to: "src/config/stt.ts"
      via: "sttManager.transcribe()"
    - from: "src/routes/tts.routes.ts"
      to: "src/config/tts.ts"
      via: "ttsManager.synthesize()"
---

<objective>
STT/TTS Services with Strategy Pattern

Purpose: Implement Vietnamese speech-to-text and text-to-speech using hybrid strategy pattern: Groq Whisper + Whisper.cpp fallback for STT; ElevenLabs + Coqui TTS fallback for TTS. Both explicitly use Vietnamese language codes and achieve <500ms latency.

Output: STT and TTS services with provider abstraction, API endpoints, and automatic fallback
</objective>

<execution_context>
@$HOME/.claude/get-shit-done/workflows/execute-plan.md
@$HOME/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-foundation-authentication/01-CONTEXT.md
@.planning/phases/01-foundation-authentication/01-RESEARCH.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Implement STT strategy pattern (Groq + Whisper.cpp)</name>
  <files>src/config/stt.ts</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Create STT provider abstraction with Vietnamese language='vi':

export interface STTProvider {
  transcribe(audio: Buffer, language?: string): Promise<string>;
  healthCheck(): Promise<boolean>;
}

export class GroqSTT implements STTProvider {
  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    const { Groq } = await import('@groq/sdk');
    const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
    const result = await groq.audio.transcriptions.create({
      file: audio,
      model: 'whisper-large-v3',
      language: language,
      response_format: 'json',
      temperature: 0.0,
    });
    return result.text;
  }

  async healthCheck(): Promise<boolean> {
    try {
      const { Groq } = await import('@groq/sdk');
      const groq = new Groq({ apiKey: process.env.GROQ_API_KEY });
      await groq.audio.transcriptions.create({
        file: new TextEncoder().encode('test'),
        model: 'whisper-large-v3',
        language: 'vi',
      });
      return true;
    } catch { return false; }
  }
}

export class WhisperCppSTT implements STTProvider {
  private endpoint: string;
  constructor() {
    this.endpoint = process.env.STT_FALLBACK_URL || 'http://localhost:8081/transcribe';
  }
  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    const response = await fetch(this.endpoint, {
      method: 'POST',
      body: audio,
      headers: { 'Content-Type': 'audio/wav' },
    });
    const { text } = await response.json();
    return text;
  }
  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.endpoint.replace('/transcribe', '')}/health`);
      return response.ok;
    } catch { return false; }
  }
}

export class STTManager {
  private primary: STTProvider;
  private fallback?: STTProvider;

  constructor() {
    this.primary = new GroqSTT();
    if (process.env.STT_PROVIDER === 'local' || process.env.STT_FALLBACK_URL) {
      this.fallback = new WhisperCppSTT();
    }
  }

  async transcribe(audio: Buffer, language = 'vi'): Promise<string> {
    try {
      if (await this.primary.healthCheck()) {
        return await this.primary.transcribe(audio, language);
      }
      if (this.fallback) {
        return await this.fallback.transcribe(audio, language);
      }
      throw new Error('No STT providers available');
    } catch (err) {
      if (this.fallback && !(err instanceof Error && err.message.includes('health'))) {
        return await this.fallback.transcribe(audio, language);
      }
      throw err;
    }
  }
}

export const sttManager = new STTManager();</action>
  <verify>
  - src/config/stt.ts exists
  - grep -q "interface STTProvider" src/config/stt.ts
  - grep -q "class GroqSTT" src/config/stt.ts
  - grep -q "class WhisperCppSTT" src/config/stt.ts
  - grep -q "language.*=.*'vi'" src/config/stt.ts
  - grep -q "whisper-large-v3" src/config/stt.ts
  - grep -q "class STTManager" src/config/stt.ts
  - grep -q "sttManager = new" src/config/stt.ts
  - TypeScript compiles
  </verify>
  <done>STT strategy pattern implemented with Groq primary and Whisper.cpp fallback, both using Vietnamese</done>
</task>

<task type="auto">
  <name>Task 2: Implement TTS strategy pattern (ElevenLabs + Coqui)</name>
  <files>src/config/tts.ts</files>
  <read_first>
  - .planning/phases/01-foundation-authentication/01-RESEARCH.md
  </read_first>
  <action>Create TTS provider abstraction:

export interface TTSProvider {
  synthesize(text: string, language?: string): Promise<Buffer>;
  healthCheck(): Promise<boolean>;
}

export class ElevenLabsTTS implements TTSProvider {
  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    const { ElevenLabs } = await import('elevenlabs');
    const client = new ElevenLabs({ apiKey: process.env.ELEVENLABS_API_KEY });

    const audio = await client.textToSpeech.convert(
      process.env.ELEVENLABS_VOICE_ID || '21m00Tcm4TlvDq8ikWAM',
      { text, modelId: 'eleven_multilingual_v2' }
    );

    return Buffer.from(await audio.arrayBuffer());
  }

  async healthCheck(): Promise<boolean> {
    try {
      const { ElevenLabs } = await import('elevenlabs');
      const client = new ElevenLabs({ apiKey: process.env.ELEVENLABS_API_KEY });
      const voices = await client.voices.getAll();
      return voices.voices.length > 0;
    } catch { return false; }
  }
}

export class CoquiTTS implements TTSProvider {
  private endpoint: string;
  constructor() {
    this.endpoint = process.env.TTS_FALLBACK_URL || 'http://localhost:5002/api/tts';
  }
  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    const response = await fetch(this.endpoint, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text, language }),
    });
    if (!response.ok) throw new Error(`Coqui TTS failed: ${response.statusText}`);
    return Buffer.from(await response.arrayBuffer());
  }
  async healthCheck(): Promise<boolean> {
    try {
      const response = await fetch(`${this.endpoint.replace('/api/tts', '')}/health`);
      return response.ok;
    } catch { return false; }
  }
}

export class TTSManager {
  private primary: TTSProvider;
  private fallback?: TTSProvider;

  constructor() {
    this.primary = new ElevenLabsTTS();
    if (process.env.TTS_PROVIDER === 'local' || process.env.TTS_FALLBACK_URL) {
      this.fallback = new CoquiTTS();
    }
  }

  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    try {
      if (await this.primary.healthCheck()) {
        return await this.primary.synthesize(text, language);
      }
      if (this.fallback) {
        return await this.fallback.synthesize(text, language);
      }
      throw new Error('No TTS providers available');
    } catch (err) {
      if (this.fallback && !(err instanceof Error && err.message.includes('health'))) {
        return await this.fallback.synthesize(text, language);
      }
      throw err;
    }
  }
}

export const ttsManager = new TTSManager();</action>
  <verify>
  - src/config/tts.ts exists
  - grep -q "interface TTSProvider" src/config/tts.ts
  - grep -q "class ElevenLabsTTS" src/config/tts.ts
  - grep -q "class CoquiTTS" src/config/tts.ts
  - grep -q "eleven_multilingual_v2" src/config/tts.ts
  - grep -q "class TTSManager" src/config/tts.ts
  - grep -q "ttsManager = new" src/config/tts.ts
  - TypeScript compiles
  </verify>
  <done>TTS strategy pattern implemented with ElevenLabs primary and Coqui fallback, both using Vietnamese</done>
</task>

<task type="auto">
  <name>Task 3: Create STT and TTS routes</name>
  <files>
  src/routes/stt.routes.ts
  src/routes/tts.routes.ts
  </files>
  <read_first>
  - src/config/stt.ts
  - src/config/tts.ts
  </read_first>
  <action>Create src/routes/stt.routes.ts:

import { Router } from 'express';
import { sttManager } from '../config/stt.js';

const router = Router();

router.post('/transcribe', async (req, res) => {
  const { audio, language = 'vi' } = req.body;
  if (!audio) return res.status(400).json({ error: 'Audio required' });
  try {
    const audioBuffer = Buffer.from(audio, 'base64');
    const text = await sttManager.transcribe(audioBuffer, language);
    res.json({ text, language });
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;

Create src/routes/tts.routes.ts:

import { Router } from 'express';
import { ttsManager } from '../config/tts.js';

const router = Router();

router.post('/synthesize', async (req, res) => {
  const { text, language = 'vi' } = req.body;
  if (!text) return res.status(400).json({ error: 'Text required' });
  try {
    const audio = await ttsManager.synthesize(text, language);
    res.contentType('audio/wav');
    res.send(audio);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

export default router;</action>
  <verify>
  - src/routes/stt.routes.ts exists
  - grep -q "router.post('/transcribe'" src/routes/stt.routes.ts
  - grep -q "sttManager.transcribe" src/routes/stt.routes.ts
  - src/routes/tts.routes.ts exists
  - grep -q "router.post('/synthesize'" src/routes/tts.routes.ts
  - grep -q "ttsManager.synthesize" src/routes/tts.routes.ts
  - grep -q "audio/wav" src/routes/tts.routes.ts
  - TypeScript compiles
  </verify>
  <done>STT and TTS endpoints implemented with proper error handling and audio response</done>
</task>

</tasks>
