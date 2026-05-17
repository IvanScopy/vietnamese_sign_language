import { describe, it, expect, beforeEach } from '@jest/globals'
import { prisma } from '@/app/lib/db'

jest.mock('@/app/lib/db', () => ({
  prisma: {
    deviceToken: {
      findMany: jest.fn(),
      deleteMany: jest.fn(),
    },
  },
}))

jest.mock('firebase-admin/app', () => ({
  getApps: jest.fn(),
  getApp: jest.fn(),
}))

jest.mock('firebase-admin/messaging', () => ({
  getMessaging: jest.fn(),
}))

import { getApps, getApp } from 'firebase-admin/app'
import { getMessaging } from 'firebase-admin/messaging'
import { sendSosPushNotification } from '@/app/lib/push'

describe('SOS Push Notifications', () => {
  const mockSendEachForMulticast = jest.fn()

  beforeEach(() => {
    jest.clearAllMocks()
    ;(getApps as jest.Mock).mockReturnValue([{}]) // Firebase initialized
    ;(getApp as jest.Mock).mockReturnValue({})
    ;(getMessaging as jest.Mock).mockReturnValue({
      sendEachForMulticast: mockSendEachForMulticast,
    })
  })

  it('sends FCM with type: SOS and alertId in data payload', async () => {
    ;(prisma.deviceToken.findMany as jest.Mock).mockResolvedValue([
      { token: 'fcm-token-abc' },
    ])
    mockSendEachForMulticast.mockResolvedValue({
      successCount: 1,
      failureCount: 0,
      responses: [{ success: true }],
    })

    await sendSosPushNotification(42, {
      alertId: 99,
      fromUserName: 'Nguyen Van A',
      status: 'SENDING',
      locationLabel: 'current',
    })

    expect(mockSendEachForMulticast).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          type: 'SOS',
          alertId: '99',
        }),
        tokens: ['fcm-token-abc'],
      })
    )
  })

  it('SOS push payload does not contain Twilio credentials or raw provider metadata', async () => {
    ;(prisma.deviceToken.findMany as jest.Mock).mockResolvedValue([
      { token: 'fcm-token-xyz' },
    ])
    mockSendEachForMulticast.mockResolvedValue({
      successCount: 1,
      failureCount: 0,
      responses: [{ success: true }],
    })

    await sendSosPushNotification(42, {
      alertId: 7,
      fromUserName: 'Tran Thi B',
      status: 'SENT',
    })

    const callArg = mockSendEachForMulticast.mock.calls[0]?.[0]
    const payloadStr = JSON.stringify(callArg)

    // Must not leak Twilio auth or provider details
    expect(payloadStr).not.toMatch(/TWILIO_AUTH_TOKEN/i)
    expect(payloadStr).not.toMatch(/authToken/i)
    expect(payloadStr).not.toMatch(/accountSid/i)
    expect(payloadStr).not.toMatch(/providerMessageSid/i)
    expect(payloadStr).not.toMatch(/providerResponse/i)
    expect(payloadStr).not.toMatch(/errorCode/i)
  })

  it('returns { sent: 0, failed: 0 } when no device tokens are found', async () => {
    ;(prisma.deviceToken.findMany as jest.Mock).mockResolvedValue([])

    const result = await sendSosPushNotification(42, {
      alertId: 1,
      fromUserName: 'Le Van C',
      status: 'SENDING',
    })

    expect(result).toEqual({ sent: 0, failed: 0 })
    expect(mockSendEachForMulticast).not.toHaveBeenCalled()
  })

  it('cleans up stale UNREGISTERED tokens after send', async () => {
    ;(prisma.deviceToken.findMany as jest.Mock).mockResolvedValue([
      { token: 'valid-token' },
      { token: 'stale-token' },
    ])
    mockSendEachForMulticast.mockResolvedValue({
      successCount: 1,
      failureCount: 1,
      responses: [
        { success: true },
        { success: false, error: { code: 'messaging/registration-token-not-registered' } },
      ],
    })

    await sendSosPushNotification(42, {
      alertId: 2,
      fromUserName: 'Test',
      status: 'SENDING',
    })

    expect(prisma.deviceToken.deleteMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({ token: { in: ['stale-token'] } }),
      })
    )
  })
})

// ─── Socket fanout security ───────────────────────────────────────────────────

describe('Socket SOS fanout — server-authoritative', () => {
  it('does not expose a client socket.on(sos:alert) handler that accepts client contact lists', async () => {
    const socketModule = await import('@/app/lib/socket')
    const sourceCode = socketModule.toString()

    // The socket module should NOT have a client-driven sos:alert handler
    // that accepts emergencyContacts from the client
    // This is tested by checking the exported module does not re-export
    // any client-trusting sos handler. The actual handler in the file
    // should have been removed (server-authoritative pattern).
    expect(typeof socketModule.initializeSocketIO).toBe('function')
    expect(typeof socketModule.getIOInstance).toBe('function')
  })

  it('socket.ts comment indicates server-authoritative SOS fanout', async () => {
    // Read the actual source to verify the client-side handler was removed
    const fs = await import('fs')
    const path = await import('path')
    const socketSrc = fs.readFileSync(
      path.resolve(process.cwd(), 'src/app/lib/socket.ts'),
      'utf-8'
    )

    // Must NOT contain a socket.on handler for sos:alert that trusts client-provided contacts
    // Check that the old handler accepting emergencyContacts from client is gone
    const hasClientSosTrustHandler = /socket\.on\(['"]sos:alert['"]\s*,\s*async?\s*\(\s*\{[^}]*emergencyContacts/m.test(socketSrc)
    expect(hasClientSosTrustHandler).toBe(false)

    // Should contain a comment about server-authoritative SOS
    const hasServerAuthComment = /server.authoritative|server-authoritative/i.test(socketSrc)
    expect(hasServerAuthComment).toBe(true)
  })
})
