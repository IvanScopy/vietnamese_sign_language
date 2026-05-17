import { prisma } from '@/app/lib/db'
import type { CSSProperties } from 'react'

export default async function AdminSosPage() {
  const alerts = await prisma.sOSAlert.findMany({ orderBy: [{ createdAt: 'desc' }], take: 100, include: { attempts: true } })
  return (
    <main style={adminPageStyle}>
      <h1 style={adminTitleStyle}>SOS logs</h1>
      {alerts.map((alert) => (
        <div key={alert.id} style={adminCardStyle}>
          <strong>Alert #{alert.id}</strong>
          <p style={{ margin: '8px 0', color: '#6B7280' }}>Status: {alert.status}</p>
          <p style={{ margin: 0, color: '#6B7280' }}>Attempts: {alert.attempts.length}</p>
        </div>
      ))}
    </main>
  )
}

const adminPageStyle: CSSProperties = { minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 16 }
const adminTitleStyle: CSSProperties = { margin: 0, fontSize: 28, fontWeight: 600 }
const adminCardStyle: CSSProperties = { padding: 16, background: '#F3F4F6', borderRadius: 8, border: '1px solid #E5E7EB' }
