import { getIOInstance } from '@/app/lib/socket'

/**
 * Emit a call lifecycle event to a specific user's Socket.io room.
 * Uses server-authoritative signaling — clients cannot emit these events.
 */
export function emitCallEvent(
  eventType: string,
  userId: number,
  payload: object,
): void {
  const io = getIOInstance()
  if (!io) {
    console.warn(
      `[call-signaling] Socket.io instance not available — cannot emit ${eventType} to user ${userId}`,
    )
    return
  }

  io.to(`user:${userId}`).emit(eventType, payload)
}
