import { describe, it, expect, beforeEach } from '@jest/globals'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

jest.mock('@/app/lib/request-auth', () => ({
  getAuthenticatedUser: jest.fn(),
}))

jest.mock('@/app/lib/sos', () => ({
  updateSosLocation: jest.fn(),
  recordSosFallback: jest.fn(),
  recordTwilioStatus: jest.fn(),
  createSosAlert: jest.fn(),
  buildSosSmsBody: jest.fn(),
}))

jest.mock('twilio', () => {
  const validateRequest = jest.fn()
  const mockTwilio = jest.fn(() => ({}))
  Object.assign(mockTwilio, { validateRequest })
  return { __esModule: true, default: mockTwilio }
})

import { getAuthenticatedUser } from '@/app/lib/request-auth'
import { updateSosLocation, recordSosFallback, recordTwilioStatus } from '@/app/lib/sos'
import twilio from 'twilio'

// Import routes at module level so mocks are in place
import { POST as locationPOST } from '@/app/api/sos/alerts/[id]/location/route'
import { POST as fallbackPOST } from '@/app/api/sos/alerts/[id]/fallback/route'
import { POST as twilioStatusPOST } from '@/app/api/sos/twilio/status/route'

const MOCK_AUTH_USER = { userId: 42, email: 'deaf.user@example.com', userType: 'DEAF' }

// ─── Location route ──────────────────────────────────────────────────────────

describe('POST /api/sos/alerts/[id]/location', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('updates alert coordinates for the owner', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(updateSosLocation as jest.Mock).mockResolvedValue({
      id: 1,
      userId: 42,
      latitude: 10.7769,
      longitude: 106.7009,
      locationLabel: 'current',
    })

    const req = new NextRequest('http://localhost:3000/api/sos/alerts/1/location', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        latitude: 10.7769,
        longitude: 106.7009,
        locationLabel: 'current',
      }),
    })

    const response = await locationPOST(req, { params: { id: '1' } })
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.success).toBe(true)

    expect(updateSosLocation).toHaveBeenCalledWith(
      42,
      1,
      expect.objectContaining({ latitude: 10.7769, longitude: 106.7009 })
    )
  })

  it('returns 404 when alert does not belong to caller (non-owner)', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue({ userId: 99, email: 'other@example.com', userType: 'DEAF' })
    // Alert belongs to userId 42 — updateSosLocation returns null for userId 99
    ;(updateSosLocation as jest.Mock).mockResolvedValue(null)

    const req = new NextRequest('http://localhost:3000/api/sos/alerts/1/location', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        latitude: 10.7769,
        longitude: 106.7009,
        locationLabel: 'current',
      }),
    })

    const response = await locationPOST(req, { params: { id: '1' } })
    expect(response.status).toBe(404)
  })

  it('returns 401 when not authenticated', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)

    const req = new NextRequest('http://localhost:3000/api/sos/alerts/1/location', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ latitude: 10.7769, longitude: 106.7009, locationLabel: 'current' }),
    })

    const response = await locationPOST(req, { params: { id: '1' } })
    expect(response.status).toBe(401)
  })
})

// ─── Fallback route ───────────────────────────────────────────────────────────

