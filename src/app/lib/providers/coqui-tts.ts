import type { TTSProvider } from './tts-provider'

export class CoquiTTSProvider implements TTSProvider {
  private baseUrl: string

  constructor() {
    this.baseUrl = process.env.COQUI_TTS_URL || 'http://localhost:5002'
  }

  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    const response = await fetch(`${this.baseUrl}/api/tts`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        text,
        language,
      }),
    })

    if (!response.ok) {
      throw new Error(`Coqui TTS error: ${response.status}`)
    }

    const arrayBuffer = await response.arrayBuffer()
    return Buffer.from(arrayBuffer)
  }
}
