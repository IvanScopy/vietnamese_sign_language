import { NextRequest, NextResponse } from 'next/server'
import { verifyAccessToken } from '@/app/lib/auth'
import { endCall } from '@/lib/calls'
import { emitCallEvent } from '@/app/lib/call-signaling'
import { prisma } from '@/app/lib/db'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ callId: string }> },
) {
  try {
    const accessToken = request.cookies.get('accessToken')?.value
    if (!accessToken) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const payload = await verifyAccessToken(accessToken)
    if (!payload) {
      return NextResponse.json(
        { error: 'Invalid or expired token' },
        { status: 401 },
      )
    }
    const userId = payload.userId

    const { callId: callIdStr } = await params
    const callId = parseInt(callIdStr, 10)
    if (isNaN(callId)) {
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
