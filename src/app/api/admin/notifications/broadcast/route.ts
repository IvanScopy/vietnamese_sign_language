import crypto from 'node:crypto'
import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { writeAdminAudit } from '@/app/lib/audit'
import { BroadcastPreviewSchema } from '@/app/lib/validators'

export async function POST(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Support Admin'])
  if (!auth.ok) return auth.response

  const body = await request.json()
  const parsed = BroadcastPreviewSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })
  }

  const previewHash = crypto
    .createHash('sha256')
    .update(`${parsed.data.targetGroup}:${parsed.data.title}:${parsed.data.body}`)
    .digest('hex')

  if (parsed.data.mode === 'preview') {
    const previewToken = parsed.data.previewToken ?? `preview-${Date.now()}`
    const preview = await prisma.broadcastMessage.create({
      data: {
        senderUserId: auth.admin.userId,
        targetGroup: parsed.data.targetGroup,
        title: parsed.data.title,
        body: parsed.data.body,
        previewToken,
        previewHash,
        previewCount: 1,
      },
    })

    await writeAdminAudit(prisma, auth.admin.userId, 'BROADCAST_PREVIEW', 'broadcast', String(preview?.id ?? 'preview'), {
      previewToken,
      previewHash,
      targetGroup: parsed.data.targetGroup,
    })

    return NextResponse.json({
      previewToken,
      previewHash,
      targetCount: 1,
    })
  }

  if (!parsed.data.previewToken) {
    return NextResponse.json({ error: 'Preview token is required before confirm' }, { status: 400 })
  }

  const preview = await prisma.broadcastMessage.findUnique({
    where: { previewToken: parsed.data.previewToken },
  })
  if (!preview) {
    return NextResponse.json({ error: 'Preview contract missing or expired' }, { status: 409 })
  }
  if (preview.senderUserId !== auth.admin.userId) {
    return NextResponse.json({ error: 'Preview contract belongs to another actor' }, { status: 409 })
  }
  if (preview.targetGroup !== parsed.data.targetGroup || preview.title !== parsed.data.title || preview.body !== parsed.data.body) {
    return NextResponse.json({ error: 'Preview contract mismatch' }, { status: 409 })
  }

  const broadcast = await prisma.broadcastMessage.create({
    data: {
      senderUserId: auth.admin.userId,
      targetGroup: parsed.data.targetGroup,
      title: parsed.data.title,
      body: parsed.data.body,
      previewToken: parsed.data.previewToken,
      previewHash,
      previewCount: 1,
      sentAt: new Date(),
    },
  })

  await writeAdminAudit(prisma, auth.admin.userId, 'BROADCAST_SEND', 'broadcast', String(broadcast?.id ?? 'broadcast'), {
    previewToken: parsed.data.previewToken ?? null,
    previewHash,
    targetGroup: parsed.data.targetGroup,
  })

  return NextResponse.json({
    success: true,
    broadcastId: broadcast?.id ?? null,
  })
}
