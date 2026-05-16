import { Server as SocketIOServer, type Socket } from 'socket.io'
import { prisma } from '@/app/lib/db'

interface AuthenticatedSocket extends Socket {
  userId?: number
  userType?: string
}

// In-memory mapping of userId -> socketId for active connections
const userSockets = new Map<number, string[]>()

export function initializeSocketIO(httpServer: any) {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: process.env.NEXT_PUBLIC_CLIENT_URL || 'http://localhost:3000',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  })

  io.on('connection', (socket: AuthenticatedSocket) => {
    console.log('Socket connected:', socket.id)

    // Register user with their socket for targeted notifications
    socket.on('register', async (userId: number, userType: string) => {
      socket.userId = userId
      socket.userType = userType

      // Store socket mapping
      const existing = userSockets.get(userId) || []
      userSockets.set(userId, [...existing, socket.id])

      // Join user-specific room
      socket.join(`user:${userId}`)

      console.log(`User ${userId} registered on socket ${socket.id}`)
    })

    // Call signaling is now server-authoritative via REST endpoints.
    // See src/app/api/calls/ — clients cannot emit call lifecycle events.

    // SOS fanout is server-authoritative — see src/app/lib/sos.ts
    // Clients do NOT emit sos:alert with contact lists. The server loads emergency
    // contacts from the database and emits to user:{linkedUserId} rooms after
    // createSosAlert completes. This prevents contact-list injection attacks.

    // Handle disconnection
    socket.on('disconnect', () => {
      if (socket.userId) {
        const existing = userSockets.get(socket.userId) || []
        const updated = existing.filter(id => id !== socket.id)
        if (updated.length === 0) {
          userSockets.delete(socket.userId)
        } else {
          userSockets.set(socket.userId, updated)
        }
      }
      console.log('Socket disconnected:', socket.id)
    })
  })

  // Set global instance for access from API routes (type assertion for TS)
  ;(globalThis as any).__socketIO = io

  return io
}

export function getIOInstance(): SocketIOServer | null {
  // This will be set during Next.js server startup
  return (globalThis as any).__socketIO || null
}
