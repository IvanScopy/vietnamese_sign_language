import { beforeEach, describe, expect, jest, test } from '@jest/globals'
import {
  acceptRingingCall,
  fetchCallPageData,
} from '@/app/calls/[callId]/page'

jest.mock('next/navigation', () => ({
  useParams: jest.fn(),
  useRouter: jest.fn(),
  useSearchParams: jest.fn(),
}))

jest.mock('@/components/calls/ActiveCallCanvas', () => ({
  __esModule: true,
  default: () => null,
}))

jest.mock('@/components/calls/CallResult', () => ({
  __esModule: true,
  default: () => null,
}))

jest.mock('@/components/calls/IncomingCallModal', () => ({
  __esModule: true,
  default: () => null,
}))

const jsonResponse = (body: unknown, ok = true) =>
  ({
    ok,
    json: jest.fn(async () => body),
  }) as unknown as Response

describe('Web Call Page', () => {
  beforeEach(() => {
    global.fetch = jest.fn() as unknown as typeof fetch
  })

  test('ACTIVE call state triggers GET then POST token', async () => {
    const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
    fetchMock
      .mockResolvedValueOnce(
        jsonResponse({
          id: 42,
          state: 'ACTIVE',
          roomName: 'vsl-room',
          callerId: 1,
          calleeId: 2,
        }),
      )
      .mockResolvedValueOnce(jsonResponse({ token: 'active-token' }))

    const result = await fetchCallPageData(42)

    expect(fetchMock).toHaveBeenNthCalledWith(1, '/api/calls/42', {
      credentials: 'include',
    })
    expect(fetchMock).toHaveBeenNthCalledWith(2, '/api/calls/42/token', {
      method: 'POST',
      credentials: 'include',
    })
    expect(result.token).toBe('active-token')
  })

  test('ACTIVE call state does not POST accept while loading', async () => {
    const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
    fetchMock
      .mockResolvedValueOnce(
        jsonResponse({
          id: 42,
          state: 'ACTIVE',
          roomName: 'vsl-room',
          callerId: 1,
          calleeId: 2,
        }),
      )
      .mockResolvedValueOnce(jsonResponse({ token: 'active-token' }))

    await fetchCallPageData(42)

    const requestedUrls = fetchMock.mock.calls.map(([url]) => url)
    expect(requestedUrls).not.toContain('/api/calls/42/accept')
  })

  test('RINGING accept action still POSTs accept', async () => {
    const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
    fetchMock.mockResolvedValueOnce(jsonResponse({ token: 'accepted-token' }))

    const token = await acceptRingingCall(42)

    expect(fetchMock).toHaveBeenCalledWith('/api/calls/42/accept', {
      method: 'POST',
      credentials: 'include',
    })
    expect(token).toBe('accepted-token')
  })

  test('terminal state from API does not fetch a token', async () => {
    const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
    fetchMock.mockResolvedValueOnce(
      jsonResponse({
        id: 42,
        state: 'ENDED',
        roomName: 'vsl-room',
        callerId: 1,
        calleeId: 2,
      }),
    )

    const result = await fetchCallPageData(42)

    expect(fetchMock).toHaveBeenCalledTimes(1)
    expect(fetchMock).toHaveBeenCalledWith('/api/calls/42', {
      credentials: 'include',
    })
    expect(result.token).toBeNull()
  })
})
