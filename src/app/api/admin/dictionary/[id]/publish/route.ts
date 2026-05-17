import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { writeAdminAudit } from '@/app/lib/audit'
import { DictionaryStatusSchema } from '@/app/lib/validators'

export async function POST(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response

  const { id } = await params
  const dictionaryEntryId = Number(id)
  if (!Number.isFinite(dictionaryEntryId)) {
    return NextResponse.json({ error: 'Invalid dictionary entry id' }, { status: 400 })
  }

  const body = await request.json()
  const parsed = DictionaryStatusSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })
  }

  const existingEntry = await prisma.dictionaryEntry.findUnique({
    where: { id: dictionaryEntryId },
  })
  if (!existingEntry) {
    return NextResponse.json({ error: 'Dictionary entry not found' }, { status: 404 })
  }

  if (
    parsed.data.status === 'PUBLISHED'
    && (!existingEntry.vietnameseText || !existingEntry.categoryId || (!existingEntry.videoUrl && !existingEntry.videoKey))
  ) {
    return NextResponse.json({ error: 'Entry is missing required publish metadata' }, { status: 409 })
  }

  const entry = await prisma.dictionaryEntry.update({
    where: { id: dictionaryEntryId },
    data: { status: parsed.data.status },
  })

  await writeAdminAudit(
    prisma,
    auth.admin.userId,
    parsed.data.status === 'PUBLISHED' ? 'DICTIONARY_PUBLISH' : 'DICTIONARY_UNPUBLISH',
    'dictionary-entry',
    String(dictionaryEntryId),
    { status: parsed.data.status },
  )

  return NextResponse.json({ entry })
}
