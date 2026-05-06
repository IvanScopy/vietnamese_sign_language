import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { RegisterTokenSchema } from '@/app/lib/validators'

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const validated = RegisterTokenSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { token, platform, userId } = validated.data

    // Upsert device token (update if user already has token for platform)
    await prisma.$executeRaw`
      INSERT INTO device_tokens (token, platform, "userId")
      VALUES (${token}, ${platform}, ${userId})
      ON CONFLICT (token) DO UPDATE SET "userId" = ${userId}
    `

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Register token error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
