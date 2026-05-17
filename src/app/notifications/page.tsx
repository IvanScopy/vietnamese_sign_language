import { prisma } from '@/app/lib/db'

export default async function NotificationsPage() {
  const notifications = await prisma.notification.findMany({
    orderBy: [{ createdAt: 'desc' }],
    take: 50,
  })

  return (
    <main style={{ minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 24 }}>
      <header>
        <h1 style={{ margin: 0, fontSize: 28, fontWeight: 600 }}>Notifications</h1>
        <p style={{ margin: '8px 0 0', fontSize: 16, color: '#6B7280' }}>
          Web SOS is informational only. Use the mobile app for SMS, native dialer, and reliable emergency location flows.
        </p>
      </header>
      <section style={{ display: 'grid', gap: 12 }}>
        {notifications.length === 0 ? (
          <div style={{ padding: 24, background: '#F3F4F6', borderRadius: 8 }}>No notifications yet.</div>
        ) : notifications.map((notification) => (
          <article key={notification.id} style={{ padding: 16, background: '#F3F4F6', borderRadius: 8, border: '1px solid #E5E7EB' }}>
            <strong style={{ display: 'block', marginBottom: 8 }}>{notification.title}</strong>
            <p style={{ margin: 0 }}>{notification.body}</p>
          </article>
        ))}
      </section>
    </main>
  )
}
