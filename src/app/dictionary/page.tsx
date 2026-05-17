import type { CSSProperties } from 'react'
import Link from 'next/link'
import { prisma } from '@/app/lib/db'

export default async function DictionaryPage({
  searchParams,
}: {
  searchParams?: Promise<Record<string, string | string[] | undefined>>
}) {
  const params = searchParams ? await searchParams : {}
  const q = typeof params.q === 'string' ? params.q : typeof params.search === 'string' ? params.search : ''
  const category = typeof params.category === 'string' ? params.category : ''

  const categories = await prisma.dictionaryCategory.findMany({
    orderBy: [{ name: 'asc' }],
    include: { _count: { select: { entries: true } } },
  })

  const entries = await prisma.dictionaryEntry.findMany({
    where: {
      status: 'PUBLISHED',
      ...(category ? { category: { slug: category } } : {}),
      ...(q ? { searchText: { contains: q.toLowerCase() } } : {}),
    },
    include: { category: true },
    orderBy: [{ updatedAt: 'desc' }],
    take: 60,
  })

  return (
    <main style={pageStyle}>
      <header style={headerStyle}>
        <div>
          <p style={eyebrowStyle}>Dictionary</p>
          <h1 style={titleStyle}>Search signs</h1>
          <p style={bodyStyle}>Browse Vietnamese sign videos stored in your live dictionary.</p>
        </div>
        <Link href="/" style={linkButtonStyle}>Back to app</Link>
      </header>

      <form action="/dictionary" style={panelStyle}>
        <label htmlFor="search" style={labelStyle}>Search signs</label>
        <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
          <input id="search" name="q" defaultValue={q} placeholder="Search signs" style={inputStyle} />
          <button type="submit" style={primaryButtonStyle}>Search signs</button>
        </div>
      </form>

      <section style={panelStyle}>
        <h2 style={sectionTitleStyle}>Categories</h2>
        <div style={gridStyle}>
          {categories.map((item) => (
            <Link key={item.id} href={`/dictionary?category=${item.slug}`} style={cardStyle}>
              <strong style={{ fontSize: 16 }}>{item.name}</strong>
              <span style={mutedStyle}>{item._count.entries} published signs</span>
            </Link>
          ))}
        </div>
      </section>

      <section style={panelStyle}>
        <h2 style={sectionTitleStyle}>Results</h2>
        {entries.length === 0 ? (
          <div style={emptyStyle}>
            <h3 style={{ margin: 0, fontSize: 20 }}>No signs found</h3>
            <p style={bodyStyle}>Try another Vietnamese word or choose a category.</p>
          </div>
        ) : (
          <div style={resultGridStyle}>
            {entries.map((entry) => (
              <Link key={entry.id} href={`/dictionary/${entry.slug}`} style={cardStyle}>
                <div style={thumbnailFrameStyle}>
                  {entry.thumbnailUrl ? (
                    // eslint-disable-next-line @next/next/no-img-element
                    <img src={entry.thumbnailUrl} alt={entry.vietnameseText} style={thumbnailStyle} />
                  ) : (
                    <div style={thumbnailFallbackStyle}>No thumbnail</div>
                  )}
                </div>
                <strong style={{ fontSize: 16 }}>{entry.vietnameseText}</strong>
                <span style={mutedStyle}>{entry.category.name}</span>
              </Link>
            ))}
          </div>
        )}
      </section>
    </main>
  )
}

const pageStyle: CSSProperties = { minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 24 }
const headerStyle: CSSProperties = { display: 'flex', justifyContent: 'space-between', gap: 16, alignItems: 'flex-start', flexWrap: 'wrap' }
const eyebrowStyle: CSSProperties = { margin: 0, color: '#6B7280', fontSize: 14, fontWeight: 600 }
const titleStyle: CSSProperties = { margin: '8px 0', fontSize: 28, fontWeight: 600 }
const bodyStyle: CSSProperties = { margin: 0, fontSize: 16, color: '#6B7280', lineHeight: 1.5 }
const panelStyle: CSSProperties = { background: '#F3F4F6', border: '1px solid #E5E7EB', borderRadius: 8, padding: 24, display: 'grid', gap: 16 }
const labelStyle: CSSProperties = { fontSize: 14, fontWeight: 600 }
const inputStyle: CSSProperties = { minHeight: 48, flex: '1 1 260px', padding: '12px 16px', border: '1px solid #E5E7EB', borderRadius: 8, fontSize: 16 }
const primaryButtonStyle: CSSProperties = { minHeight: 48, padding: '12px 20px', border: 'none', borderRadius: 8, background: '#2563EB', color: '#FFFFFF', fontSize: 16, fontWeight: 600 }
const linkButtonStyle: CSSProperties = { ...primaryButtonStyle, textDecoration: 'none', display: 'inline-flex', alignItems: 'center' }
const sectionTitleStyle: CSSProperties = { margin: 0, fontSize: 20, fontWeight: 600 }
const gridStyle: CSSProperties = { display: 'grid', gap: 16, gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))' }
const resultGridStyle: CSSProperties = { display: 'grid', gap: 16, gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }
const cardStyle: CSSProperties = { display: 'grid', gap: 8, padding: 16, borderRadius: 8, border: '1px solid #E5E7EB', background: '#FFFFFF', color: '#101010', textDecoration: 'none' }
const mutedStyle: CSSProperties = { color: '#6B7280', fontSize: 14 }
const emptyStyle: CSSProperties = { display: 'grid', gap: 8, padding: 32, borderRadius: 8, background: '#FFFFFF' }
const thumbnailFrameStyle: CSSProperties = { aspectRatio: '16 / 9', borderRadius: 8, overflow: 'hidden', background: '#E5E7EB' }
const thumbnailStyle: CSSProperties = { width: '100%', height: '100%', objectFit: 'cover' }
const thumbnailFallbackStyle: CSSProperties = { width: '100%', height: '100%', display: 'grid', placeItems: 'center', color: '#6B7280', fontSize: 14 }
