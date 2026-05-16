import { NextRequest, NextResponse } from 'next/server'
import { CreateCallSchema } from '@/app/lib/validators'
import { createCall, checkBusy } from '@/lib/calls'
import { emitCallEvent } from '@/app/lib/call-signaling'
import { sendCallPushNotification } from '@/app/lib/push'
import { prisma } from '@/app/lib/db'
import { getAuthenticatedUser } from '@/app/lib/request-auth'

export async function POST(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 },
      )
    }
    const callerId = payload.userId

    // Parse and validate body
    const body = await request.json()
    const validated = CreateCallSchema.safeParse(body)
    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 },
      )
    }

    const { calleeId } = validated.data

    // Cannot call yourself
    if (callerId === calleeId) {
      return NextResponse.json(
        { error: 'Cannot call yourself' },
        { status: 400 },
      )
    }

    // Check if callee is busy
    const calleeBusy = await checkBusy(calleeId)
    if (calleeBusy) {
      return NextResponse.json(
        { error: 'User is busy' },
        { status: 409 },
      )
    }

    // Check if caller is busy
    const callerBusy = await checkBusy(callerId)
    if (callerBusy) {
      return NextResponse.json(
        { error: 'You are already in a call' },
        { status: 409 },
      )
    }

    // Create the call
    const { callId, roomName, expiresAt } = await createCall(callerId, calleeId)

    // Emit call:incoming to callee
    emitCallEvent('call:incoming', calleeId, {
      callId,
      fromUserId: callerId,
      expiresAt: expiresAt.toISOString(),
      type: 'VIDEO_CALL',
    })

    // Emit call:ringing to caller
    emitCallEvent('call:ringing', callerId, {
      callId,
      roomName,
    })

    // Get caller name for push notification (fire-and-forget)
    prisma.user
      .findUnique({ where: { id: callerId }, select: { name: true } })
      .then((user) => {
        if (user?.name) {
          sendCallPushNotification(calleeId, callId, user.name).catch(
            (err) => console.error('[calls] Push notification error:', err),
          )
        }
      })
      .catch((err) => console.error('[calls] Failed to fetch caller name:', err))

    return NextResponse.json(
      { callId, roomName, expiresAt },
      { status: 201 },
    )
  } catch (error) {
    console.error('Create call error:', error)
    const message =
      error instanceof Error ? error.message : 'Internal server error'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
