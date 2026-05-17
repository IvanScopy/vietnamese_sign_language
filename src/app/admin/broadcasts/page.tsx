import { prisma } from '@/app/lib/db'
import type { CSSProperties } from 'react'

export default async function AdminBroadcastsPage() {
  const broadcasts = await prisma.broadcastMessage.findMany({ orderBy: [{ createdAt: 'desc' }], take: 100 })
  return (
    <main style={adminPageStyle}>
      <h1 style={adminTitleStyle}>Broadcasts</h1>
      {broadcasts.length === 0 ? <div style={adminCardStyle}>No broadcasts yet.</div> : broadcasts.map((broadcast) => (
        <div key={broadcast.id} style={adminCardStyle}>
          <strong>{broadcast.title}</strong>
          <p style={{ margin: '8px 0', color: '#6B7280' }}>{broadcast.targetGroup}</p>
          <p style={{ margin: 0, color: '#6B7280' }}>{broadcast.sentAt ? 'Sent' : 'Preview only'}</p>
        </div>
      ))}
    </main>
  )
}

const adminPageStyle: CSSProperties = { minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 16 }
const adminTitleStyle: CSSProperties = { margin: 0, fontSize: 28, fontWeight: 600 }
const adminCardStyle: CSSProperties = { padding: 16, background: '#F3F4F6', borderRadius: 8, border: '1px solid #E5E7EB' }
