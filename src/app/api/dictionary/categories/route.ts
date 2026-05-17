import { NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'

export async function GET() {
  const categories = await prisma.dictionaryCategory.findMany({
    orderBy: [{ name: 'asc' }],
    include: {
      _count: {
        select: {
          entries: true,
        },
      },
    },
  })

  return NextResponse.json({
    categories: categories.map((item: Record<string, any>) => ({
      slug: item.slug,
      name: item.name,
      description: item.description ?? null,
      publishedCount: item._count?.entries ?? 0,
    })),
  })
}
