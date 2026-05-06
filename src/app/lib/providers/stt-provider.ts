export interface STTProvider {
  transcribe(audioBuffer: Buffer, language?: string): Promise<string>
}

export function getSTTProvider(): STTProvider {
  const provider = process.env.STT_PROVIDER || 'groq'
  switch (provider) {
    case 'groq':
      return new (require('./groq-stt').GroqSTTProvider)()
    case 'local':
      return new (require('./whisper-cpp-stt').WhisperCppSTTProvider)()
    default:
      return new (require('./groq-stt').GroqSTTProvider)()
  }
}
