import { NextRequest } from 'next/server'
import { verifyAccessToken } from './auth'
import type { AuthPayload } from './auth'

export async function getAuthenticatedUser(request: NextRequest): Promise<AuthPayload | null> {
  // Try cookie first (web/browser)
  const cookieToken = request.cookies.get('accessToken')?.value
  if (cookieToken) {
    const payload = await verifyAccessToken(cookieToken)
    if (payload) return payload
  }
  // Bearer token fallback (mobile)
  const authHeader = request.headers.get('Authorization')
  if (authHeader?.startsWith('Bearer ')) {
    const bearerToken = authHeader.slice(7)
    const payload = await verifyAccessToken(bearerToken)
    if (payload) return payload
  }
  return null
}
