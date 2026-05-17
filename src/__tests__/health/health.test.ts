import { describe, it, expect, beforeEach, jest } from '@jest/globals'
import { GET } from '@/app/api/health/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

describe('GET /api/health', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should return healthy status when all services are ok', async () => {
    ;(prisma.$queryRaw as jest.Mock).mockResolvedValue([{ 1: 1 }])

    const request = new NextRequest('http://localhost:3000/api/health')
    const response = await GET(request)

    expect(response.status).toBe(200)
    const data = await response.json()

    expect(data.status).toBe('ok')
    expect(data.timestamp).toBeDefined()
    expect(data.services.api).toBe('ok')
    expect(data.services.database).toBe('ok')
    // Redis and LiveKit may be configured or not
    expect(['ok', 'not_configured']).toContain(data.services.redis)
    expect(['ok', 'not_configured']).toContain(data.services.livekit)
  })

  it('should return degraded status when database is down', async () => {
    ;(prisma.$queryRaw as jest.Mock).mockRejectedValue(new Error('DB connection failed'))

    const request = new NextRequest('http://localhost:3000/api/health')
    const response = await GET(request)

    expect(response.status).toBe(503)
    const data = await response.json()

    expect(data.status).toBe('degraded')
    expect(data.services.database).toBe('error')
  })

  it('should check Redis configuration', async () => {
    // Test with REDIS_URL set
    process.env.REDIS_URL = 'redis://localhost:6379'

    ;(prisma.$queryRaw as jest.Mock).mockResolvedValue([{ 1: 1 }])

    const request = new NextRequest('http://localhost:3000/api/health')
    const response = await GET(request)

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.services.redis).toBe('ok')

    // Cleanup
    delete process.env.REDIS_URL
  })

  it('should check LiveKit configuration', async () => {
    // Test with LIVEKIT_URL set
    process.env.NEXT_PUBLIC_LIVEKIT_URL = 'ws://localhost:7880'

    ;(prisma.$queryRaw as jest.Mock).mockResolvedValue([{ 1: 1 }])

    const request = new NextRequest('http://localhost:3000/api/health')
    const response = await GET(request)

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.services.livekit).toBe('ok')

    // Cleanup
    delete process.env.NEXT_PUBLIC_LIVEKIT_URL
  })

  it('should report not_configured for Redis when no REDIS_URL', async () => {
    delete process.env.REDIS_URL

    ;(prisma.$queryRaw as jest.Mock).mockResolvedValue([{ 1: 1 }])

    const request = new NextRequest('http://localhost:3000/api/health')
    const response = await GET(request)

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.services.redis).toBe('not_configured')
  })

  it('should return valid timestamp format', async () => {
    ;(prisma.$queryRaw as jest.Mock).mockResolvedValue([{ 1: 1 }])

    const request = new NextRequest('http://localhost:3000/api/health')
    const response = await GET(request)

    expect(response.status).toBe(200)
    const data = await response.json()

    // Verify timestamp is valid ISO string
    const timestamp = new Date(data.timestamp)
    expect(timestamp.toISOString()).toBe(data.timestamp)
  })
})
