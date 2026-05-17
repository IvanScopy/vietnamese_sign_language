import { describe, it, expect, beforeEach } from '@jest/globals'
import { POST as registerToken } from '@/app/api/notifications/register-token/route'
import { POST as sendNotification } from '@/app/api/notifications/send/route'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

jest.mock('@/app/lib/request-auth', () => ({
  getAuthenticatedUser: jest.fn(),
}))

import { getAuthenticatedUser } from '@/app/lib/request-auth'

describe('Notifications API', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(getAuthenticatedUser as jest.Mock).mockResolvedValue({
      userId: 1,
      email: 'test@example.com',
      userType: 'DEAF',
    })
  })

  describe('POST /api/notifications/register-token', () => {
    it('should register a device token successfully', async () => {
      ;(prisma.$executeRaw as jest.Mock).mockResolvedValue({})

      const request = new NextRequest('http://localhost:3000/api/notifications/register-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          token: 'device-token-123',
          platform: 'android',
          userId: 1,
        }),
      })

      const response = await registerToken(request)
      expect(response.status).toBe(200)
      const data = await response.json()
      expect(data.success).toBe(true)
    })

    it('should return 400 for missing required fields', async () => {
      const request = new NextRequest('http://localhost:3000/api/notifications/register-token', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          platform: 'android',
        }),
      })

      const response = await registerToken(request)
      expect(response.status).toBe(400)
    })
  })

  describe('POST /api/notifications/send', () => {
    it('should send notification successfully', async () => {
      ;(prisma.notification.create as jest.Mock).mockResolvedValue({ id: 1 })

      const request = new NextRequest('http://localhost:3000/api/notifications/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          toUserId: 1,
          title: 'Test Notification',
          body: 'Hello!',
          type: 'MESSAGE',
        }),
      })

      const response = await sendNotification(request)
      expect(response.status).toBe(200)
    })

    it('should return 400 for missing title', async () => {
      const request = new NextRequest('http://localhost:3000/api/notifications/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          toUserId: 1,
          body: 'Hello!',
        }),
      })

      const response = await sendNotification(request)
      expect(response.status).toBe(400)
    })

    it('should return 400 for missing body', async () => {
      const request = new NextRequest('http://localhost:3000/api/notifications/send', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          toUserId: 1,
          title: 'Test',
        }),
      })

      const response = await sendNotification(request)
      expect(response.status).toBe(400)
    })
  })
})
