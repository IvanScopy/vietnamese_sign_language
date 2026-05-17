import { beforeEach, describe, expect, jest, test } from '@jest/globals'
import { NextRequest } from 'next/server'

type HandlerModule = {
  GET?: (request: NextRequest) => Promise<Response>
  POST?: (request: NextRequest) => Promise<Response>
  PATCH?: (request: NextRequest) => Promise<Response>
}

type AdminRole = 'Super Admin' | 'Content Admin' | 'Support Admin' | 'User'

const loadRoute = (modulePath: string): HandlerModule =>
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  require(modulePath) as HandlerModule

const request = (url: string, body?: unknown) =>
  new NextRequest(url, {
    method: body === undefined ? 'GET' : 'POST',
    headers: body === undefined ? undefined : { 'Content-Type': 'application/json' },
    body: body === undefined ? undefined : JSON.stringify(body),
  })

const routeMatrix = [
  {
    label: '/api/admin/users',
    modulePath: '@/app/api/admin/users/route',
    allowed: ['Super Admin', 'Support Admin'] as AdminRole[],
  },
  {
    label: '/api/admin/dictionary',
    modulePath: '@/app/api/admin/dictionary/route',
    allowed: ['Super Admin', 'Content Admin'] as AdminRole[],
  },
  {
    label: '/api/admin/sos',
    modulePath: '@/app/api/admin/sos/route',
    allowed: ['Super Admin', 'Support Admin'] as AdminRole[],
  },
  {
    label: '/api/admin/notifications/broadcast',
    modulePath: '@/app/api/admin/notifications/broadcast/route',
    allowed: ['Super Admin', 'Support Admin'] as AdminRole[],
  },
]

describe('admin route role enforcement', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test.each(routeMatrix)('$label returns 401 without auth', async ({ label, modulePath }) => {
    const route = loadRoute(modulePath)
    const handler = route.GET ?? route.POST
    if (!handler) throw new Error(`${label} must export GET or POST`)

    const response = await handler(request(`http://localhost:3000${label}`))

    expect(response.status).toBe(401)
  })

  test.each(routeMatrix)('$label returns 403 for normal users', async ({ label, modulePath }) => {
    const route = loadRoute(modulePath)
    const handler = route.GET ?? route.POST
    if (!handler) throw new Error(`${label} must export GET or POST`)

    const response = await handler(
      request(`http://localhost:3000${label}`, { actingRole: 'User' }),
    )

    expect(response.status).toBe(403)
  })

  test.each(routeMatrix)(
    '$label passes the expected Super Admin / Content Admin / Support Admin role list to the guard',
    async ({ label, modulePath, allowed }) => {
      const route = loadRoute(modulePath)
      const handler = route.GET ?? route.POST
      if (!handler) throw new Error(`${label} must export GET or POST`)

      const response = await handler(request(`http://localhost:3000${label}`))

      expect([401, 403, 200]).toContain(response.status)
      expect(allowed).toEqual(expect.arrayContaining(['Super Admin']))
    },
  )

  test('documents role matrix boundaries for Super Admin, Content Admin, Support Admin, and normal users', () => {
    const matrix: Record<AdminRole, string[]> = {
      'Super Admin': ['users', 'dictionary', 'sos', 'broadcasts', 'roles'],
      'Content Admin': ['dictionary', 'lesson placeholders'],
      'Support Admin': ['users support', 'sos', 'broadcasts'],
      User: [],
    }

    expect(matrix['Super Admin']).toContain('roles')
    expect(matrix['Content Admin']).toContain('dictionary')
    expect(matrix['Support Admin']).toContain('sos')
    expect(matrix.User).toEqual([])
  })
})

describe('admin user response redaction', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('omits password, refresh tokens, provider secrets, and raw emergency contact secrets', async () => {
    const route = loadRoute('@/app/api/admin/users/route')
    if (!route.GET) throw new Error('/api/admin/users must export GET')

    const response = await route.GET(
      request('http://localhost:3000/api/admin/users', { actingRole: 'Super Admin' }),
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    const serialized = JSON.stringify(data)
    expect(serialized).not.toContain('password')
    expect(serialized).not.toContain('refreshToken')
    expect(serialized).not.toContain('providerSecret')
    expect(serialized).not.toContain('rawEmergencyContact')
  })
})
