import { describe, it, expect, beforeEach } from '@jest/globals'
import { GET, POST, PATCH, DELETE } from '@/app/api/user/emergency-contacts/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

jest.mock('@/app/lib/request-auth', () => ({
  getAuthenticatedUser: jest.fn(),
}))

import { getAuthenticatedUser } from '@/app/lib/request-auth'

const MOCK_USER_1 = { userId: 1, email: 'user1@example.com', userType: 'DEAF' }
const MOCK_USER_2 = { userId: 2, email: 'user2@example.com', userType: 'HEARING' }

const makeRequest = (
  method: string,
  body?: unknown,
  headers: Record<string, string> = {}
) =>
  new NextRequest('http://localhost:3000/api/user/emergency-contacts', {
    method,
    headers: { 'Content-Type': 'application/json', ...headers },
    ...(body !== undefined ? { body: JSON.stringify(body) } : {}),
  })

describe('GET /api/user/emergency-contacts', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_USER_1)
  })

  it('returns only the authenticated user contacts', async () => {
    const contacts = [
      { id: 1, name: 'Mom', phone: '0901234567', phoneE164: '+84901234567', userId: 1, isActive: true },
      { id: 2, name: 'Dad', phone: '0912345678', phoneE164: '+84912345678', userId: 1, isActive: true },
    ]
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue(contacts)

    const response = await GET(makeRequest('GET'))
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.contacts).toHaveLength(2)
    expect(data.contacts[0].userId).toBe(1)
    // Verify query was scoped to auth user
    expect(prisma.emergencyContact.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { userId: 1 } })
    )
  })

  it('returns 401 for unauthenticated GET', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)

    const response = await GET(makeRequest('GET'))
    expect(response.status).toBe(401)
    const data = await response.json()
    expect(data.error).toBe('Unauthorized')
  })
})

describe('POST /api/user/emergency-contacts', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_USER_1)
  })

  it('creates contact with normalized phoneE164 for Vietnamese 0xxx number', async () => {
    const created = {
      id: 3,
      name: 'Sister',
      phone: '0901 234 567',
      phoneE164: '+84901234567',
      userId: 1,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    }
    ;(prisma.emergencyContact.create as jest.Mock).mockResolvedValue(created)

    const response = await POST(
      makeRequest('POST', { name: 'Sister', phone: '0901 234 567' })
    )
    expect(response.status).toBe(201)
    const data = await response.json()
    expect(data.contacts).toHaveLength(1)
    expect(data.contacts[0].phoneE164).toBe('+84901234567')

    // Check that the create call used normalized E.164
    expect(prisma.emergencyContact.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          phoneE164: '+84901234567',
          userId: 1,
        }),
      })
    )
  })

  it('creates contact with international number starting with +', async () => {
    const created = {
      id: 4,
      name: 'Friend',
      phone: '+12025550123',
      phoneE164: '+12025550123',
      userId: 1,
      isActive: true,
    }
    ;(prisma.emergencyContact.create as jest.Mock).mockResolvedValue(created)

    const response = await POST(
      makeRequest('POST', { name: 'Friend', phone: '+12025550123' })
    )
    expect(response.status).toBe(201)
    const data = await response.json()
    expect(data.contacts[0].phoneE164).toBe('+12025550123')
  })

  it('rejects invalid phone number', async () => {
    const response = await POST(
      makeRequest('POST', { name: 'Ghost', phone: 'not-a-phone' })
    )
    expect(response.status).toBe(400)
    // Should not have called prisma
    expect(prisma.emergencyContact.create).not.toHaveBeenCalled()
  })

  it('returns 400 for missing name', async () => {
    const response = await POST(makeRequest('POST', { phone: '0901234567' }))
    expect(response.status).toBe(400)
    expect(prisma.emergencyContact.create).not.toHaveBeenCalled()
  })

  it('returns 401 when not authenticated', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)

    const response = await POST(
      makeRequest('POST', { name: 'Test', phone: '0901234567' })
    )
    expect(response.status).toBe(401)
  })
})

describe('PATCH /api/user/emergency-contacts', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_USER_1)
  })

  it('only updates own contacts (scoped by userId)', async () => {
    const updated = {
      id: 1,
      name: 'Updated Name',
      phone: '0901234567',
      phoneE164: '+84901234567',
      userId: 1,
      isActive: true,
    }
    ;(prisma.emergencyContact.update as jest.Mock).mockResolvedValue(updated)

    const response = await PATCH(
      makeRequest('PATCH', { id: 1, name: 'Updated Name' })
    )
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.contacts[0].name).toBe('Updated Name')

    // Verify where clause includes userId
    expect(prisma.emergencyContact.update).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ id: 1, userId: 1 }),
      })
    )
  })

  it('normalizes phone when patching phone field', async () => {
    const updated = {
      id: 1,
      name: 'Mom',
      phone: '091-234-5678',
      phoneE164: '+84912345678',
      userId: 1,
      isActive: true,
    }
    ;(prisma.emergencyContact.update as jest.Mock).mockResolvedValue(updated)

    await PATCH(makeRequest('PATCH', { id: 1, phone: '091-234-5678' }))

    expect(prisma.emergencyContact.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ phoneE164: '+84912345678' }),
      })
    )
  })

  it('returns 401 when not authenticated', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)
    const response = await PATCH(makeRequest('PATCH', { id: 1, name: 'New' }))
    expect(response.status).toBe(401)
  })
})

describe('DELETE /api/user/emergency-contacts', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_USER_1)
  })

  it('only deletes own contacts (scoped by userId)', async () => {
    ;(prisma.emergencyContact.deleteMany as jest.Mock).mockResolvedValue({ count: 1 })

    const response = await DELETE(makeRequest('DELETE', { id: 5 }))
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.success).toBe(true)

    // Verify deleteMany where includes both id and userId
    expect(prisma.emergencyContact.deleteMany).toHaveBeenCalledWith({
      where: { id: 5, userId: 1 },
    })
  })

  it('user 2 cannot delete user 1 contacts (separate userId scope)', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_USER_2)
    ;(prisma.emergencyContact.deleteMany as jest.Mock).mockResolvedValue({ count: 0 })

    const response = await DELETE(makeRequest('DELETE', { id: 1 }))
    expect(response.status).toBe(200) // deleteMany returns success even if nothing deleted

    // Verify deleteMany was called with user 2's userId, not user 1
    expect(prisma.emergencyContact.deleteMany).toHaveBeenCalledWith({
      where: { id: 1, userId: 2 },
    })
  })

  it('returns 400 when id is missing', async () => {
    const response = await DELETE(makeRequest('DELETE', {}))
    expect(response.status).toBe(400)
    expect(prisma.emergencyContact.deleteMany).not.toHaveBeenCalled()
  })

  it('returns 401 when not authenticated', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)
    const response = await DELETE(makeRequest('DELETE', { id: 1 }))
    expect(response.status).toBe(401)
  })
})
