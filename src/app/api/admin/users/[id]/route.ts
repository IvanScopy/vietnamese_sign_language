import { NextRequest, NextResponse } from 'next/server'
import { prisma } from '@/app/lib/db'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { writeAdminAudit } from '@/app/lib/audit'
import { AdminUserUpdateSchema } from '@/app/lib/validators'

const ADMIN_ROLE_INPUT_MAP = {
  'Super Admin': 'SUPER_ADMIN',
  'Content Admin': 'CONTENT_ADMIN',
  'Support Admin': 'SUPPORT_ADMIN',
} as const

export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> },
) {
  const { id } = await params
  const userId = Number(id)
  if (!Number.isFinite(userId)) {
    return NextResponse.json({ error: 'Invalid user id' }, { status: 400 })
  }

  const auth = await requireAdminRole(request, ['Super Admin', 'Support Admin'])
  if (!auth.ok) return auth.response

  const body = await request.json()
  const parsed = AdminUserUpdateSchema.safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })
  }

  if ((parsed.data.adminRole || parsed.data.userType) && auth.admin.role !== 'Super Admin') {
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 })
  }

  const targetUser = await prisma.user.findUnique({
    where: { id: userId },
    select: { id: true, isActive: true, adminRole: true },
  })

  if (!targetUser) {
    return NextResponse.json({ error: 'User not found' }, { status: 404 })
  }

  if (parsed.data.active === false && targetUser.adminRole === 'SUPER_ADMIN') {
    const activeSuperAdmins = await prisma.user.count({
      where: { adminRole: 'SUPER_ADMIN', isActive: true },
    })
    if (activeSuperAdmins <= 1) {
      return NextResponse.json({ error: 'Cannot deactivate the last active Super Admin' }, { status: 409 })
    }
    if (auth.admin.userId === userId) {
      return NextResponse.json({ error: 'Self-deactivation is not allowed' }, { status: 409 })
    }
  }

  const updatedUser = await prisma.$transaction(async (tx) => {
    const user = await tx.user.update({
      where: { id: userId },
      data: {
        ...(parsed.data.active !== undefined ? { isActive: parsed.data.active } : {}),
        ...(parsed.data.adminRole
          ? {
              adminRole: ADMIN_ROLE_INPUT_MAP[parsed.data.adminRole],
            }
          : {}),
        ...(parsed.data.userType ? { userType: parsed.data.userType } : {}),
      },
    })

    if (parsed.data.active === false) {
      await tx.refreshToken.deleteMany({
        where: { userId },
      })
    }

    return user
  })

  if (parsed.data.active === false) {
    await writeAdminAudit(prisma, auth.admin.userId, 'USER_DEACTIVATE', 'user', String(userId), {
      active: false,
    })
  }

  if (parsed.data.active === true) {
    await writeAdminAudit(prisma, auth.admin.userId, 'USER_REACTIVATE', 'user', String(userId), {
      active: true,
    })
  }

  if (parsed.data.adminRole) {
    await writeAdminAudit(prisma, auth.admin.userId, 'ADMIN_ROLE_CHANGE', 'user', String(userId), {
      adminRole: parsed.data.adminRole,
    })
  }

  if (parsed.data.userType) {
    await writeAdminAudit(prisma, auth.admin.userId, 'USER_TYPE_CHANGE', 'user', String(userId), {
      userType: parsed.data.userType,
    })
  }

  const responseUser = updatedUser ?? {
    id: userId,
    email: null,
    name: null,
    userType: parsed.data.userType ?? null,
    isActive: parsed.data.active ?? true,
    adminRole: parsed.data.adminRole ?? null,
  }

  return NextResponse.json({
    user: {
      id: responseUser.id,
      email: responseUser.email,
      name: responseUser.name ?? null,
      userType: responseUser.userType,
      isActive: responseUser.isActive ?? true,
      adminRole: responseUser.adminRole ?? null,
    },
  })
}
