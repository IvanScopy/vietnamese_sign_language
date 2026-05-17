'use client'

import { useEffect, useState, type CSSProperties } from 'react'

type ProfileData = {
  id: number
  email: string
  name: string | null
  userType: string
  emergencyContacts: Array<{ id: number; name: string; phone: string }>
}

export default function ProfilePage() {
  const [profile, setProfile] = useState<ProfileData | null>(null)
  const [status, setStatus] = useState<'loading' | 'ready' | 'unauthorized' | 'error'>('loading')

  useEffect(() => {
    fetch('/api/user/profile', { credentials: 'include' })
      .then(async (response) => {
        if (response.status === 401 || response.status === 403) {
          setStatus('unauthorized')
          return
        }
        if (!response.ok) throw new Error('profile')
        const data = await response.json()
        setProfile(data.user)
        setStatus('ready')
      })
      .catch(() => setStatus('error'))
  }, [])

  return (
    <main style={{ minHeight: '100vh', background: '#FFFFFF', padding: 24, color: '#101010', display: 'grid', gap: 24 }}>
      <h1 style={{ margin: 0, fontSize: 28, fontWeight: 600 }}>Profile</h1>
      {status === 'loading' ? <p>Loading profile...</p> : null}
      {status === 'unauthorized' ? <p>Your session expired. Log in again to continue.</p> : null}
      {status === 'error' ? <p>We could not load this content. Check your connection and try again.</p> : null}
      {status === 'ready' && profile ? (
        <>
          <section style={panelStyle}>
            <h2 style={sectionTitleStyle}>Account</h2>
            <p style={bodyStyle}><strong>Name:</strong> {profile.name ?? 'Not set'}</p>
            <p style={bodyStyle}><strong>Email:</strong> {profile.email}</p>
            <p style={bodyStyle}><strong>User type:</strong> {profile.userType}</p>
          </section>
          <section style={panelStyle}>
            <h2 style={sectionTitleStyle}>Emergency contacts</h2>
            {profile.emergencyContacts.length === 0 ? <p style={bodyStyle}>No emergency contacts linked yet.</p> : profile.emergencyContacts.map((contact) => (
              <p key={contact.id} style={bodyStyle}>{contact.name} - {contact.phone}</p>
            ))}
          </section>
        </>
      ) : null}
    </main>
  )
}

const panelStyle: CSSProperties = { background: '#F3F4F6', border: '1px solid #E5E7EB', borderRadius: 8, padding: 24 }
const sectionTitleStyle: CSSProperties = { margin: '0 0 12px', fontSize: 20, fontWeight: 600 }
const bodyStyle: CSSProperties = { margin: '8px 0', fontSize: 16, lineHeight: 1.5 }
