import Link from 'next/link'
import type { CSSProperties } from 'react'

export default function Home() {
  return (
    <main style={{ minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 24 }}>
      <header style={{ display: 'grid', gap: 12 }}>
        <h1 style={{ margin: 0, fontSize: 28, fontWeight: 600 }}>VSL Bridge</h1>
        <nav aria-label="Primary" style={{ display: 'flex', gap: 16, flexWrap: 'wrap' }}>
          <Link href="/dictionary" style={navLinkStyle}>Dictionary</Link>
          <Link href="/recognition" style={navLinkStyle}>Recognition</Link>
          <Link href="/calls" style={navLinkStyle}>Calls</Link>
          <Link href="/profile" style={navLinkStyle}>Profile</Link>
          <Link href="/notifications" style={navLinkStyle}>Notifications</Link>
        </nav>
      </header>
      <section style={{ display: 'grid', gap: 16, gridTemplateColumns: 'repeat(auto-fit, minmax(220px, 1fr))' }}>
        <Link href="/dictionary" style={panelCardStyle}>
          <strong>Dictionary</strong>
          <span style={mutedStyle}>Search and browse 4,362 published VSL videos.</span>
        </Link>
        <Link href="/recognition" style={panelCardStyle}>
          <strong>Recognition</strong>
          <span style={mutedStyle}>Use your webcam to recognize Vietnamese signs.</span>
        </Link>
        <Link href="/calls" style={panelCardStyle}>
          <strong>Calls</strong>
          <span style={mutedStyle}>Continue existing web video-call flows.</span>
        </Link>
        <Link href="/profile" style={panelCardStyle}>
          <strong>Profile</strong>
          <span style={mutedStyle}>Review account state and emergency contacts.</span>
        </Link>
      </section>
      <section style={{ background: '#F3F4F6', border: '1px solid #E5E7EB', borderRadius: 8, padding: 24 }}>
        <p style={{ margin: 0, fontSize: 16, color: '#6B7280' }}>Your session expired. Log in again to continue.</p>
        <button type="button" style={{ marginTop: 16, minHeight: 48, padding: '12px 20px', borderRadius: 8, background: '#2563EB', color: '#FFFFFF', border: 'none', fontWeight: 600 }}>
          Log in
        </button>
      </section>
    </main>
  )
}

const navLinkStyle: CSSProperties = { color: '#101010', textDecoration: 'none', fontSize: 16, fontWeight: 600 }
const panelCardStyle: CSSProperties = { display: 'grid', gap: 8, padding: 24, borderRadius: 8, border: '1px solid #E5E7EB', background: '#F3F4F6', textDecoration: 'none', color: '#101010' }
const mutedStyle: CSSProperties = { color: '#6B7280', fontSize: 16, lineHeight: 1.5 }
