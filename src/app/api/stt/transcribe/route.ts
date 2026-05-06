import { NextRequest, NextResponse } from 'next/server'
import { getSTTProvider } from '@/app/lib/providers/stt-provider'

export async function POST(request: NextRequest) {
  try {
    const formData = await request.formData()
    const audioFile = formData.get('audio') as File | null
    const language = (formData.get('language') as string) || 'vi'

    if (!audioFile) {
      return NextResponse.json(
        { error: 'Audio file is required' },
        { status: 400 }
      )
    }

    const bytes = await audioFile.arrayBuffer()
    const audioBuffer = Buffer.from(bytes)

    // Try primary provider first, fallback on failure
    let transcript: string
    try {
      const primaryProvider = getSTTProvider()
      transcript = await primaryProvider.transcribe(audioBuffer, language)
    } catch (primaryError) {
      console.error('Primary STT provider failed, trying fallback:', primaryError)

      // Fallback to local whisper.cpp
      const { WhisperCppSTTProvider } = require('@/app/lib/providers/whisper-cpp-stt')
      const fallbackProvider = new WhisperCppSTTProvider()
      transcript = await fallbackProvider.transcribe(audioBuffer, language)
    }

    return NextResponse.json({ transcript })
  } catch (error) {
    console.error('STT error:', error)
    return NextResponse.json(
      { error: 'Transcription failed' },
      { status: 500 }
    )
  }
}
