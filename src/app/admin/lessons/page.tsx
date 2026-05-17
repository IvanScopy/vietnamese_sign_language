import { prisma } from '@/app/lib/db'
import type { CSSProperties } from 'react'

export default async function AdminLessonsPage() {
  const lessons = await prisma.lessonPlaceholder.findMany({ orderBy: [{ updatedAt: 'desc' }] })
  return (
    <main style={adminPageStyle}>
      <h1 style={adminTitleStyle}>Lesson placeholders</h1>
      {lessons.length === 0 ? <div style={adminCardStyle}>No lesson placeholders created yet.</div> : lessons.map((lesson) => (
        <div key={lesson.id} style={adminCardStyle}>
          <strong>{lesson.title}</strong>
          <span style={{ color: '#6B7280' }}>{lesson.isPublished ? 'Published' : 'Draft'}</span>
        </div>
      ))}
    </main>
  )
}

const adminPageStyle: CSSProperties = { minHeight: '100vh', background: '#FFFFFF', color: '#101010', padding: 24, display: 'grid', gap: 16 }
const adminTitleStyle: CSSProperties = { margin: 0, fontSize: 28, fontWeight: 600 }
const adminCardStyle: CSSProperties = { padding: 16, background: '#F3F4F6', borderRadius: 8, border: '1px solid #E5E7EB' }
