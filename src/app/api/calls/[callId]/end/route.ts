import { NextRequest, NextResponse } from 'next/server'
import { endCall } from '@/lib/calls'
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

    const { callId: callIdStr } = await params
    if (!/^\d+$/.test(callIdStr)) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
    }
    const callId = Number(callIdStr)
    if (!Number.isSafeInteger(callId) || callId < 1) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
    }

    await endCall(callId, userId)

    // Fetch both participants to emit events
    const callSession = await prisma.callSession.findUnique({
      where: { id: callId },
      select: { callerId: true, calleeId: true },
    })

    if (callSession) {
      emitCallEvent('call:ended', callSession.callerId, { callId })
      emitCallEvent('call:ended', callSession.calleeId, { callId })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('End call error:', error)
    const message =
      error instanceof Error ? error.message : 'Internal server error'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
