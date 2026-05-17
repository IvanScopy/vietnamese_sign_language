import Link from 'next/link'
import { prisma } from '@/app/lib/db'
import type { CSSProperties } from 'react'

export default async function AdminDictionaryPage() {
  const entries = await prisma.dictionaryEntry.findMany({ include: { category: true }, take: 100, orderBy: [{ updatedAt: 'desc' }] })
  return (
    <main style={adminPageStyle}>
      <h1 style={adminTitleStyle}>Dictionary</h1>
      <div style={{ display: 'grid', gap: 12 }}>
        {entries.map((entry) => (
          <div key={entry.id} style={adminCardStyle}>
            <div>
              <strong>{entry.vietnameseText}</strong>
              <p style={{ margin: '8px 0 0', color: '#6B7280' }}>{entry.category.name} · {entry.status}</p>
            </div>
            <Link href={`/dictionary/${entry.slug}`}>Open</Link>
          </div>
        ))}
      </div>
    </main>
  )
}

const adminPageStyle: CSSProperties = { minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 16 }
const adminTitleStyle: CSSProperties = { margin: 0, fontSize: 28, fontWeight: 600 }
const adminCardStyle: CSSProperties = { display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 16, padding: 16, background: '#F3F4F6', borderRadius: 8, border: '1px solid #E5E7EB' }
