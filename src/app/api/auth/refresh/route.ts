import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { verifyRefreshToken, encryptAccessToken, encryptRefreshToken } from '@/app/lib/auth'

export const dynamic = 'force-dynamic'

export async function POST(request: NextRequest) {
  try {
    // Get refresh token from cookie or request body
    const body = request.headers.get('content-type')?.includes('application/json')
      ? await request.json().catch(() => ({}))
      : {}
    const authHeader = request.headers.get('Authorization')
    const bearerRefreshToken = authHeader?.startsWith('Bearer ')
      ? authHeader.slice(7)
      : null
    const refreshToken = request.cookies.get('refreshToken')?.value
      ?? body.refreshToken
      ?? bearerRefreshToken

    if (!refreshToken) {
      return NextResponse.json(
        { error: 'Refresh token required' },
        { status: 400 }
      )
    }

    // Verify the refresh token
    const payload = await verifyRefreshToken(refreshToken)

    if (!payload) {
      return NextResponse.json(
        { error: 'Invalid refresh token' },
        { status: 401 }
      )
    }

    // Check if refresh token exists in database and is not expired
    const storedToken = await prisma.refreshToken.findUnique({
      where: { token: refreshToken },
      include: { user: true },
    })

    if (!storedToken || storedToken.expiresAt < new Date()) {
      // Token expired or not found - clean up
      if (storedToken) {
        await prisma.refreshToken.delete({ where: { id: storedToken.id } })
      }
      return NextResponse.json(
        { error: 'Refresh token expired or invalid' },
        { status: 401 }
      )
    }

    if (storedToken.user?.isActive === false) {
      await prisma.refreshToken.deleteMany({
        where: { userId: storedToken.user.id },
      })
      return NextResponse.json(
        { error: 'Your session expired. Log in again to continue.' },
        { status: 403 }
      )
    }

    // Generate new tokens (token rotation)
    const newPayload = {
      userId: storedToken.user.id,
      email: storedToken.user.email,
      userType: storedToken.user.userType,
    }
    const newAccessToken = await encryptAccessToken(newPayload)
    const newRefreshToken = await encryptRefreshToken(newPayload)

    // Replace old refresh token with new one
    await prisma.refreshToken.update({
      where: { id: storedToken.id },
      data: {
        token: newRefreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
      },
    })

    // Set new cookies
    const response = NextResponse.json({
      success: true,
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    })

    response.cookies.set('accessToken', newAccessToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 15 * 60,
    })

    response.cookies.set('refreshToken', newRefreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60,
    })

    return response
  } catch (error) {
    console.error('Refresh token error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
