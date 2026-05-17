import { describe, it, expect, beforeEach } from '@jest/globals'
import { POST } from '@/app/api/sos/alerts/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

jest.mock('@/app/lib/request-auth', () => ({
  getAuthenticatedUser: jest.fn(),
}))

jest.mock('@/app/lib/sms-provider', () => ({
  getSmsProvider: jest.fn(),
}))

import { getAuthenticatedUser } from '@/app/lib/request-auth'
import { getSmsProvider } from '@/app/lib/sms-provider'

const MOCK_AUTH_USER = { userId: 42, email: 'deaf.user@example.com', userType: 'DEAF' }

const makeRequest = (body?: unknown) =>
  new NextRequest('http://localhost:3000/api/sos/alerts', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    ...(body !== undefined ? { body: JSON.stringify(body) } : { body: JSON.stringify({}) }),
  })

const mockSendSuccess = jest.fn().mockResolvedValue({
  success: true,
  provider: 'twilio',
  providerMessageSid: 'SM1234567890abcdef',
  providerStatus: 'queued',
  status: 'PROVIDER_QUEUED',
})

const mockSendFailure = jest.fn().mockResolvedValue({
  success: false,
  provider: 'twilio',
  status: 'PROVIDER_FAILED',
  errorCode: '21211',
  errorMessage: 'Invalid phone number',
})

describe('POST /api/sos/alerts - Authentication', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  it('returns 401 when not authenticated', async () => {
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(null)

    const response = await POST(makeRequest({}))
    expect(response.status).toBe(401)
    const data = await response.json()
    expect(data.error).toBe('Unauthorized')
  })
})

describe('POST /api/sos/alerts - Server-authoritative userId', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(getSmsProvider as jest.Mock).mockReturnValue({ send: mockSendSuccess })
  })

  it('creates SOSAlert with userId from auth token, not from body', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Nguyen Van A' })
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue([])
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 1,
      userId: 42,
      status: 'SENT',
      smsBody: '🆘 Nguyen Van A cần trợ giúp khẩn cấp!\nTôi cần trợ giúp khẩn cấp. Đường dây khẩn cấp: 115\nKhông có vị trí GPS\nThời gian: 08:00',
      latitude: null,
      longitude: null,
      idempotencyKey: null,
    })

    // Attempt to inject a different userId via body
    const response = await POST(makeRequest({ userId: 999 }))
    expect(response.status).toBe(201)

    // Verify the alert was created with auth userId (42), not body userId (999)
    expect(prisma.sOSAlert.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ userId: 42 }),
      })
    )
  })

  it('ignores body recipient/contacts/userId fields', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Nguyen Van A' })
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue([])
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 2,
      userId: 42,
      status: 'SENT',
      smsBody: 'body',
    })

    const response = await POST(makeRequest({
      userId: 1337,
      contacts: [{ phone: '+84901234567' }],
      recipient: '+84900000000',
    }))
    expect(response.status).toBe(201)

    // These fields should be silently ignored — alert still uses auth userId
    expect(prisma.sOSAlert.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ userId: 42 }),
      })
    )
    // No direct recipient-injection possible
    expect(prisma.sOSAlert.create).toHaveBeenCalledWith(
      expect.not.objectContaining({
        data: expect.objectContaining({ userId: 1337 }),
      })
    )
  })
})

describe('POST /api/sos/alerts - No contacts scenario', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(getSmsProvider as jest.Mock).mockReturnValue({ send: mockSendSuccess })
  })

  it('returns 201 with noContacts:true and does not call SMS provider', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Nguyen Van A' })
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue([])
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 3,
      userId: 42,
      status: 'SENT',
      smsBody: '🆘 Nguyen Van A cần trợ giúp khẩn cấp!\nTôi cần trợ giúp khẩn cấp.',
    })

    const response = await POST(makeRequest({}))
    expect(response.status).toBe(201)
    const data = await response.json()
    expect(data.noContacts).toBe(true)
    expect(data.contactsCount).toBe(0)
    expect(data.attempts).toHaveLength(0)

    // Provider must NOT be called when no contacts
    expect(mockSendSuccess).not.toHaveBeenCalled()
  })
})

