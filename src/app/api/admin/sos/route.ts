import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'

export async function GET(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Support Admin'])
  if (!auth.ok) return auth.response

  const alerts = await prisma.sOSAlert.findMany({
    include: {
      attempts: true,
      user: {
        select: { id: true, email: true, name: true },
      },
    },
    orderBy: [{ createdAt: 'desc' }],
  })

  const byStatus = alerts.reduce<Record<string, number>>((acc, alert) => {
    acc[alert.status] = (acc[alert.status] ?? 0) + 1
    return acc
  }, {})

  return NextResponse.json({ alerts, stats: { total: alerts.length, byStatus } })
}
