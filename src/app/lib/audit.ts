import type { Prisma } from '@prisma/client'
import { prisma } from '@/app/lib/db'

export type AdminAuditActionName =
  | 'USER_DEACTIVATE'
  | 'USER_REACTIVATE'
  | 'ADMIN_ROLE_CHANGE'
  | 'USER_TYPE_CHANGE'
  | 'DICTIONARY_CREATE'
  | 'DICTIONARY_UPDATE'
  | 'DICTIONARY_PUBLISH'
  | 'DICTIONARY_UNPUBLISH'
  | 'BROADCAST_PREVIEW'
  | 'BROADCAST_SEND'
  | 'SOS_REVIEW'
  | 'LESSON_PLACEHOLDER_UPDATE'

type AuditClient = typeof prisma

export async function writeAdminAudit(
  txOrPrisma: AuditClient,
  actorUserId: number,
  action: AdminAuditActionName,
  targetType: string,
  targetId: string,
  metadata: Prisma.InputJsonValue = {},
) {
  return txOrPrisma.adminAuditLog.create({
    data: {
      actorUserId,
      action,
      targetType,
      targetId,
      metadata,
    },
  })
}
