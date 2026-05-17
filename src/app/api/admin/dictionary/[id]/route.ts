import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { writeAdminAudit } from '@/app/lib/audit'
import { DictionaryEntryPayloadSchema } from '@/app/lib/validators'
import { normalizeKeywordList, normalizeVietnameseSearch } from '@/app/lib/dictionary-search'

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response
  const { id: idParam } = await params
  const id = Number(idParam)
  if (!Number.isFinite(id)) return NextResponse.json({ error: 'Invalid id' }, { status: 400 })

  const entry = await prisma.dictionaryEntry.findUnique({
    where: { id },
    include: { category: true },
  })
  if (!entry) return NextResponse.json({ error: 'Not found' }, { status: 404 })
  return NextResponse.json({ entry })
}

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response
  const { id: idParam } = await params
  const id = Number(idParam)
  if (!Number.isFinite(id)) return NextResponse.json({ error: 'Invalid id' }, { status: 400 })

  const body = await request.json()
  const parsed = DictionaryEntryPayloadSchema.partial().safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })
  }

  const updated = await prisma.dictionaryEntry.update({
    where: { id },
    data: {
      ...parsed.data,
      ...(parsed.data.vietnameseText || parsed.data.keywords
        ? {
            searchText: normalizeVietnameseSearch(
              `${parsed.data.vietnameseText ?? ''} ${(parsed.data.keywords ?? []).join(' ')}`,
            ),
          }
        : {}),
      ...(parsed.data.keywords ? { keywords: normalizeKeywordList(parsed.data.keywords) } : {}),
    },
  })

  await writeAdminAudit(prisma, auth.admin.userId, 'DICTIONARY_UPDATE', 'dictionary-entry', String(id), {
    fields: Object.keys(parsed.data),
  })

  return NextResponse.json({ entry: updated })
}

export async function DELETE(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response
  const { id: idParam } = await params
  const id = Number(idParam)
  if (!Number.isFinite(id)) return NextResponse.json({ error: 'Invalid id' }, { status: 400 })

  await prisma.dictionaryEntry.delete({
    where: { id },
  })

  await writeAdminAudit(prisma, auth.admin.userId, 'DICTIONARY_UPDATE', 'dictionary-entry', String(id), {
    deleted: true,
  })

  return NextResponse.json({ success: true })
}
