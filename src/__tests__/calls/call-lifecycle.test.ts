import { describe, test, expect, beforeEach, jest } from '@jest/globals'
import {
  generateRoomName,
  createCall,
  acceptCall,
  rejectCall,
  cancelCall,
  endCall,
  checkBusy,
  expireRingingCalls,
} from '@/lib/calls'
import { prisma } from '@/app/lib/db'

jest.mock('livekit-server-sdk', () => ({
  AccessToken: jest.fn().mockImplementation(() => ({
    addGrant: jest.fn(),
    toJwt: jest.fn().mockResolvedValue('mock.jwt.token' as never),
  })),
}))

const mockPrisma = prisma as jest.Mocked<typeof prisma>

describe('Call Lifecycle', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test.todo('generateRoomName returns strings matching pattern /^vsl-call-\\d+-[a-zA-Z0-9]{8}$/')

  test.todo('createCall succeeds with valid users')

  test.todo('createCall rejects when callerId === calleeId')

  test.todo('createCall rejects when caller does not exist')

  test.todo('createCall rejects when callee does not exist')

  test.todo('createCall rejects when caller is already busy')

  test.todo('createCall rejects when callee is already busy')

  test.todo('acceptCall transitions RINGING to ACTIVE')

  test.todo('acceptCall returns roomName and both callerToken and calleeToken')

  test.todo('acceptCall throws when call is not available')

  test.todo('rejectCall transitions RINGING to REJECTED')

  test.todo('cancelCall transitions RINGING to CANCELLED')

  test.todo('endCall transitions ACTIVE to ENDED')

  test.todo('endCall accepts either callerId or calleeId as userId')

  test.todo('endCall throws when call is not active')

  test.todo('expireRingingCalls transitions expired RINGING to MISSED')

  test.todo('expireRingingCalls returns count of expired calls')

  test.todo('checkBusy returns true for user with RINGING call')

  test.todo('checkBusy returns true for user with ACTIVE call')

  test.todo('checkBusy returns false for user with no active calls')

  test('acceptCall returns only callee token and call identity fields', async () => {
    mockPrisma.callSession.updateMany.mockResolvedValueOnce({ count: 1 } as never)
    mockPrisma.callSession.findUnique.mockResolvedValueOnce({
      id: 42,
      roomName: 'vsl-room',
      callerId: 1,
      calleeId: 2,
      state: 'ACTIVE',
    } as never)

    const result = await acceptCall(42, 2)

    expect(result).toMatchObject({
      callId: 42,
      id: 42,
      state: 'ACTIVE',
      roomName: 'vsl-room',
      calleeToken: expect.any(String),
    })
    expect(result).not.toHaveProperty('callerToken')
  })

  test('rejectCall throws when no authorized transition occurs', async () => {
    mockPrisma.callSession.updateMany.mockResolvedValueOnce({ count: 0 } as never)

    await expect(rejectCall(42, 99)).rejects.toThrow('Call unavailable')
  })

  test('cancelCall throws when no authorized transition occurs', async () => {
    mockPrisma.callSession.updateMany.mockResolvedValueOnce({ count: 0 } as never)

    await expect(cancelCall(42, 99)).rejects.toThrow('Call unavailable')
  })
})
