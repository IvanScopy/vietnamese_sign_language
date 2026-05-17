import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import bcrypt from 'bcrypt'
import { prisma } from '@/app/lib/db'
import { RegisterSchema } from '@/app/lib/validators'
import { encryptAccessToken, encryptRefreshToken } from '@/app/lib/auth'

export const dynamic = 'force-dynamic'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = RegisterSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { email, password, name, userType } = validated.data

    // Check if user already exists
    const existingUser = await prisma.user.findUnique({
      where: { email },
    })

    if (existingUser) {
      return NextResponse.json(
        { error: 'Email already registered' },
        { status: 409 }
      )
    }

    // Hash password with bcrypt (salt rounds = 10)
    const hashedPassword = await bcrypt.hash(password, 10)

    // Create user
    const user = await prisma.user.create({
      data: {
        email,
        password: hashedPassword,
        name,
        userType,
        isActive: true,
      },
    })

    // Generate tokens
    const payload = { userId: user.id, email: user.email, userType: user.userType }
    const accessToken = await encryptAccessToken(payload)
    const refreshToken = await encryptRefreshToken(payload)

    // Store refresh token in database
    await prisma.refreshToken.create({
      data: {
        token: refreshToken,
        expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000), // 7 days
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
      maxAge: 15 * 60, // 15 minutes
    })

    response.cookies.set('refreshToken', refreshToken, {
      httpOnly: true,
      secure: process.env.NODE_ENV === 'production',
      sameSite: 'strict',
      maxAge: 7 * 24 * 60 * 60, // 7 days
    })

    return response
  } catch (error) {
    console.error('Registration error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
