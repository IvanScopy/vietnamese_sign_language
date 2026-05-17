import { describe, it, expect, beforeEach } from '@jest/globals'
import { GET, PUT } from '@/app/api/user/profile/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'
import { verifyAccessToken } from '@/app/lib/auth'

// Mock auth
jest.mock('@/app/lib/auth', () => ({
  verifyAccessToken: jest.fn(),
}))

describe('GET /api/user/profile', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(verifyAccessToken as jest.Mock).mockResolvedValue({ userId: 1, email: 'test@example.com' })
  })

  it('should return user profile', async () => {
    const mockUser = {
      id: 1,
      email: 'test@example.com',
      name: 'Test User',
      userType: 'HEARING',
      isActive: true,
      createdAt: new Date(),
      emergencyContacts: [],
    }

    ;(prisma.user.findUnique as jest.Mock)
      .mockResolvedValueOnce({ isActive: true })
      .mockResolvedValueOnce(mockUser)

    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'GET',
      headers: { 'Cookie': 'accessToken=mock-token' },
    })

    const response = await GET(request)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.user).toBeDefined()
    expect(data.user.email).toBe('test@example.com')
  })

  it('should return 401 when access token is missing', async () => {
    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'GET',
    })

    const response = await GET(request)
    expect(response.status).toBe(401)
  })

  it('should return 401 for invalid token', async () => {
    ;(verifyAccessToken as jest.Mock).mockResolvedValue(null)

    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'GET',
      headers: { 'Cookie': 'accessToken=invalid-token' },
    })

    const response = await GET(request)
    expect(response.status).toBe(401)
  })

  it('should return 404 when user not found', async () => {
    ;(prisma.user.findUnique as jest.Mock)
      .mockResolvedValueOnce({ isActive: true })
      .mockResolvedValueOnce(null)

    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'GET',
      headers: { 'Cookie': 'accessToken=mock-token' },
    })

    const response = await GET(request)
    expect(response.status).toBe(404)
  })
})

describe('PUT /api/user/profile', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(verifyAccessToken as jest.Mock).mockResolvedValue({ userId: 1, email: 'test@example.com' })
  })

  it('should update user name', async () => {
    const mockUpdatedUser = {
      id: 1,
      email: 'test@example.com',
      name: 'Updated Name',
      userType: 'HEARING',
      emergencyContacts: [],
    }

    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ isActive: true })
    ;(prisma.user.update as jest.Mock).mockResolvedValue(mockUpdatedUser)

    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Cookie': 'accessToken=mock-token' },
      body: JSON.stringify({ name: 'Updated Name' }),
    })

    const response = await PUT(request)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.user.name).toBe('Updated Name')
  })

  it('should update user type', async () => {
    const mockUpdatedUser = {
      id: 1,
      email: 'test@example.com',
      name: 'Test User',
      userType: 'PARENT',
      emergencyContacts: [],
    }

    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ isActive: true })
    ;(prisma.user.update as jest.Mock).mockResolvedValue(mockUpdatedUser)

    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Cookie': 'accessToken=mock-token' },
      body: JSON.stringify({ userType: 'PARENT' }),
    })

    const response = await PUT(request)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.user.userType).toBe('PARENT')
  })

  it('should return 400 for invalid userType', async () => {
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ isActive: true })

    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json', 'Cookie': 'accessToken=mock-token' },
      body: JSON.stringify({ userType: 'INVALID' }),
    })

    const response = await PUT(request)
    expect(response.status).toBe(400)
  })

  it('should return 401 when access token is missing', async () => {
    const request = new NextRequest('http://localhost:3000/api/user/profile', {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ name: 'Test' }),
    })

    const response = await PUT(request)
    expect(response.status).toBe(401)
  })
})