describe('POST /api/sos/alerts/[id]/fallback', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('records native_sms_opened as NATIVE_COMPOSER_OPENED (NOT sent status)', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(recordSosFallback as jest.Mock).mockResolvedValue({ success: true })

    const req = new NextRequest('http://localhost:3000/api/sos/alerts/1/fallback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fallbackType: 'native_sms_opened' }),
    })

    const response = await fallbackPOST(req, { params: { id: '1' } })
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.success).toBe(true)

    // Must pass native_sms_opened type — not any sent/delivered type
    expect(recordSosFallback).toHaveBeenCalledWith(
      42,
      1,
      expect.objectContaining({ fallbackType: 'native_sms_opened' })
    )
    const callArgs = (recordSosFallback as jest.Mock).mock.calls[0][2]
    expect(callArgs.fallbackType).not.toMatch(/sent|delivered/i)
  })

  it('records native_sms_failed as NATIVE_COMPOSER_FAILED (NOT delivered)', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(recordSosFallback as jest.Mock).mockResolvedValue({ success: true })

    const req = new NextRequest('http://localhost:3000/api/sos/alerts/1/fallback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fallbackType: 'native_sms_failed' }),
    })

    const response = await fallbackPOST(req, { params: { id: '1' } })
    expect(response.status).toBe(200)

    expect(recordSosFallback).toHaveBeenCalledWith(
      42,
      1,
      expect.objectContaining({ fallbackType: 'native_sms_failed' })
    )
    const callArgs = (recordSosFallback as jest.Mock).mock.calls[0][2]
    expect(callArgs.fallbackType).not.toMatch(/sent|delivered/i)
  })

  it('records dialer_opened as DIALER_OPENED', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(recordSosFallback as jest.Mock).mockResolvedValue({ success: true })

    const req = new NextRequest('http://localhost:3000/api/sos/alerts/1/fallback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fallbackType: 'dialer_opened' }),
    })

    const response = await fallbackPOST(req, { params: { id: '1' } })
    expect(response.status).toBe(200)

    expect(recordSosFallback).toHaveBeenCalledWith(
      42,
      1,
      expect.objectContaining({ fallbackType: 'dialer_opened' })
    )
  })

  it('returns 404 for non-owner', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue({ userId: 77, email: 'x@x.com', userType: 'HEARING' })
    ;(recordSosFallback as jest.Mock).mockResolvedValue(null)

    const req = new NextRequest('http://localhost:3000/api/sos/alerts/1/fallback', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ fallbackType: 'native_sms_opened' }),
    })

    const response = await fallbackPOST(req, { params: { id: '1' } })
    expect(response.status).toBe(404)
  })
})

// ─── Twilio callback route ────────────────────────────────────────────────────

describe('POST /api/sos/twilio/status', () => {
  const mockValidateRequest = twilio.validateRequest as jest.Mock

  beforeEach(() => {
    jest.clearAllMocks()
    process.env.TWILIO_AUTH_TOKEN = 'test-auth-token'
    process.env.TWILIO_STATUS_CALLBACK_BASE_URL = 'https://example.com'
  })

  afterEach(() => {
    delete process.env.TWILIO_AUTH_TOKEN
    delete process.env.TWILIO_STATUS_CALLBACK_BASE_URL
  })

  it('rejects request with invalid Twilio signature (403)', async () => {
    mockValidateRequest.mockReturnValue(false)

    const formBody = 'MessageSid=SM123&MessageStatus=delivered&To=%2B84901234567&From=%2B1234567890'
    const req = new NextRequest('http://localhost:3000/api/sos/twilio/status', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Twilio-Signature': 'bad-signature',
      },
      body: formBody,
    })

    const response = await twilioStatusPOST(req)
    expect(response.status).toBe(403)
    const data = await response.json()
    expect(data.error).toMatch(/signature/i)
  })

  it('updates attempt status by providerMessageSid when signature is valid', async () => {
    mockValidateRequest.mockReturnValue(true)
    ;(recordTwilioStatus as jest.Mock).mockResolvedValue({ count: 1 })

    const formBody = 'MessageSid=SM1234567890abcdef&MessageStatus=delivered&To=%2B84901234567&From=%2B1234567890'
    const req = new NextRequest('http://localhost:3000/api/sos/twilio/status', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'X-Twilio-Signature': 'valid-signature',
      },
      body: formBody,
    })

    const response = await twilioStatusPOST(req)
    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.received).toBe(true)

    expect(recordTwilioStatus).toHaveBeenCalledWith(
      expect.objectContaining({ MessageSid: 'SM1234567890abcdef' })
    )
  })
})
