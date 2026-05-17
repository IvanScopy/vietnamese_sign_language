import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { getAuthenticatedUser } from '@/app/lib/request-auth'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ callId: string }> },
) {
  try {
    const { callId: callIdStr } = await params
    if (!/^\d+$/.test(callIdStr)) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
    }

    const callId = Number(callIdStr)
    if (!Number.isSafeInteger(callId) || callId < 1) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
    }

    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const callSession = await prisma.callSession.findUnique({
      where: { id: callId },
      include: {
        caller: { select: { name: true } },
        callee: { select: { name: true } },
      },
    })

    if (!callSession) {
      return NextResponse.json({ error: 'Call not found' }, { status: 404 })
    }

    if (
      callSession.callerId !== payload.userId &&
      callSession.calleeId !== payload.userId
    ) {
      return NextResponse.json(
        { error: 'Not a participant in this call' },
        { status: 403 },
      )
    }

    return NextResponse.json({
      id: callSession.id,
      callId: callSession.id,
      state: callSession.state,
      roomName: callSession.roomName,
      callerId: callSession.callerId,
      calleeId: callSession.calleeId,
      callerName: callSession.caller?.name ?? null,
      calleeName: callSession.callee?.name ?? null,
      viewerRole: callSession.calleeId === payload.userId ? 'callee' : 'caller',
      expiresAt: callSession.expiresAt,
      acceptedAt: callSession.acceptedAt,
      endedAt: callSession.endedAt,
    })
  } catch (error) {
    console.error('Get call state error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    )
  }
}
