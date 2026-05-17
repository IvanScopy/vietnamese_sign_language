import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { normalizeVietnameseSearch } from '@/app/lib/dictionary-search'

function entryCard(entry: Record<string, any>) {
  return {
    id: entry.id,
    slug: entry.slug,
    vietnameseText: entry.vietnameseText ?? entry.term,
    status: entry.status,
    category: entry.category,
    thumbnailUrl: entry.thumbnailUrl ?? null,
    thumbnailKey: entry.thumbnailKey ?? null,
    videoUrl: entry.videoUrl ?? null,
    videoKey: entry.videoKey ?? null,
    updatedAt: entry.updatedAt instanceof Date ? entry.updatedAt.toISOString() : entry.updatedAt,
  }
}

export async function GET(request: NextRequest) {
  const { searchParams } = request.nextUrl
  const rawQuery = searchParams.get('q') ?? searchParams.get('search') ?? ''
  const normalizedQuery = normalizeVietnameseSearch(rawQuery)
  const category = searchParams.get('category')
  const limit = Math.min(Number(searchParams.get('limit') ?? '50') || 50, 100)

  const where: Record<string, any> = {
    status: 'PUBLISHED',
    OR: [{ videoUrl: { not: null } }, { videoKey: { not: null } }],
  }

  if (normalizedQuery) {
    where.OR = [
      { normalizedTerm: { contains: normalizedQuery } },
      { searchText: { contains: normalizedQuery } },
      { keywords: { has: normalizedQuery } },
      { keywords: { array_contains: normalizedQuery } },
    ]
  }

  if (category) {
    where.category = { slug: category }
  }

  const [entries, categories] = await Promise.all([
    prisma.dictionaryEntry.findMany({
      where,
      include: { category: true },
      orderBy: [{ updatedAt: 'desc' }, { slug: 'asc' }],
      take: limit,
    }),
    prisma.dictionaryCategory.findMany({
      orderBy: [{ name: 'asc' }],
      include: {
        _count: {
          select: {
            entries: true,
          },
        },
      },
    }),
  ])

  return NextResponse.json({
    entries: (entries ?? []).map(entryCard),
    categories: (categories ?? []).map((item: Record<string, any>) => ({
      slug: item.slug,
      name: item.name,
      description: item.description ?? null,
      publishedCount: item._count?.entries ?? 0,
    })),
  })
}
