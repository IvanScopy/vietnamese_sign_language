import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { getAuthenticatedUser } from '@/app/lib/request-auth'
import { emitCallEvent } from '@/app/lib/call-signaling'
import { z } from 'zod'

const transcriptSchema = z.object({
  transcript: z.string().min(1, 'Transcript text is required'),
})

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ callId: string }> },
) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
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

    // Verify call exists and user is a participant
    const callSession = await prisma.callSession.findUnique({
      where: { id: callId },
      select: { callerId: true, calleeId: true, state: true },
    })

    if (!callSession) {
      return NextResponse.json({ error: 'Call not found' }, { status: 404 })
    }

    if (callSession.callerId !== userId && callSession.calleeId !== userId) {
      return NextResponse.json(
        { error: 'Not a participant in this call' },
        { status: 403 },
      )
    }

    // Allow saving for active or ended calls
    if (
      callSession.state !== 'ACTIVE' &&
      callSession.state !== 'ENDED'
    ) {
      return NextResponse.json(
        { error: 'Cannot save transcript for this call state' },
        { status: 400 },
      )
    }

    // Validate request body
    const body = await request.json()
    const validation = transcriptSchema.safeParse(body)
    if (!validation.success) {
      return NextResponse.json(
        { error: 'Invalid request body', details: validation.error.issues },
        { status: 400 },
      )
    }

    const { transcript } = validation.data

    // Save the transcript
    const callTranscript = await prisma.callTranscript.create({
      data: {
        callId,
        userId,
        text: transcript,
      },
    })

    const recipientId =
      callSession.callerId === userId ? callSession.calleeId : callSession.callerId
    emitCallEvent('call:transcript', recipientId, {
      callId,
      fromUserId: userId,
      text: transcript,
      transcriptId: callTranscript.id,
    })

    return NextResponse.json(
      { success: true, transcriptId: callTranscript.id },
      { status: 201 },
    )
  } catch (error) {
    console.error('Save transcript error:', error)
    const message =
      error instanceof Error ? error.message : 'Internal server error'
    return NextResponse.json({ error: message }, { status: 500 })
  }
}
