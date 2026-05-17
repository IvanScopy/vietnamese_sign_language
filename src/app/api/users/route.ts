import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { getAuthenticatedUser } from '@/app/lib/request-auth'

export async function GET(request: NextRequest) {
  try {
    const payload = await getAuthenticatedUser(request)
    if (!payload) {
      return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
    }

    const users = await prisma.user.findMany({
      where: { id: { not: payload.userId } },
      select: { id: true, name: true, email: true, userType: true },
      orderBy: [{ name: 'asc' }, { email: 'asc' }],
      take: 50,
    })

    return NextResponse.json({
      users: users.map((user) => ({
        id: user.id,
        name: user.name || user.email,
        email: user.email,
        userType: user.userType,
      })),
    })
  } catch (error) {
    console.error('Users lookup error:', error)
    return NextResponse.json({ error: 'Internal server error' }, { status: 500 })
  }
}
