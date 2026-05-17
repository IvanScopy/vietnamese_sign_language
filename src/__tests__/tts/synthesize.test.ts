import { describe, it, expect, beforeEach, jest } from '@jest/globals'
import { NextRequest } from 'next/server'

describe('POST /api/tts/synthesize', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    jest.resetModules()
  })

  it('should synthesize text to audio successfully', async () => {
    // Mock successful primary provider
    jest.doMock('@/app/lib/providers/tts-provider', () => ({
      getTTSProvider: () => ({
        synthesize: jest.fn().mockResolvedValue(Buffer.from('fake audio')),
      }),
    }))

    const { POST } = await import('@/app/api/tts/synthesize/route')
    const request = new NextRequest('http://localhost:3000/api/tts/synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Xin chào', language: 'vi' }),
    })

    const response = await POST(request)

    expect(response.status).toBe(200)
    expect(response.headers.get('Content-Type')).toBe('audio/mpeg')
    expect(response.headers.get('Content-Length')).toBeDefined()
  })

  it('should synthesize with default Vietnamese language', async () => {
    jest.doMock('@/app/lib/providers/tts-provider', () => ({
      getTTSProvider: () => ({
        synthesize: jest.fn().mockResolvedValue(Buffer.from('fake audio')),
      }),
    }))

    const { POST } = await import('@/app/api/tts/synthesize/route')
    const request = new NextRequest('http://localhost:3000/api/tts/synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Hello world' }),
    })

    const response = await POST(request)

    expect(response.status).toBe(200)
    expect(response.headers.get('Content-Type')).toBe('audio/mpeg')
  })

  it('should return 400 when text is missing', async () => {
    jest.doMock('@/app/lib/providers/tts-provider', () => ({
      getTTSProvider: () => ({
        synthesize: jest.fn().mockResolvedValue(Buffer.from('fake audio')),
      }),
    }))

    const { POST } = await import('@/app/api/tts/synthesize/route')
    const request = new NextRequest('http://localhost:3000/api/tts/synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ language: 'vi' }),
    })

    const response = await POST(request)
    expect(response.status).toBe(400)
    const data = await response.json()
    expect(data.error).toBe('Text is required')
  })

  it('should return 400 when text is empty string', async () => {
    jest.doMock('@/app/lib/providers/tts-provider', () => ({
      getTTSProvider: () => ({
        synthesize: jest.fn().mockResolvedValue(Buffer.from('fake audio')),
      }),
    }))

    const { POST } = await import('@/app/api/tts/synthesize/route')
    const request = new NextRequest('http://localhost:3000/api/tts/synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: '' }),
    })

    const response = await POST(request)
    expect(response.status).toBe(400)
  })

  it('should handle primary TTS provider failure and fall back to coqui', async () => {
    jest.doMock('@/app/lib/providers/tts-provider', () => ({
      getTTSProvider: () => ({
        synthesize: jest.fn().mockRejectedValue(new Error('Primary provider failed')),
      }),
    }))
    jest.doMock('@/app/lib/providers/coqui-tts', () => ({
      CoquiTTSProvider: jest.fn().mockImplementation(() => ({
        synthesize: jest.fn().mockResolvedValue(Buffer.from('fallback audio')),
      })),
    }))

    const { POST } = await import('@/app/api/tts/synthesize/route')
    const request = new NextRequest('http://localhost:3000/api/tts/synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Xin chào' }),
    })

    const response = await POST(request)

    expect(response.status).toBe(200)
    expect(response.headers.get('Content-Type')).toBe('audio/mpeg')
  })

  it('should return 500 when both providers fail', async () => {
    // Mock both providers to fail
    jest.doMock('@/app/lib/providers/tts-provider', () => ({
      getTTSProvider: () => ({
        synthesize: jest.fn().mockRejectedValue(new Error('Primary failed')),
      }),
    }))
    jest.doMock('@/app/lib/providers/coqui-tts', () => ({
      CoquiTTSProvider: jest.fn().mockImplementation(() => ({
        synthesize: jest.fn().mockRejectedValue(new Error('Fallback failed')),
      })),
    }))

    const { POST } = await import('@/app/api/tts/synthesize/route')
    const request = new NextRequest('http://localhost:3000/api/tts/synthesize', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ text: 'Xin chào' }),
    })

    const response = await POST(request)
    expect(response.status).toBe(500)
  })
})
