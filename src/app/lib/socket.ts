import { Server as SocketIOServer, type Socket } from 'socket.io'
import { prisma } from '@/app/lib/db'
import { createHmac, timingSafeEqual } from 'crypto'

interface AuthenticatedSocket extends Socket {
  userId?: number
  userType?: string
}

// In-memory mapping of userId -> socketId for active connections
const userSockets = new Map<number, string[]>()

function base64UrlDecode(value: string): Buffer {
  const normalized = value.replace(/-/g, '+').replace(/_/g, '/')
  const padded = normalized.padEnd(Math.ceil(normalized.length / 4) * 4, '=')
  return Buffer.from(padded, 'base64')
}

async function verifySocketAccessToken(token: string) {
  try {
    const secret = process.env.JWT_SECRET
    if (!secret) return null

    const [header, payload, signature] = token.split('.')
    if (!header || !payload || !signature) return null

    const expectedSignature = createHmac('sha256', secret)
      .update(`${header}.${payload}`)
      .digest()
    const actualSignature = base64UrlDecode(signature)

    if (
      expectedSignature.length !== actualSignature.length ||
      !timingSafeEqual(expectedSignature, actualSignature)
    ) {
      return null
    }

    const parsedPayload = JSON.parse(base64UrlDecode(payload).toString('utf8')) as {
      userId?: unknown
      userType?: unknown
      exp?: unknown
    }

    if (typeof parsedPayload.exp === 'number' && parsedPayload.exp * 1000 < Date.now()) {
      return null
    }
    if (typeof parsedPayload.userId !== 'number') return null
    return {
      userId: parsedPayload.userId,
      userType: typeof parsedPayload.userType === 'string' ? parsedPayload.userType : undefined,
    }
  } catch {
    return null
  }
}

export function initializeSocketIO(httpServer: any) {
  const io = new SocketIOServer(httpServer, {
    cors: {
      origin: process.env.NEXT_PUBLIC_CLIENT_URL || 'http://localhost:3000',
      methods: ['GET', 'POST'],
      credentials: true,
    },
    transports: ['websocket', 'polling'],
  })

  io.use(async (socket: AuthenticatedSocket, next) => {
    const token =
      typeof socket.handshake.auth?.token === 'string'
        ? socket.handshake.auth.token
        : socket.handshake.headers.authorization?.startsWith('Bearer ')
          ? socket.handshake.headers.authorization.slice(7)
          : null

    if (!token) {
      next()
      return
    }

    const payload = await verifySocketAccessToken(token)
    if (payload) {
      socket.userId = payload.userId
      socket.userType = payload.userType
    }
    next()
  })

  io.on('connection', (socket: AuthenticatedSocket) => {
    console.log('Socket connected:', socket.id)

    if (socket.userId) {
      const existing = userSockets.get(socket.userId) || []
      userSockets.set(socket.userId, [...existing, socket.id])
      socket.join(`user:${socket.userId}`)
      console.log(`User ${socket.userId} authenticated on socket ${socket.id}`)
    }

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
