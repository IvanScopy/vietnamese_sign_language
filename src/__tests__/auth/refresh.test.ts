import { describe, it, expect, beforeEach } from '@jest/globals'
import { POST } from '@/app/api/auth/refresh/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'
import { verifyRefreshToken, encryptAccessToken, encryptRefreshToken } from '@/app/lib/auth'

// Mock auth module
jest.mock('@/app/lib/auth', () => ({
  verifyRefreshToken: jest.fn(),
  encryptAccessToken: jest.fn().mockResolvedValue('mock-access-token'),
  encryptRefreshToken: jest.fn().mockResolvedValue('mock-refresh-token'),
}))

describe('POST /api/auth/refresh', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should issue new tokens with valid refresh token', async () => {
    const mockUser = {
      id: 1,
      email: 'test@example.com',
      userType: 'HEARING',
    }

    const mockStoredToken = {
      id: 1,
      token: 'old-refresh-token',
      userId: 1,
      user: mockUser,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days in future
    }

    ;(verifyRefreshToken as jest.Mock).mockResolvedValue({
      userId: 1,
      email: 'test@example.com',
      userType: 'HEARING',
    })
    ;(prisma.refreshToken.findUnique as jest.Mock).mockResolvedValue(mockStoredToken)
    ;(prisma.refreshToken.update as jest.Mock).mockResolvedValue({})

    const request = new NextRequest('http://localhost:3000/api/auth/refresh', {
      method: 'POST',
      headers: {
        'Cookie': 'refreshToken=valid-refresh-token',
      },
    })

    const response = await POST(request)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.success).toBe(true)

    // Verify cookies are set (check response has Set-Cookie headers)
    const cookies = response.headers.getSetCookie()
    expect(cookies.some(c => c.includes('accessToken'))).toBe(true)
    expect(cookies.some(c => c.includes('refreshToken'))).toBe(true)
  })

  it('should return 400 when refresh token is missing', async () => {
    const request = new NextRequest('http://localhost:3000/api/auth/refresh', {
      method: 'POST',
    })

    const response = await POST(request)
    expect(response.status).toBe(400)
    const data = await response.json()
    expect(data.error).toBe('Refresh token required')
  })

  it('should return 401 for invalid refresh token', async () => {
    ;(verifyRefreshToken as jest.Mock).mockResolvedValue(null)

    const request = new NextRequest('http://localhost:3000/api/auth/refresh', {
      method: 'POST',
      headers: {
        'Cookie': 'refreshToken=invalid-token',
      },
    })

    const response = await POST(request)
    expect(response.status).toBe(401)
  })

  it('should return 401 for expired refresh token', async () => {
    const mockStoredToken = {
      id: 1,
      token: 'expired-token',
      userId: 1,
      expiresAt: new Date(Date.now() - 1000), // Expired
    }

    ;(verifyRefreshToken as jest.Mock).mockResolvedValue({
      userId: 1,
      email: 'test@example.com',
    })
    ;(prisma.refreshToken.findUnique as jest.Mock).mockResolvedValue(mockStoredToken)
    ;(prisma.refreshToken.delete as jest.Mock).mockResolvedValue({})

    const request = new NextRequest('http://localhost:3000/api/auth/refresh', {
      method: 'POST',
      headers: {
        'Cookie': 'refreshToken=expired-token',
      },
    })

    const response = await POST(request)
    expect(response.status).toBe(401)
  })

  it('should rotate refresh token on successful refresh', async () => {
    const mockUser = {
      id: 1,
      email: 'test@example.com',
      userType: 'HEARING',
    }

    const mockStoredToken = {
      id: 1,
      token: 'old-token',
      userId: 1,
      user: mockUser,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    }

    ;(verifyRefreshToken as jest.Mock).mockResolvedValue({
      userId: 1,
      email: 'test@example.com',
      userType: 'HEARING',
    })
    ;(prisma.refreshToken.findUnique as jest.Mock).mockResolvedValue(mockStoredToken)
    ;(prisma.refreshToken.update as jest.Mock).mockResolvedValue({})

    const request = new NextRequest('http://localhost:3000/api/auth/refresh', {
      method: 'POST',
      headers: {
        'Cookie': 'refreshToken=old-token',
      },
    })

    const response = await POST(request)
    expect(response.status).toBe(200)

    // Verify update was called with new token
    expect(prisma.refreshToken.update).toHaveBeenCalledWith({
      where: { id: 1 },
      data: {
        token: 'mock-refresh-token',
        expiresAt: expect.any(Date),
      },
    })
  })
})
