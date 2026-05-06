import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { GoogleAuthSchema } from '@/app/lib/validators'
import { verifyGoogleToken, getGoogleAuthURL } from '@/app/lib/google-oauth'
import { encryptAccessToken, encryptRefreshToken } from '@/app/lib/auth'
import bcrypt from 'bcrypt'

// GET /api/auth/google — redirect to Google for authorization
export async function GET(request: NextRequest) {
  const authUrl = getGoogleAuthURL()
  return NextResponse.redirect(authUrl)
}

// POST /api/auth/google — handle OAuth callback with authorization code
export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = GoogleAuthSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { code } = validated.data

    // Verify Google token and get user info
    const googleUser = await verifyGoogleToken(code)

    if (!googleUser) {
      return NextResponse.json(
        { error: 'Google authentication failed' },
        { status: 401 }
      )
    }

    if (!googleUser.emailVerified) {
      return NextResponse.json(
        { error: 'Google email not verified' },
        { status: 401 }
      )
    }

    // Find or create user
    let user = await prisma.user.findUnique({
      where: { email: googleUser.email },
    })

    if (!user) {
      // Create new user from Google info
      // Generate a random password for Google users (they won't use it)
      const randomPassword = Math.random().toString(36).slice(-12)
      const hashedPassword = await bcrypt.hash(randomPassword, 10)

      user = await prisma.user.create({
        data: {
          email: googleUser.email,
          password: hashedPassword,
          name: googleUser.name,
          userType: 'HEARING', // Default for Google sign-ups
        },
      })
    }

    // Generate tokens
    const payload = { userId: user.id, email: user.email, userType: user.userType }
    const accessToken = await encryptAccessToken(payload)
    const refreshToken = await encryptRefreshToken(payload)

    // Store refresh token (allow multiple sessions per CONTEXT.md)
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
        userId: user.id,
      },
    })

    // Set httpOnly cookies
    const response = NextResponse.json({
      user: { id: user.id, email: user.email, name: user.name, userType: user.userType },
    })

    response.cookies.set('accessToken', accessToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 15 * 60,
    })

    response.cookies.set('refreshToken', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60,
    })

    return response
  } catch (error) {
    console.error('Google OAuth error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
