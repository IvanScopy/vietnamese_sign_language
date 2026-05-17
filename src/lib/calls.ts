import { prisma } from '@/app/lib/db'
import { generateLiveKitToken } from '@/lib/livekit'

/**
 * Generate a unique room name for a video call.
 * Format: vsl-call-{timestamp}-{random8}
 */
export function generateRoomName(): string {
  const timestamp = Date.now()
  const random = Math.random().toString(36).substring(2, 10)
  return `vsl-call-${timestamp}-${random}`
}

/**
 * Create a new call session between caller and callee.
 * Validates that both users exist and neither is already in a call.
 */
export async function createCall(callerId: number, calleeId: number) {
  if (callerId === calleeId) {
    throw new Error('Caller and callee cannot be the same user')
  }

  const [caller, callee] = await Promise.all([
    prisma.user.findUnique({ where: { id: callerId } }),
    prisma.user.findUnique({ where: { id: calleeId } }),
  ])

  if (!caller) {
    throw new Error('Caller not found')
  }
  if (!callee) {
    throw new Error('Callee not found')
  }

  const [callerBusy, calleeBusy] = await Promise.all([
    checkBusy(callerId),
    checkBusy(calleeId),
  ])

  if (callerBusy) {
    throw new Error('Caller is already in a call')
  }
  if (calleeBusy) {
    throw new Error('Callee is already in a call')
  }

  const roomName = generateRoomName()
  const expiresAt = new Date(Date.now() + 30_000) // 30-second timeout

  const callSession = await prisma.callSession.create({
    data: {
      roomName,
      callerId,
      calleeId,
      state: 'RINGING',
      expiresAt,
    },
  })

  return {
    callId: callSession.id,
    roomName: callSession.roomName,
    expiresAt: callSession.expiresAt,
  }
}

/**
 * Accept an incoming call. Uses atomic updateMany to prevent race conditions.
 * Generates LiveKit tokens for both participants after successful transition.
 */
export async function acceptCall(callId: number, userId: number) {
  const result = await prisma.callSession.updateMany({
    where: {
      id: callId,
      calleeId: userId,
      state: 'RINGING',
      expiresAt: { gt: new Date() },
    },
    data: {
      state: 'ACTIVE',
      acceptedAt: new Date(),
    },
  })

  if (result.count !== 1) {
    throw new Error('Call unavailable')
  }

  const callSession = await prisma.callSession.findUnique({
    where: { id: callId },
  })

  if (!callSession) {
    throw new Error('Call session not found after accept')
  }

  const calleeToken = await generateLiveKitToken({
    roomName: callSession.roomName,
    participantName: 'callee',
    userId: callSession.calleeId,
  })

  return {
    callId: callSession.id,
    id: callSession.id,
    state: callSession.state,
    roomName: callSession.roomName,
    calleeToken,
  }
}

/**
 * Reject an incoming call. Atomic transition from RINGING to REJECTED.
 */
export async function rejectCall(callId: number, userId: number): Promise<void> {
  const result = await prisma.callSession.updateMany({
    where: {
      id: callId,
      calleeId: userId,
      state: 'RINGING',
    },
    data: {
      state: 'REJECTED',
    },
  })

  if (result.count !== 1) {
    throw new Error('Call unavailable')
  }
}

/**
 * Cancel an outgoing call. Atomic transition from RINGING to CANCELLED.
 */
export async function cancelCall(callId: number, callerId: number): Promise<void> {
  const result = await prisma.callSession.updateMany({
    where: {
      id: callId,
      callerId: callerId,
      state: 'RINGING',
    },
    data: {
      state: 'CANCELLED',
    },
  })

  if (result.count !== 1) {
    throw new Error('Call unavailable')
  }
}

/**
 * End an active call. Atomic transition from ACTIVE to ENDED.
 * Either caller or callee can end the call.
 */
export async function endCall(callId: number, userId: number): Promise<void> {
  const result = await prisma.callSession.updateMany({
    where: {
      id: callId,
      state: 'ACTIVE',
      OR: [{ callerId: userId }, { calleeId: userId }],
    },
    data: {
      state: 'ENDED',
      endedAt: new Date(),
    },
  })

  if (result.count !== 1) {
    throw new Error('Cannot end call: not active or not a participant')
  }
}

/**
 * Check if a user is currently busy (in a RINGING or ACTIVE call).
 */
export async function checkBusy(userId: number): Promise<boolean> {
  const count = await prisma.callSession.count({
    where: {
      OR: [{ callerId: userId }, { calleeId: userId }],
      state: { in: ['RINGING', 'ACTIVE'] },
    },
  })
  return count > 0
}

/**
 * Expire all RINGING calls that have passed their expiresAt timestamp.
 * Transitions them to MISSED state. Returns count of expired calls.
 */
export async function expireRingingCalls(): Promise<number> {
  const result = await prisma.callSession.updateMany({
    where: {
      state: 'RINGING',
      expiresAt: { lt: new Date() },
    },
    data: {
      state: 'MISSED',
    },
  })
  return result.count
}
