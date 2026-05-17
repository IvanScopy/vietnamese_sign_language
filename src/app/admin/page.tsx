import Link from 'next/link'
import type { CSSProperties } from 'react'

export default function AdminPage() {
  return (
    <main style={{ minHeight: '100vh', padding: 24, background: '#FFFFFF', color: '#101010', display: 'grid', gap: 24 }}>
      <header style={{ display: 'grid', gap: 8 }}>
        <h1 style={{ margin: 0, fontSize: 28, fontWeight: 600 }}>Admin</h1>
        <nav aria-label="Admin" style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
          <Link href="/admin/users" style={adminNavStyle}>Users</Link>
          <Link href="/admin/dictionary" style={adminNavStyle}>Dictionary</Link>
          <Link href="/admin/lessons" style={adminNavStyle}>Lesson placeholders</Link>
          <Link href="/admin/sos" style={adminNavStyle}>SOS logs</Link>
          <Link href="/admin/broadcasts" style={adminNavStyle}>Broadcasts</Link>
          <Link href="/admin/audit" style={adminNavStyle}>Audit logs</Link>
        </nav>
      </header>
      <section style={{ display: 'grid', gap: 16, gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}>
        {[
          ['Users', '/admin/users', 'Manage users, roles, and account access.'],
          ['Dictionary', '/admin/dictionary', 'Review published and draft sign entries.'],
          ['Lesson placeholders', '/admin/lessons', 'Prepare lesson structures for future curriculum work.'],
          ['SOS logs', '/admin/sos', 'Inspect emergency incidents and fallback states.'],
          ['Broadcasts', '/admin/broadcasts', 'Preview and confirm targeted notifications.'],
          ['Audit logs', '/admin/audit', 'Inspect sensitive admin actions.'],
        ].map(([label, href, body]) => (
          <Link key={href} href={href} style={{ display: 'grid', gap: 8, padding: 20, background: '#F3F4F6', borderRadius: 8, border: '1px solid #E5E7EB', textDecoration: 'none', color: '#101010' }}>
            <strong>{label}</strong>
            <span style={{ color: '#6B7280' }}>{body}</span>
          </Link>
        ))}
      </section>
    </main>
  )
}

const adminNavStyle: CSSProperties = { color: '#101010', textDecoration: 'none', fontSize: 16, fontWeight: 600 }
