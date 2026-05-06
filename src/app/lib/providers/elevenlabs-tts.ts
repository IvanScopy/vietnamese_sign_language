import type { TTSProvider } from './tts-provider'

export class ElevenLabsTTSProvider implements TTSProvider {
  async synthesize(text: string, language = 'vi'): Promise<Buffer> {
    const response = await fetch('https://api.elevenlabs.io/v1/text-to-speech/eleven_multilingual_v2', {
      method: 'POST',
      headers: {
        'Accept': 'audio/mpeg',
        'Content-Type': 'application/json',
        'xi-api-key': process.env.ELEVENLABS_API_KEY!,
      },
      body: JSON.stringify({
        text,
        model_id: 'eleven_multilingual_v2',
        voice_settings: {
          stability: 0.5,
          similarity_boost: 0.75,
        },
      }),
    })

    if (!response.ok) {
      throw new Error(`ElevenLabs API error: ${response.status} ${await response.text()}`)
    }

    const arrayBuffer = await response.arrayBuffer()
    return Buffer.from(arrayBuffer)
  }
}
