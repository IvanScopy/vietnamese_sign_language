export interface TTSProvider {
  synthesize(text: string, language?: string): Promise<Buffer>
}

export function getTTSProvider(): TTSProvider {
  const provider = process.env.TTS_PROVIDER || 'elevenlabs'
  switch (provider) {
    case 'elevenlabs':
      return new (require('./elevenlabs-tts').ElevenLabsTTSProvider)()
    case 'local':
      return new (require('./coqui-tts').CoquiTTSProvider)()
    case 'vieneu':
      // VieNeu-TTS integration — research during implementation
      throw new Error('VieNeu-TTS not yet implemented')
    default:
      return new (require('./elevenlabs-tts').ElevenLabsTTSProvider)()
  }
}
