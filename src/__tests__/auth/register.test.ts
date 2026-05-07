import { describe, it, expect, beforeEach, beforeAll } from '@jest/globals'
import { POST } from '@/app/api/auth/register/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

describe('POST /api/auth/register', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('should register a new user with valid input', async () => {
    const mockUser = {
      id: 1,
      email: 'test@example.com',
      name: 'Test User',
      userType: 'HEARING',
      password: 'hashed-password',
      createdAt: new Date(),
      updatedAt: new Date(),
    }

    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.create as jest.Mock).mockResolvedValue(mockUser)
    ;(prisma.refreshToken.create as jest.Mock).mockResolvedValue({})

    const request = new NextRequest('http://localhost:3000/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        userType: 'HEARING',
      }),
    })

    const response = await POST(request)
    const data = await response.json()

    expect(response.status).toBe(200)
    expect(data.user).toBeDefined()
    expect(data.user.email).toBe('test@example.com')
  })

  it('should return 409 for duplicate email', async () => {
    const existingUser = {
      id: 1,
      email: 'test@example.com',
      password: 'hashed-password',
      name: 'Existing User',
      userType: 'HEARING',
    }

    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue(existingUser)

    const request = new NextRequest('http://localhost:3000/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'test@example.com',
        password: 'password123',
        name: 'Test User',
        userType: 'HEARING',
      }),
    })

    const response = await POST(request)
    expect(response.status).toBe(409)
  })

  it('should return 400 for invalid validation', async () => {
    const request = new NextRequest('http://localhost:3000/api/auth/register', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        email: 'invalid-email',
        password: 'short',
        name: '',
      }),
    })

    const response = await POST(request)
    expect(response.status).toBe(400)
  })
})
