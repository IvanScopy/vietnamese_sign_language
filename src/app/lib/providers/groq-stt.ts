import type { STTProvider } from './stt-provider'

export class GroqSTTProvider implements STTProvider {
  async transcribe(audioBuffer: Buffer, language = 'vi'): Promise<string> {
    const formData = new FormData()
    formData.append('file', new Blob([audioBuffer], { type: 'audio/webm' }), 'audio.webm')
    formData.append('model', 'whisper-large-v3-turbo')
    formData.append('language', language)
    formData.append('response_format', 'json')

    const response = await fetch('https://api.groq.com/openai/v1/audio/transcriptions', {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${process.env.GROQ_API_KEY}`,
      },
      body: formData as BodyInit,
    })

    if (!response.ok) {
      throw new Error(`Groq API error: ${response.status} ${await response.text()}`)
    }

    const data = await response.json() as { text: string }
    return data.text
  }
}
