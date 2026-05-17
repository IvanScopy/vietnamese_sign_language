import { NextRequest, NextResponse } from 'next/server'
import { z } from 'zod'
import { requireAdminRole } from '@/app/lib/admin-auth'
import { StoragePresignSchema } from '@/app/lib/validators'
import { createDictionaryUploadUrl } from '@/app/lib/storage'
import { prisma } from '@/app/lib/db'

export async function POST(request: NextRequest) {
  const auth = await requireAdminRole(request, ['Super Admin', 'Content Admin'])
  if (!auth.ok) return auth.response

  const body = await request.json()
  const parsed = StoragePresignSchema.extend({
    kind: z.enum(['video', 'thumbnail']),
    entryId: z.number().int().positive().optional(),
  }).safeParse(body)
  if (!parsed.success) {
    return NextResponse.json({ errors: parsed.error.flatten() }, { status: 400 })
  }

  const key = parsed.data.entryId
    ? `dictionary/${parsed.data.entryId}/${parsed.data.kind}/${parsed.data.key}`
    : `dictionary/unassigned/${parsed.data.kind}/${parsed.data.key}`
  const result = await createDictionaryUploadUrl(key, parsed.data.contentType)

  await prisma.dictionaryUpload.create({
    data: {
      dictionaryEntryId: parsed.data.entryId,
      storageKey: result.key,
      contentType: parsed.data.contentType,
      kind: parsed.data.kind,
    },
  })

  return NextResponse.json(result)
}
