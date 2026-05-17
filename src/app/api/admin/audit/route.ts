import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'

export async function GET(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin', 'Support Admin'])
  if (!auth.ok) return auth.response
  const { searchParams } = request.nextUrl
  const action = searchParams.get('action')
  const targetType = searchParams.get('targetType')
  const limit = Math.min(Number(searchParams.get('limit') ?? '100') || 100, 200)

  const logs = await prisma.adminAuditLog.findMany({
    where: {
      ...(action ? { action: action as any } : {}),
      ...(targetType ? { targetType } : {}),
    },
    orderBy: [{ createdAt: 'desc' }],
    take: limit,
    include: {
      actorUser: {
        select: { id: true, email: true, name: true, adminRole: true },
      },
    },
  })

  return NextResponse.json({ logs })
}
