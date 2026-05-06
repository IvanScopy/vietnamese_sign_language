import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { SendNotificationSchema } from '@/app/lib/validators'
import { getIOInstance } from '@/app/lib/socket'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = SendNotificationSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { toUserId, title, body: messageBody, data, priority, type } = validated.data

    // Try Socket.io first (user online)
    const io = getIOInstance()
    if (io) {
      io.to(`user:${toUserId}`).emit('notification', {
        title,
        body: messageBody,
        data,
        priority,
        type,
        timestamp: Date.now(),
      })
    }

    // Also store notification in DB for offline users
    await prisma.$executeRaw`
      INSERT INTO notifications (title, body, data, priority, type, "userId")
      VALUES (${title}, ${messageBody}, ${JSON.stringify(data || {})}, ${priority}, ${type}, ${toUserId})
    `

    // TODO: Send FCM/APNs push notification for background/closed app
    // This requires Firebase Admin SDK setup or APNs provider

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Send notification error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
