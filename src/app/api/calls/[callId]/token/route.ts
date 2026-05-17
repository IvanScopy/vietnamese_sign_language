import { NextRequest, NextResponse } from 'next/server'
import { generateLiveKitToken } from '@/lib/livekit'
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

    // Verify call exists, is ACTIVE, and userId is a participant
    const callSession = await prisma.callSession.findUnique({
      where: { id: callId },
    })

    if (!callSession) {
      return NextResponse.json({ error: 'Call not found' }, { status: 404 })
    }

    if (callSession.state !== 'ACTIVE') {
      return NextResponse.json(
        { error: 'Call is not active' },
        { status: 409 },
      )
    }

    if (callSession.callerId !== userId && callSession.calleeId !== userId) {
      return NextResponse.json(
        { error: 'Not a participant in this call' },
        { status: 403 },
      )
    }

    // Generate a fresh LiveKit token for this participant
    const participantName =
      callSession.callerId === userId ? 'caller' : 'callee'
    const token = await generateLiveKitToken({
      roomName: callSession.roomName,
      participantName,
      userId,
    })

    return NextResponse.json({ token })
  } catch (error) {
    console.error('Token generation error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 },
    )
  }
}
