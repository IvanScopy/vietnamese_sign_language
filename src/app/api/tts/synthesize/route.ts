import { NextRequest, NextResponse } from 'next/server'
import { getTTSProvider } from '@/app/lib/providers/tts-provider'

export const dynamic = 'force-dynamic'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const { text, language } = body

    if (!text || typeof text !== 'string') {
      return NextResponse.json(
        { error: 'Text is required' },
        { status: 400 }
      )
    }

    // Try primary provider first, fallback on failure
    let audioBuffer: Buffer
    try {
      const primaryProvider = getTTSProvider()
      audioBuffer = await primaryProvider.synthesize(text, language || 'vi')
    } catch (primaryError) {
      console.error('Primary TTS provider failed, trying fallback:', primaryError)

      // Fallback to local Coqui TTS
      const { CoquiTTSProvider } = require('@/app/lib/providers/coqui-tts')
      const fallbackProvider = new CoquiTTSProvider()
      audioBuffer = await fallbackProvider.synthesize(text, language || 'vi')
    }

    return new NextResponse(audioBuffer.buffer.slice(audioBuffer.byteOffset, audioBuffer.byteOffset + audioBuffer.byteLength) as ArrayBuffer, {
      headers: {
        'Content-Type': 'audio/mpeg',
        'Content-Length': audioBuffer.length.toString(),
      },
    })
  } catch (error) {
    console.error('TTS error:', error)
    return NextResponse.json(
      { error: 'Synthesis failed' },
      { status: 500 }
    )
  }
}
