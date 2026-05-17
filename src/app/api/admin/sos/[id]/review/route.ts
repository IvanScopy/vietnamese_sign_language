import { NextRequest, NextResponse } from 'next/server'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { writeAdminAudit } from '@/app/lib/audit'
import { prisma } from '@/app/lib/db'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Support Admin'])
  if (!auth.ok) return auth.response

  const { id: sosAlertId } = await params
  if (!sosAlertId) {
    return NextResponse.json({ error: 'Invalid SOS alert id' }, { status: 400 })
  }

  const body = await request.json()

  await writeAdminAudit(prisma, auth.admin.userId, 'SOS_REVIEW', 'sos-alert', sosAlertId, body)

  return NextResponse.json({
    success: true,
    review: {
      id: sosAlertId,
      ...body,
    },
  })
}