describe('POST /api/sos/alerts - Active contacts', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(getSmsProvider as jest.Mock).mockReturnValue({ send: mockSendSuccess })
  })

  it('creates an attempt for each active contact and calls provider concurrently', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Nguyen Van A' })

    const contacts = [
      { id: 10, name: 'Mom', phone: '0901234567', phoneE164: '+84901234567', isActive: true, userId: 42 },
      { id: 11, name: 'Dad', phone: '0912345678', phoneE164: '+84912345678', isActive: true, userId: 42 },
    ]
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue(contacts)
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 4,
      userId: 42,
      status: 'SENDING',
      smsBody: '🆘 Nguyen Van A cần trợ giúp khẩn cấp!\nTôi cần trợ giúp khẩn cấp. Đường dây khẩn cấp: 115\nKhông có vị trí GPS\nThời gian: 08:00',
    })

    // Mock attempt creation for each contact
    ;(prisma.sosAlertAttempt.create as jest.Mock)
      .mockResolvedValueOnce({ id: 100, sosAlertId: 4, emergencyContactId: 10, recipientName: 'Mom', recipientPhoneE164: '+84901234567', channel: 'PROVIDER_SMS', status: 'PROVIDER_QUEUED' })
      .mockResolvedValueOnce({ id: 101, sosAlertId: 4, emergencyContactId: 11, recipientName: 'Dad', recipientPhoneE164: '+84912345678', channel: 'PROVIDER_SMS', status: 'PROVIDER_QUEUED' })

    ;(prisma.sosAlertAttempt.update as jest.Mock)
      .mockResolvedValueOnce({ id: 100, channel: 'PROVIDER_SMS', status: 'PROVIDER_QUEUED', recipientName: 'Mom', recipientPhoneE164: '+84901234567' })
      .mockResolvedValueOnce({ id: 101, channel: 'PROVIDER_SMS', status: 'PROVIDER_QUEUED', recipientName: 'Dad', recipientPhoneE164: '+84912345678' })

    ;(prisma.sOSAlert.update as jest.Mock).mockResolvedValue({ id: 4, status: 'SENDING' })

    const response = await POST(makeRequest({}))
    expect(response.status).toBe(201)
    const data = await response.json()

    // Attempt created for each contact
    expect(prisma.sosAlertAttempt.create).toHaveBeenCalledTimes(2)
    // Provider called for each contact
    expect(mockSendSuccess).toHaveBeenCalledTimes(2)
    expect(mockSendSuccess).toHaveBeenCalledWith(
      expect.objectContaining({ to: '+84901234567' })
    )
    expect(mockSendSuccess).toHaveBeenCalledWith(
      expect.objectContaining({ to: '+84912345678' })
    )

    expect(data.contactsCount).toBe(2)
    expect(data.attempts).toHaveLength(2)
  })
})

