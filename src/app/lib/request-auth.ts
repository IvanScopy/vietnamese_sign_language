import { NextRequest } from 'next/server'
import { verifyAccessToken } from './auth'
import type { AuthPayload } from './auth'
import { prisma } from './db'

export async function getAuthenticatedUser(request: NextRequest): Promise<AuthPayload | null> {
  // Try cookie first (web/browser)
  const cookieToken = request.cookies.get('accessToken')?.value
  let payload: AuthPayload | null = null
  if (cookieToken) payload = await verifyAccessToken(cookieToken)
  // Bearer token fallback (mobile)
  if (!payload) {
    const authHeader = request.headers.get('Authorization')
    if (authHeader?.startsWith('Bearer ')) {
      const bearerToken = authHeader.slice(7)
      payload = await verifyAccessToken(bearerToken)
    }
  }

  if (!payload) return null

  const user = await prisma.user.findUnique({
    where: { id: payload.userId },
    select: { isActive: true },
  })

  if (!user || user.isActive === false) {
    return null
  }

  return payload
}
