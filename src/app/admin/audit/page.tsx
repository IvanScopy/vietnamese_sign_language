import { prisma } from '@/app/lib/db'
import type { CSSProperties } from 'react'

export default async function AdminAuditPage() {
  const logs = await prisma.adminAuditLog.findMany({ orderBy: [{ createdAt: 'desc' }], take: 100, include: { actorUser: true } })
  return (
    <main style={adminPageStyle}>
      <h1 style={adminTitleStyle}>Audit logs</h1>
      {logs.map((log) => (
        <div key={log.id} style={adminCardStyle}>
          <strong>{log.action}</strong>
          <p style={{ margin: '8px 0', color: '#6B7280' }}>{log.targetType} · {log.targetId}</p>
          <p style={{ margin: 0, color: '#6B7280' }}>{log.actorUser.email}</p>
        </div>
      ))}
    </main>
  )
}

const adminPageStyle: CSSProperties = { minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 16 }
const adminTitleStyle: CSSProperties = { margin: 0, fontSize: 28, fontWeight: 600 }
const adminCardStyle: CSSProperties = { padding: 16, background: '#F3F4F6', borderRadius: 8, border: '1px solid #E5E7EB' }
