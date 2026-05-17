import { beforeEach, describe, expect, jest, test } from '@jest/globals'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

type RouteModule = {
  POST?: (request: NextRequest, context?: { params?: Record<string, string> }) => Promise<Response>
  PATCH?: (request: NextRequest, context?: { params?: Record<string, string> }) => Promise<Response>
}

const loadRoute = (modulePath: string): RouteModule =>
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  require(modulePath) as RouteModule

const jsonRequest = (url: string, body: unknown, method = 'POST') =>
  new NextRequest(url, {
    method,
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  })

describe('admin audit logging for sensitive actions', () => {
  beforeEach(() => {
    jest.clearAllMocks()
    ;(prisma.adminAuditLog.create as jest.Mock).mockResolvedValue({ id: 1 })
  })

  test.each([
    {
      action: 'USER_DEACTIVATE',
      modulePath: '@/app/api/admin/users/[id]/route',
      method: 'PATCH',
      url: 'http://localhost:3000/api/admin/users/42',
      body: { active: false },
      params: { id: '42' },
    },
    {
      action: 'ADMIN_ROLE_CHANGE',
      modulePath: '@/app/api/admin/users/[id]/route',
      method: 'PATCH',
      url: 'http://localhost:3000/api/admin/users/42',
      body: { adminRole: 'Content Admin' },
      params: { id: '42' },
    },
    {
      action: 'DICTIONARY_PUBLISH',
      modulePath: '@/app/api/admin/dictionary/[id]/publish/route',
      method: 'POST',
      url: 'http://localhost:3000/api/admin/dictionary/99/publish',
      body: { status: 'PUBLISHED' },
      params: { id: '99' },
    },
    {
      action: 'DICTIONARY_UNPUBLISH',
      modulePath: '@/app/api/admin/dictionary/[id]/publish/route',
      method: 'POST',
      url: 'http://localhost:3000/api/admin/dictionary/99/publish',
      body: { status: 'UNPUBLISHED' },
      params: { id: '99' },
    },
    {
      action: 'BROADCAST_SEND',
      modulePath: '@/app/api/admin/notifications/broadcast/route',
      method: 'POST',
      url: 'http://localhost:3000/api/admin/notifications/broadcast',
      body: {
        mode: 'confirm',
        targetGroup: 'deaf',
        previewToken: 'preview-123',
        title: 'Test',
        body: 'Message',
      },
    },
    {
      action: 'SOS_REVIEW',
      modulePath: '@/app/api/admin/sos/[id]/review/route',
      method: 'POST',
      url: 'http://localhost:3000/api/admin/sos/123/review',
      body: { reviewed: true, note: 'Handled by support' },
      params: { id: '123' },
    },
  ])('creates AdminAuditLog row for $action', async ({ action, modulePath, method, url, body, params }) => {
    const route = loadRoute(modulePath)
    const handler = method === 'PATCH' ? route.PATCH : route.POST
    if (!handler) throw new Error(`${modulePath} must export ${method}`)

    const response = await handler(jsonRequest(url, body, method), { params })

    expect(response.status).toBeGreaterThanOrEqual(200)
    expect(response.status).toBeLessThan(300)
    expect(prisma.adminAuditLog.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          actorUserId: 7,
          action,
          targetType: expect.any(String),
          targetId: expect.any(String),
          metadata: expect.any(Object),
        }),
      }),
    )
  })

  test('broadcast preview does not write BROADCAST_SEND until confirmation', async () => {
    const route = loadRoute('@/app/api/admin/notifications/broadcast/route')
    if (!route.POST) throw new Error('/api/admin/notifications/broadcast must export POST')

    const response = await route.POST(
      jsonRequest('http://localhost:3000/api/admin/notifications/broadcast', {
        mode: 'preview',
        targetGroup: 'teacher',
        title: 'Preview',
        body: 'Preview body',
      }),
    )

    expect(response.status).toBe(200)
    expect(prisma.adminAuditLog.create).not.toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ action: 'BROADCAST_SEND' }),
      }),
    )
  })
})
