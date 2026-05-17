import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'

export async function GET(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Support Admin'])
  if (!auth.ok) return auth.response

  const { searchParams } = request.nextUrl
  const q = searchParams.get('q')?.trim()
  const userType = searchParams.get('userType')
  const isActive = searchParams.get('isActive')
  const adminRole = searchParams.get('adminRole')
  const limit = Math.min(Number(searchParams.get('limit') ?? '100') || 100, 200)

  const users = await prisma.user.findMany({
    where: {
      ...(q ? {
        OR: [
          { email: { contains: q, mode: 'insensitive' } },
          { name: { contains: q, mode: 'insensitive' } },
        ],
      } : {}),
      ...(userType ? { userType: userType as any } : {}),
      ...(isActive ? { isActive: isActive === 'true' } : {}),
      ...(adminRole ? { adminRole: adminRole.replace(' ', '_').toUpperCase() as any } : {}),
    },
    take: limit,
    orderBy: [{ id: 'asc' }],
  })

  return NextResponse.json({
    users: (users ?? []).map((user: Record<string, any>) => ({
      id: user.id,
      email: user.email,
      name: user.name ?? null,
      userType: user.userType,
      isActive: user.isActive ?? true,
      adminRole: user.adminRole ?? null,
      createdAt: user.createdAt instanceof Date ? user.createdAt.toISOString() : user.createdAt,
    })),
  })
}
