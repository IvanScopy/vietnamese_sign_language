import { describe, test, expect, jest } from '@jest/globals'
import { generateLiveKitToken, generateLiveKitRoomToken } from '@/lib/livekit'

jest.mock('livekit-server-sdk', () => ({
  AccessToken: jest.fn().mockImplementation(() => ({
    addGrant: jest.fn(),
    toJwt: jest.fn().mockResolvedValue('mock.jwt.token'),
  })),
}))

describe('LiveKit Token Generation', () => {
  test.todo('generateLiveKitToken returns a non-empty string')

  test.todo('token includes roomJoin grant')

  test.todo('token identity contains userId')

  test.todo('generateLiveKitRoomToken returns admin token')
})
