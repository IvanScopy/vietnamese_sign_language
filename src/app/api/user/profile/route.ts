import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { getAuthenticatedUser } from '@/app/lib/request-auth'
import { z } from 'zod'

const UpdateProfileSchema = z.object({
  name: z.string().optional(),
  userType: z.enum(['DEAF', 'HEARING', 'PARENT', 'TEACHER']).optional(),
})

export async function GET(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const user = await prisma.user.findUnique({
      where: { id: payload.userId },
      select: {
        id: true,
        email: true,
        name: true,
        userType: true,
        isActive: true,
        emergencyContacts: {
          select: { id: true, name: true, phone: true }
        },
        createdAt: true,
      },
    })

    if (!user) {
      return NextResponse.json({ error: 'User not found' }, { status: 404 })
    }

    return NextResponse.json({ user })
  } catch (error) {
    console.error('Profile GET error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}

export async function PUT(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Invalid or expired token' }, { status: 401 })
    }

    const body = await request.json()
    const validated = UpdateProfileSchema.safeParse(body)

    if (!validated.success) {
      return NextResponse.json(
        { errors: validated.error.flatten() },
        { status: 400 }
      )
    }

    const { name, userType } = validated.data

    const updatedUser = await prisma.user.update({
      where: { id: payload.userId },
      data: {
        ...(name !== undefined && { name }),
        ...(userType !== undefined && { userType }),
      },
      select: {
        id: true,
        email: true,
        name: true,
        userType: true,
        isActive: true,
        emergencyContacts: {
          select: { id: true, name: true, phone: true }
        },
      },
    })

    return NextResponse.json({ user: updatedUser })
  } catch (error) {
    console.error('Profile PUT error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
