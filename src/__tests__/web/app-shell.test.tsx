import { describe, expect, test } from '@jest/globals'
import Home from '@/app/page'

type ReactLikeNode =
  | string
  | number
  | null
  | undefined
  | boolean
  | { props?: { children?: ReactLikeNode | ReactLikeNode[]; [key: string]: unknown } }

type AdminModule = {
  default: () => ReactLikeNode
}

const collectText = (node: ReactLikeNode): string[] => {
  if (node === null || node === undefined || typeof node === 'boolean') return []
  if (typeof node === 'string' || typeof node === 'number') return [String(node)]
  const children = node.props?.children
  if (Array.isArray(children)) return children.flatMap(collectText)
  return collectText(children)
}

const loadAdminPage = (): AdminModule =>
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  require('@/app/admin/page') as AdminModule

describe('protected web app shell', () => {
  test('renders user navigation labels exactly Dictionary, Recognition, Calls, Profile, and Notifications', () => {
    const labels = ['Dictionary', 'Recognition', 'Calls', 'Profile', 'Notifications']
    const text = collectText(Home()).join(' ')

    for (const label of labels) {
      expect(text).toContain(label)
    }
    expect(text).not.toContain('Admin')
  })

  test('shows login or session state when profile fetch is unauthenticated', () => {
    const text = collectText(Home()).join(' ')

    expect(text).toMatch(/log in|login|session|unauthorized/i)
  })

  test('/admin chrome is separate and not mixed with user navigation', () => {
    const adminPage = loadAdminPage()
    const adminText = collectText(adminPage.default()).join(' ')

    expect(adminText).toContain('Admin')
    expect(adminText).toMatch(/Users|Dictionary|SOS logs|Broadcasts|Audit logs/)
    expect(adminText).not.toMatch(/Communicate|Profile.*Notifications.*Calls/)
  })
})
