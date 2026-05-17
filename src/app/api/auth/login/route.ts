import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { LoginSchema } from '@/app/lib/validators'
import { encryptAccessToken, encryptRefreshToken } from '@/app/lib/auth'

export const dynamic = 'force-dynamic'

export async function POST(request: NextRequest) {
  try {
    const bcrypt = await import('bcrypt')
    const body = await request.json()
    const validated = LoginSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { email, password } = validated.data

    // Find user by email
    const user = await prisma.user.findUnique({
      where: { email },
    })

    if (!user || !(await bcrypt.compare(password, user.password))) {
      return NextResponse.json(
        { error: 'Invalid email or password' },
        { status: 401 }
      )
    }

    if (user.isActive === false) {
      return NextResponse.json(
        { error: 'Account disabled' },
        { status: 403 }
      )
    }

    // Generate tokens
    const payload = { userId: user.id, email: user.email, userType: user.userType }
    const accessToken = await encryptAccessToken(payload)
    const refreshToken = await encryptRefreshToken(payload)

    // Store refresh token in database (allow multiple sessions per CONTEXT.md)
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
      accessToken,
      refreshToken,
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
    console.error('Login error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
