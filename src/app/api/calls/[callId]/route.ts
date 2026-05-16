import { NextRequest, NextResponse } from 'next/server'
import { verifyAccessToken } from '@/app/lib/auth'
import { prisma } from '@/app/lib/db'

function getAccessToken(request: NextRequest): string | null {
  const cookieToken = request.cookies.get('accessToken')?.value
  if (cookieToken) return cookieToken

  const authorization = request.headers.get('authorization')
  if (authorization?.startsWith('Bearer ')) {
    return authorization.slice('Bearer '.length)
  }

  return null
}

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ callId: string }> },
) {
  try {
    const accessToken = getAccessToken(request)
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

    const { callId: callIdStr } = await params
    const callId = parseInt(callIdStr, 10)
    if (isNaN(callId)) {
      return NextResponse.json({ error: 'Invalid call ID' }, { status: 400 })
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
