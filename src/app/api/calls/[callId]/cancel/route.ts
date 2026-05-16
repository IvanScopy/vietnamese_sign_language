import { NextRequest, NextResponse } from 'next/server'
import { verifyAccessToken } from '@/app/lib/auth'
import { cancelCall } from '@/lib/calls'
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

    await cancelCall(callId, userId)

    // Fetch calleeId to emit event
    const callSession = await prisma.callSession.findUnique({
      where: { id: callId },
      select: { calleeId: true },
    })

    if (callSession) {
      emitCallEvent('call:cancelled', callSession.calleeId, { callId })
    }

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Cancel call error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    )
  }
}
