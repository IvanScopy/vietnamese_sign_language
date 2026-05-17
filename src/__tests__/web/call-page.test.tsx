import { beforeEach, describe, expect, jest, test } from '@jest/globals'
import {
  acceptRingingCall,
  cancelRingingCall,
  endActiveCall,
  fetchCallPageData,
  parsePositiveCallId,
  saveCallTranscript,
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

  test('RINGING cancel action POSTs cancel', async () => {
    const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
    fetchMock.mockResolvedValueOnce(jsonResponse({ success: true }))

    await cancelRingingCall(42)

    expect(fetchMock).toHaveBeenCalledWith('/api/calls/42/cancel', {
      method: 'POST',
      credentials: 'include',
    })
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

  test('parsePositiveCallId rejects invalid route params', () => {
    expect(parsePositiveCallId('42')).toBe(42)
    expect(parsePositiveCallId(['7'])).toBe(7)
    expect(parsePositiveCallId('0')).toBeNull()
    expect(parsePositiveCallId('not-a-number')).toBeNull()
    expect(parsePositiveCallId(undefined)).toBeNull()
  })

  test('endActiveCall POSTs the server end transition', async () => {
    const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
    fetchMock.mockResolvedValueOnce(jsonResponse({ success: true }))

    await endActiveCall(42)

    expect(fetchMock).toHaveBeenCalledWith('/api/calls/42/end', {
      method: 'POST',
      credentials: 'include',
    })
  })

  test('saveCallTranscript POSTs confirmed transcript text', async () => {
    const fetchMock = global.fetch as jest.MockedFunction<typeof fetch>
    fetchMock.mockResolvedValueOnce(jsonResponse({ success: true }))

    await saveCallTranscript(42, 'Xin chao')

    expect(fetchMock).toHaveBeenCalledWith('/api/calls/42/transcript', {
      method: 'POST',
      credentials: 'include',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ transcript: 'Xin chao' }),
    })
  })
})
