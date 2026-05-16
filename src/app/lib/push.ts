import { prisma } from '@/app/lib/db'
import { getMessaging, Messaging } from 'firebase-admin/messaging'
import { getApp, getApps } from 'firebase-admin/app'

/**
 * Send FCM push notification for an incoming video call.
 * Queries all device tokens for the user and sends a high-priority notification.
 *
 * Returns { sent, failed } counts. If Firebase is not initialized (no credentials
 * in dev), logs a warning and returns { sent: 0, failed: 0 } — does not throw.
 */
export async function sendCallPushNotification(
  userId: number,
  callId: number,
  callerName: string,
): Promise<{ sent: number; failed: number }> {
  // Check if Firebase is initialized
  let messaging: Messaging
  try {
    if (getApps().length === 0) {
      // No Firebase apps initialized — likely dev environment without credentials
      console.warn(
        '[push] Firebase not initialized — skipping push notification for call',
        callId,
      )
      return { sent: 0, failed: 0 }
    }
    messaging = getMessaging(getApp())
  } catch {
    console.warn(
      '[push] Firebase initialization error — skipping push notification for call',
      callId,
    )
    return { sent: 0, failed: 0 }
  }

  // Query all device tokens for this user
  const deviceTokens = await prisma.deviceToken.findMany({
    where: { userId },
    select: { token: true },
  })

  if (deviceTokens.length === 0) {
    console.log(`[push] No device tokens found for user ${userId}`)
    return { sent: 0, failed: 0 }
  }

  const tokens = deviceTokens.map((dt) => dt.token)

  const message = {
    notification: {
      title: 'Incoming video call',
      body: `${callerName} is calling`,
    },
    data: {
      type: 'VIDEO_CALL',
      callId: String(callId),
      callerName,
    },
    android: {
      priority: 'high' as const,
    },
    apns: {
      payload: {
        aps: {
          sound: 'default',
          badge: 1,
        },
      },
    },
    tokens,
  }

  try {
    const response = await messaging.sendEachForMulticast(message)

    // Handle failed tokens — delete UNREGISTERED ones
    const unregisteredTokens: string[] = []
    response.responses.forEach((res, index) => {
      if (!res.success) {
        const error = res.error
        if (error?.code === 'messaging/registration-token-not-registered') {
          unregisteredTokens.push(tokens[index])
        }
      }
    })

    if (unregisteredTokens.length > 0) {
      await prisma.deviceToken.deleteMany({
        where: { token: { in: unregisteredTokens } },
      })
      console.log(
        `[push] Removed ${unregisteredTokens.length} unregistered token(s) for user ${userId}`,
      )
    }

    return {
      sent: response.successCount,
      failed: response.failureCount,
    }
  } catch (error) {
    console.error('[push] FCM send error:', error)
    return { sent: 0, failed: 0 }
  }
}
