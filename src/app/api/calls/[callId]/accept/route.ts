import { NextRequest, NextResponse } from 'next/server'
import { acceptCall } from '@/lib/calls'
import { emitCallEvent } from '@/app/lib/call-signaling'
import { prisma } from '@/app/lib/db'
import { getAuthenticatedUser } from '@/app/lib/request-auth'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ callId: string }> },
) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json(
        { error: 'Unauthorized' },
        { status: 401 },
      )
    }
    const userId = payload.userId

    // Parse callId from URL params
    const { callId: callIdStr } = await params
    if (!/^\d+$/.test(callIdStr)) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
    }
    const callId = Number(callIdStr)
    if (!Number.isSafeInteger(callId) || callId < 1) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
    }

    // Accept the call — atomic state transition
    const result = await acceptCall(callId, userId)

    // Fetch call session to get callerId for event emission
    const callSession = await prisma.callSession.findUnique({
      where: { id: callId },
      select: { callerId: true },
    })

    if (callSession) {
      // Emit call:accepted to caller and callee
      emitCallEvent('call:accepted', callSession.callerId, {
        callId,
        roomName: result.roomName,
      })
      emitCallEvent('call:accepted', userId, {
        callId,
        roomName: result.roomName,
      })
    }

    return NextResponse.json({
      roomName: result.roomName,
      token: result.calleeToken,
      callerToken: result.callerToken,
    })
  } catch (error) {
    console.error('Accept call error:', error)
    const message =
      error instanceof Error ? error.message : 'Internal server error'
    if (message === 'Call unavailable') {
      return NextResponse.json({ error: 'Call unavailable' }, { status: 409 })
    }
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
