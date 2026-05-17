import Link from 'next/link'
import { notFound } from 'next/navigation'
import { prisma } from '@/app/lib/db'
import DictionaryPlayer from '@/components/dictionary/DictionaryPlayer'

export default async function DictionaryDetailPage({ params }: { params: Promise<{ slug: string }> }) {
  const { slug } = await params
  const entry = await prisma.dictionaryEntry.findUnique({
    where: { slug },
    include: { category: true },
  })
  if (!entry || entry.status !== 'PUBLISHED' || (!entry.videoUrl && !entry.videoKey)) {
    notFound()
  }

  const related = await prisma.dictionaryEntry.findMany({
    where: {
      status: 'PUBLISHED',
      categoryId: entry.categoryId,
      slug: { not: slug },
    },
    orderBy: [{ updatedAt: 'desc' }],
    take: 6,
  })

  return (
    <main style={{ minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 24 }}>
      <Link href="/dictionary" style={{ color: '#2563EB', textDecoration: 'none', fontWeight: 600 }}>Back to dictionary</Link>
      <section style={{ display: 'grid', gap: 24, gridTemplateColumns: 'minmax(0, 2fr) minmax(280px, 1fr)' }}>
        <div style={{ display: 'grid', gap: 16 }}>
          <DictionaryPlayer src={entry.videoUrl ?? entry.videoKey ?? ''} poster={entry.thumbnailUrl} />
          <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
            {Array.isArray(entry.keywords) ? entry.keywords.map((keyword) => (
              <span key={String(keyword)} style={{ padding: '6px 10px', borderRadius: 999, background: '#F3F4F6', fontSize: 14, color: '#6B7280' }}>
                {String(keyword)}
              </span>
            )) : null}
          </div>
        </div>
        <aside style={{ display: 'grid', gap: 16, alignContent: 'start' }}>
          <div style={{ padding: 24, borderRadius: 8, background: '#F3F4F6', border: '1px solid #E5E7EB' }}>
            <p style={{ margin: 0, color: '#6B7280', fontSize: 14, fontWeight: 600 }}>{entry.category.name}</p>
            <h1 style={{ margin: '8px 0 12px', fontSize: 28, fontWeight: 600 }}>{entry.vietnameseText}</h1>
            <p style={{ margin: 0, color: '#6B7280', fontSize: 16 }}>Updated {entry.updatedAt.toLocaleDateString('vi-VN')}</p>
          </div>
          <div style={{ padding: 24, borderRadius: 8, background: '#F3F4F6', border: '1px solid #E5E7EB', display: 'grid', gap: 12 }}>
            <h2 style={{ margin: 0, fontSize: 20, fontWeight: 600 }}>Related signs</h2>
            {related.length === 0 ? <p style={{ margin: 0, color: '#6B7280' }}>No published signs in this category yet.</p> : related.map((item) => (
              <Link key={item.id} href={`/dictionary/${item.slug}`} style={{ color: '#101010', textDecoration: 'none' }}>
                {item.vietnameseText}
              </Link>
            ))}
          </div>
        </aside>
      </section>
    </main>
  )
}
