import { describe, test, expect, jest, beforeEach } from '@jest/globals'
import { sendCallPushNotification } from '@/app/lib/push'

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

describe('Call Push Notifications', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test.todo(
    'sendCallPushNotification formats VIDEO_CALL data payload correctly',
  )

  test.todo(
    'sendCallPushNotification handles failed UNREGISTERED tokens by deletion',
  )

  test.todo(
    'sendCallPushNotification returns { sent: 0, failed: 0 } when Firebase not initialized',
  )

  test.todo('sendCallPushNotification queries DeviceToken by userId')
})
