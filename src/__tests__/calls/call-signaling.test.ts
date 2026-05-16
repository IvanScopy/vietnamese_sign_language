import { describe, test, expect, jest, beforeEach } from '@jest/globals'
import { emitCallEvent } from '@/app/lib/call-signaling'
import * as socketModule from '@/app/lib/socket'

jest.mock('@/app/lib/socket', () => ({
  getIOInstance: jest.fn(),
}))

const mockGetIOInstance = socketModule.getIOInstance as jest.MockedFunction<
  typeof socketModule.getIOInstance
>

describe('Call Signaling', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test.todo('emitCallEvent sends to correct user room (user:${userId})')

  test.todo('emitCallEvent does nothing when IO instance is null')

  test.todo(
    'call:incoming payload includes callId/fromUserId/expiresAt/type',
  )

  test.todo('call:accepted payload includes callId/roomName')

  test.todo('terminal events (rejected/cancelled/ended/missed/busy/failed) emit only callId')
})
