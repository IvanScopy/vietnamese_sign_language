import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { DictionaryEntryPayloadSchema } from '@/app/lib/validators'
import { normalizeKeywordList, normalizeVietnameseSearch } from '@/app/lib/dictionary-search'
import { writeAdminAudit } from '@/app/lib/audit'

export async function GET(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response

  const entries = await prisma.dictionaryEntry.findMany({
    include: { category: true },
    orderBy: [{ updatedAt: 'desc' }, { slug: 'asc' }],
  })

  return NextResponse.json({ entries })
}

export async function POST(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response

  const body = await request.json()
  const parsed = DictionaryEntryPayloadSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })
  }

  const entry = await prisma.dictionaryEntry.create({
    data: {
      ...parsed.data,
      searchText: normalizeVietnameseSearch(
        `${parsed.data.vietnameseText} ${parsed.data.keywords.join(' ')}`,
      ),
      keywords: normalizeKeywordList(parsed.data.keywords),
    },
  })

  await writeAdminAudit(prisma, auth.admin.userId, 'DICTIONARY_CREATE', 'dictionary-entry', String(entry.id), {
    slug: entry.slug,
  })

  return NextResponse.json({ entry }, { status: 201 })
}
