import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'

export async function POST(request: NextRequest) {
  try {
    const refreshToken = request.cookies.get('refreshToken')?.value

    // If refresh token exists, delete it from database
    if (refreshToken) {
      await prisma.refreshToken.deleteMany({
        where: { token: refreshToken },
      })
    }

    // Clear cookies
    const response = NextResponse.json({ success: true })
    response.cookies.set('accessToken', '', { maxAge: 0 })
    response.cookies.set('refreshToken', '', { maxAge: 0 })

    return response
  } catch (error) {
    console.error('Logout error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