describe('POST /api/sos/alerts - Provider failure', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(getSmsProvider as jest.Mock).mockReturnValue({ send: mockSendFailure })
  })

  it('marks attempt as PROVIDER_FAILED and returns fallbackTargets when all fail', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Nguyen Van A' })

    const contacts = [
      { id: 20, name: 'Sister', phone: '0901111222', phoneE164: '+84901111222', isActive: true, userId: 42 },
    ]
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue(contacts)
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 5,
      userId: 42,
      status: 'SENDING',
      smsBody: '🆘 Nguyen Van A cần trợ giúp khẩn cấp!\nTôi cần trợ giúp khẩn cấp.',
    })

    ;(prisma.sosAlertAttempt.create as jest.Mock).mockResolvedValueOnce({
      id: 200,
      sosAlertId: 5,
      emergencyContactId: 20,
      recipientName: 'Sister',
      recipientPhoneE164: '+84901111222',
      channel: 'PROVIDER_SMS',
      status: 'PROVIDER_QUEUED',
    })

    ;(prisma.sosAlertAttempt.update as jest.Mock).mockResolvedValueOnce({
      id: 200,
      channel: 'PROVIDER_SMS',
      status: 'PROVIDER_FAILED',
      recipientName: 'Sister',
      recipientPhoneE164: '+84901111222',
    })

    ;(prisma.sOSAlert.update as jest.Mock).mockResolvedValue({ id: 5, status: 'NATIVE_FALLBACK' })

    const response = await POST(makeRequest({}))
    expect(response.status).toBe(201)
    const data = await response.json()

    // Attempt was updated to failed
    expect(prisma.sosAlertAttempt.update).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ status: 'PROVIDER_FAILED' }),
      })
    )

    // fallbackTargets returned when all fail
    expect(data.fallbackTargets).toHaveLength(1)
    expect(data.fallbackTargets[0].name).toBe('Sister')
    expect(data.fallbackTargets[0].phoneE164).toBe('+84901111222')
    expect(data.status).toBe('NATIVE_FALLBACK')
  })
})

describe('POST /api/sos/alerts - SMS body content', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue(MOCK_AUTH_USER)
    ;(getSmsProvider as jest.Mock).mockReturnValue({ send: mockSendSuccess })
  })

  it('SMS body includes user name and emergency text in Vietnamese', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Tran Thi B' })
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue([])
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 6,
      userId: 42,
      status: 'SENT',
      smsBody: null,
    })

    const response = await POST(makeRequest({}))
    expect(response.status).toBe(201)

    // Verify the smsBody was created with required content
    const createCall = (prisma.sOSAlert.create as jest.Mock).mock.calls[0][0]
    const smsBody: string = createCall.data.smsBody
    expect(smsBody).toContain('Tran Thi B')
    expect(smsBody).toContain('Tôi cần trợ giúp khẩn cấp')
  })

  it('SMS body includes Google Maps link when coordinates provided', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Le Van C' })
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue([])
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 7,
      userId: 42,
      status: 'SENT',
      smsBody: null,
    })

    const response = await POST(makeRequest({
      latitude: 10.7769,
      longitude: 106.7009,
    }))
    expect(response.status).toBe(201)

    const createCall = (prisma.sOSAlert.create as jest.Mock).mock.calls[0][0]
    const smsBody: string = createCall.data.smsBody
    expect(smsBody).toContain('maps.google.com')
    expect(smsBody).toContain('10.7769')
    expect(smsBody).toContain('106.7009')
  })

  it('SMS body includes no-location text when coordinates not provided', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Le Van C' })
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue([])
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 8,
      userId: 42,
      status: 'SENT',
      smsBody: null,
    })

    const response = await POST(makeRequest({}))
    expect(response.status).toBe(201)

    const createCall = (prisma.sOSAlert.create as jest.Mock).mock.calls[0][0]
    const smsBody: string = createCall.data.smsBody
    expect(smsBody).toContain('Không có vị trí GPS')
  })

  it('SMS body includes timestamp', async () => {
    ;(prisma.sOSAlert.findFirst as jest.Mock).mockResolvedValue(null)
    ;(prisma.user.findUnique as jest.Mock).mockResolvedValue({ id: 42, name: 'Test User' })
    ;(prisma.emergencyContact.findMany as jest.Mock).mockResolvedValue([])
    ;(prisma.sOSAlert.create as jest.Mock).mockResolvedValue({
      id: 9,
      userId: 42,
      status: 'SENT',
      smsBody: null,
    })

    const response = await POST(makeRequest({}))
    expect(response.status).toBe(201)

    const createCall = (prisma.sOSAlert.create as jest.Mock).mock.calls[0][0]
    const smsBody: string = createCall.data.smsBody
    // Should include a time string (HH:MM format)
    expect(smsBody).toMatch(/\d{1,2}:\d{2}/)
  })
})
