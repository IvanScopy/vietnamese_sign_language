import { describe, it, expect, beforeEach } from '@jest/globals'
import { POST } from '@/app/api/stt/transcribe/route'
import { NextRequest } from 'next/server'

describe('POST /api/stt/transcribe', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should transcribe audio file successfully', async () => {
    const mockAudioBuffer = Buffer.from('mock audio data')
    const formData = new FormData()
    formData.append('audio', new Blob([mockAudioBuffer], { type: 'audio/webm' }), 'test.webm')

    const request = new NextRequest('http://localhost:3000/api/stt/transcribe', {
      method: 'POST',
      body: formData,
    })

    const response = await POST(request)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.transcript).toBeDefined()
  })

  it('should return 400 when audio file is missing', async () => {
    const formData = new FormData()

    const request = new NextRequest('http://localhost:3000/api/stt/transcribe', {
      method: 'POST',
      body: formData,
    })

    const response = await POST(request)
    expect(response.status).toBe(400)
  })
})
