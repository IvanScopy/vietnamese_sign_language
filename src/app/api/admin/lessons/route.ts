import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { LessonPlaceholderSchema } from '@/app/lib/validators'
import { writeAdminAudit } from '@/app/lib/audit'

export async function GET(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response

  const lessons = await prisma.lessonPlaceholder.findMany({
    orderBy: [{ updatedAt: 'desc' }],
  })
  return NextResponse.json({ lessons })
}

export async function POST(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response
  const body = await request.json()
  const parsed = LessonPlaceholderSchema.safeParse(body)
  if (!parsed.success) return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })

  const lesson = await prisma.lessonPlaceholder.create({ data: parsed.data })
  await writeAdminAudit(prisma, auth.admin.userId, 'LESSON_PLACEHOLDER_UPDATE', 'lesson-placeholder', String(lesson.id), { created: true })
  return NextResponse.json({ lesson }, { status: 201 })
}

export async function PATCH(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response
  const body = await request.json()
  const id = Number(body.id)
  if (!Number.isFinite(id)) return NextResponse.json({ error: 'Lesson id is required' }, { status: 400 })
  const parsed = LessonPlaceholderSchema.partial().safeParse(body)
  if (!parsed.success) return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })

  const lesson = await prisma.lessonPlaceholder.update({
    where: { id },
    data: parsed.data,
  })
  await writeAdminAudit(prisma, auth.admin.userId, 'LESSON_PLACEHOLDER_UPDATE', 'lesson-placeholder', String(id), { updated: true })
  return NextResponse.json({ lesson })
}
