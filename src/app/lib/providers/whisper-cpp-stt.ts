import type { STTProvider } from './stt-provider'

export class WhisperCppSTTProvider implements STTProvider {
  private baseUrl: string

  constructor() {
    this.baseUrl = process.env.WHISPER_CPP_URL || 'http://localhost:8080'
  }

  async transcribe(audioBuffer: Buffer, language = 'vi'): Promise<string> {
    const formData = new FormData()
    formData.append('audio_file', new Blob([new Uint8Array(audioBuffer)], { type: 'audio/webm' }), 'audio.webm')
    formData.append('language', language)

    const response = await fetch(`${this.baseUrl}/inference`, {
      method: 'POST',
      body: formData as BodyInit,
    })

    if (!response.ok) {
      throw new Error(`whisper.cpp error: ${response.status}`)
    }

    const data = await response.json() as { text: string }
    return data.text
  }
}
