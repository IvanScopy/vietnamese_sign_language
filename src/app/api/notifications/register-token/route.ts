import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { RegisterTokenSchema } from '@/app/lib/validators'
import { getAuthenticatedUser } from '@/app/lib/request-auth'

export async function POST(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const body = await request.json()

    // Only validate token and platform — userId is ignored from body (security)
    const tokenSchema = RegisterTokenSchema.pick({ token: true, platform: true })
    const validated = tokenSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { token, platform } = validated.data
    const userId = payload.userId

    // Upsert device token (update if token already registered)
    await prisma.deviceToken.upsert({
      where: { token },
      create: { token, platform, userId },
      update: { platform, userId },
    })

    return NextResponse.json({ success: true })
  } catch (error) {
    console.error('Register token error:', error)
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    )
  }
}
