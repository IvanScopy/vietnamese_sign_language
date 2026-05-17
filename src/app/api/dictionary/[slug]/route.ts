import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'

export async function GET(
  _request: NextRequest,
  { params }: { params: Promise<{ slug: string }> },
) {
  const { slug } = await params
  if (!slug) {
    return NextResponse.json({ error: 'Missing slug' }, { status: 400 })
  }

  const entry = await prisma.dictionaryEntry.findUnique({
    where: { slug },
    include: { category: true },
  })

  if (!entry || entry.status !== 'PUBLISHED' || (!entry.videoUrl && !entry.videoKey)) {
    return NextResponse.json({ error: 'Not found' }, { status: 404 })
  }

  const related = await prisma.dictionaryEntry.findMany({
    where: {
      status: 'PUBLISHED',
      categoryId: entry.categoryId,
      slug: { not: slug },
    },
    include: { category: true },
    take: 4,
    orderBy: [{ updatedAt: 'desc' }, { slug: 'asc' }],
  })

  return NextResponse.json({
    entry: {
      id: entry.id,
      slug: entry.slug,
      vietnameseText: entry.vietnameseText ?? (entry as Record<string, any>).term,
      status: entry.status,
      category: entry.category,
      videoUrl: entry.videoUrl ?? null,
      videoKey: entry.videoKey ?? null,
      thumbnailUrl: entry.thumbnailUrl ?? null,
      thumbnailKey: entry.thumbnailKey ?? null,
      keywords: Array.isArray(entry.keywords) ? entry.keywords : (entry.keywords as string[] | null) ?? [],
      updatedAt: entry.updatedAt.toISOString(),
      playbackSpeeds: [0.5, 0.75, 1],
    },
    related: related.map((item: Record<string, any>) => ({
      id: item.id,
      slug: item.slug,
      vietnameseText: item.vietnameseText ?? item.term,
      category: item.category,
      thumbnailUrl: item.thumbnailUrl ?? null,
      thumbnailKey: item.thumbnailKey ?? null,
    })),
  })
}
