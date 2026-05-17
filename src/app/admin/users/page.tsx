import { prisma } from '@/app/lib/db'
import type { CSSProperties } from 'react'

export default async function AdminUsersPage() {
  const users = await prisma.user.findMany({ orderBy: [{ createdAt: 'desc' }], take: 100 })
  return (
    <main style={adminPageStyle}>
      <h1 style={adminTitleStyle}>Users</h1>
      <table style={tableStyle}>
        <thead><tr><th>Email</th><th>Name</th><th>User type</th><th>Active</th><th>Role</th></tr></thead>
        <tbody>
          {users.map((user) => (
            <tr key={user.id}>
              <td>{user.email}</td>
              <td>{user.name ?? '—'}</td>
              <td>{user.userType}</td>
              <td>{user.isActive ? 'Active' : 'Disabled'}</td>
              <td>{user.adminRole ?? 'User'}</td>
            </tr>
          ))}
        </tbody>
      </table>
    </main>
  )
}

const adminPageStyle: CSSProperties = { minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 16 }
const adminTitleStyle: CSSProperties = { margin: 0, fontSize: 28, fontWeight: 600 }
const tableStyle: CSSProperties = { width: '100%', borderCollapse: 'collapse', background: '#F3F4F6' }
