import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'

export const dynamic = 'force-dynamic'

export async function POST(request: NextRequest) {
  try {
    const body = request.headers.get('content-type')?.includes('application/json')
      ? await request.json().catch(() => ({}))
      : {}
    const authHeader = request.headers.get('Authorization')
    const bearerToken = authHeader?.startsWith('Bearer ') ? authHeader.slice(7) : null
    const refreshToken = request.cookies.get('refreshToken')?.value
      ?? body.refreshToken
      ?? bearerToken

    if (refreshToken) {
      await prisma.refreshToken.deleteMany({
        where: { token: refreshToken },
      })
    }

    const response = NextResponse.json({ success: true })
    response.cookies.set('accessToken', '', { httpOnly: true, maxAge: 0, sameSite: 'strict' })
    response.cookies.set('refreshToken', '', { httpOnly: true, maxAge: 0, sameSite: 'strict' })
    return response
  } catch (error) {
    console.error('Logout error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
