import { describe, it, expect, beforeEach } from '@jest/globals'
import { POST } from '@/app/api/notifications/register-token/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'
import { verifyAccessToken } from '@/app/lib/auth'

// request-auth imports verifyAccessToken from auth — already mocked in setup.ts
// We also need to mock request-auth itself to avoid 'server-only' import error
jest.mock('@/app/lib/request-auth', () => ({
  getAuthenticatedUser: jest.fn(),
}))

import { getAuthenticatedUser } from '@/app/lib/request-auth'

describe('POST /api/notifications/register-token', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    // Default: authenticated as user 1
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue({
      userId: 1,
      email: 'user@example.com',
      userType: 'HEARING',
    })
    ;(prisma.deviceToken.upsert as jest.Mock).mockResolvedValue({
      id: 10,
      token: 'device-token-abc',
      platform: 'android',
      userId: 1,
    })
  })

  it('returns 401 when no auth token is present', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)

    const request = new NextRequest(
      'http://localhost:3000/api/notifications/register-token',
      {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ token: 'some-token', platform: 'android' }),
      }
    )

    const response = await POST(request)
    expect(response.status).toBe(401)
    const data = await response.json()
    expect(data.error).toBe('Unauthorized')
  })

  it('returns 401 for invalid/expired token', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)

    const request = new NextRequest(
      'http://localhost:3000/api/notifications/register-token',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer invalid-token',
        },
        body: JSON.stringify({ token: 'device-token-abc', platform: 'ios' }),
      }
    )

    const response = await POST(request)
    expect(response.status).toBe(401)
  })

  it('registers device token for user derived from cookie', async () => {
    const request = new NextRequest(
      'http://localhost:3000/api/notifications/register-token',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Cookie: 'accessToken=valid-cookie-token',
        },
        body: JSON.stringify({ token: 'device-token-abc', platform: 'android' }),
      }
    )

    const response = await POST(request)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.success).toBe(true)

    expect(prisma.deviceToken.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({ userId: 1 }),
        update: expect.objectContaining({ userId: 1 }),
      })
    )
  })

  it('registers device token for user derived from Bearer token', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue({
      userId: 42,
      email: 'mobile@example.com',
      userType: 'DEAF',
    })
    ;(prisma.deviceToken.upsert as jest.Mock).mockResolvedValue({
      id: 11,
      token: 'mobile-token-xyz',
      platform: 'ios',
      userId: 42,
    })

    const request = new NextRequest(
      'http://localhost:3000/api/notifications/register-token',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: 'Bearer valid-bearer-token',
        },
        body: JSON.stringify({ token: 'mobile-token-xyz', platform: 'ios' }),
      }
    )

    const response = await POST(request)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.success).toBe(true)

    expect(prisma.deviceToken.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({ userId: 42 }),
        update: expect.objectContaining({ userId: 42 }),
      })
    )
  })

  it('body-supplied userId is ignored and cannot override auth-derived userId', async () => {
    // Auth says userId = 1, but body provides userId = 999
    const request = new NextRequest(
      'http://localhost:3000/api/notifications/register-token',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Cookie: 'accessToken=valid-token',
        },
        body: JSON.stringify({
          token: 'device-token-abc',
          platform: 'android',
          userId: 999, // should be ignored
        }),
      }
    )

    const response = await POST(request)
    expect(response.status).toBe(200)

    // Verify the upsert used auth-derived userId (1), not body userId (999)
    expect(prisma.deviceToken.upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({ userId: 1 }),
        update: expect.objectContaining({ userId: 1 }),
      })
    )
    const upsertArgs = (prisma.deviceToken.upsert as jest.Mock).mock.calls[0][0]
    expect(upsertArgs.create.userId).not.toBe(999)
    expect(upsertArgs.update.userId).not.toBe(999)
  })

  it('returns 400 when device token is missing', async () => {
    const request = new NextRequest(
      'http://localhost:3000/api/notifications/register-token',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Cookie: 'accessToken=valid-token',
        },
        body: JSON.stringify({ platform: 'android' }),
      }
    )

    const response = await POST(request)
    expect(response.status).toBe(400)
  })
})
