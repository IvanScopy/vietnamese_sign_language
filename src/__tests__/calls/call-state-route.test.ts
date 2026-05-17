import { describe, test, expect, jest, beforeEach } from '@jest/globals'
import { NextRequest } from 'next/server'
import { GET } from '@/app/api/calls/[callId]/route'
import { prisma } from '@/app/lib/db'
import { verifyAccessToken } from '@/app/lib/auth'

const mockVerifyAccessToken = verifyAccessToken as jest.MockedFunction<
  typeof verifyAccessToken
>
const mockFindUnique = prisma.callSession
  .findUnique as jest.MockedFunction<typeof prisma.callSession.findUnique>
const mockUserFindUnique = prisma.user
  .findUnique as jest.MockedFunction<typeof prisma.user.findUnique>

const makeRequest = (headers: Record<string, string> = {}) =>
  new NextRequest('http://localhost:3000/api/calls/42', { headers })

const callParams = (callId: string) => ({ params: Promise.resolve({ callId }) })

const participantCall = {
  id: 42,
  roomName: 'vsl-call-room',
  callerId: 10,
  calleeId: 20,
  state: 'ACTIVE' as const,
  expiresAt: new Date('2026-05-16T10:00:00.000Z'),
  acceptedAt: new Date('2026-05-16T10:01:00.000Z'),
  endedAt: null,
  createdAt: new Date('2026-05-16T09:59:00.000Z'),
  caller: { name: 'Caller User' },
  callee: { name: 'Callee User' },
}

describe('GET /api/calls/[callId]', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    mockVerifyAccessToken.mockResolvedValue({
      userId: 10,
      email: 'caller@example.com',
      userType: 'DEAF',
    })
    mockUserFindUnique.mockResolvedValue({ isActive: true } as never)
  })

  test('returns 401 when unauthenticated', async () => {
    const response = await GET(makeRequest(), callParams('42'))

    expect(response.status).toBe(401)
    expect(mockVerifyAccessToken).not.toHaveBeenCalled()
    expect(mockFindUnique).not.toHaveBeenCalled()
  })

  test('returns 400 for invalid callId', async () => {
    const response = await GET(
      makeRequest({ cookie: 'accessToken=test-token' }),
      callParams('not-a-number'),
    )

    expect(response.status).toBe(400)
    expect(mockFindUnique).not.toHaveBeenCalled()
  })

  test('returns 400 for partial numeric callId', async () => {
    const response = await GET(
      makeRequest({ cookie: 'accessToken=test-token' }),
      callParams('42abc'),
    )

    expect(response.status).toBe(400)
    expect(mockFindUnique).not.toHaveBeenCalled()
  })

  test('returns 404 when the call is missing', async () => {
    mockFindUnique.mockResolvedValue(null)

    const response = await GET(
      makeRequest({ cookie: 'accessToken=test-token' }),
      callParams('42'),
    )

    expect(response.status).toBe(404)
  })

  test('returns 403 for a non-participant', async () => {
    mockVerifyAccessToken.mockResolvedValue({
      userId: 999,
      email: 'other@example.com',
      userType: 'HEARING',
    })
    mockFindUnique.mockResolvedValue(participantCall)

    const response = await GET(
      makeRequest({ cookie: 'accessToken=test-token' }),
      callParams('42'),
    )

    expect(response.status).toBe(403)
  })

  test('returns call state and participant names for a participant', async () => {
    mockFindUnique.mockResolvedValue(participantCall)

    const response = await GET(
      makeRequest({ cookie: 'accessToken=test-token' }),
      callParams('42'),
    )
    const body = await response.json()

    expect(response.status).toBe(200)
    expect(mockFindUnique).toHaveBeenCalledWith({
      where: { id: 42 },
      include: {
        caller: { select: { name: true } },
        callee: { select: { name: true } },
      },
    })
    expect(body).toMatchObject({
      id: 42,
      callId: 42,
      state: 'ACTIVE',
      roomName: 'vsl-call-room',
      callerName: 'Caller User',
      calleeName: 'Callee User',
      viewerRole: 'caller',
    })
  })

  test('accepts mobile Bearer auth', async () => {
    mockFindUnique.mockResolvedValue(participantCall)

    const response = await GET(
      makeRequest({ authorization: 'Bearer mobile-token' }),
      callParams('42'),
    )

    expect(response.status).toBe(200)
    expect(mockVerifyAccessToken).toHaveBeenCalledWith('mobile-token')
  })
})
