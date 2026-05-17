import { beforeEach, describe, expect, jest, test } from '@jest/globals'
import { NextRequest } from 'next/server'
import { prisma } from '@/app/lib/db'

type RouteModule = {
  GET: (request: NextRequest, context?: { params?: Record<string, string> }) => Promise<Response>
}

const loadDictionaryRoute = (): RouteModule =>
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  require('@/app/api/dictionary/route') as RouteModule

const loadDictionaryDetailRoute = (): RouteModule =>
  // eslint-disable-next-line @typescript-eslint/no-var-requires
  require('@/app/api/dictionary/[slug]/route') as RouteModule

const makeRequest = (url: string) => new NextRequest(url, { method: 'GET' })

const publishedEntry = {
  id: 1,
  slug: 'gia-dinh',
  term: 'gia đình',
  normalizedTerm: 'gia dinh',
  status: 'PUBLISHED',
  categoryId: 10,
  category: { id: 10, slug: 'family', name: 'Family' },
  thumbnailUrl: 'https://cdn.example.com/thumbs/gia-dinh.jpg',
  thumbnailKey: null,
  videoUrl: 'https://cdn.example.com/videos/gia-dinh.mp4',
  videoKey: null,
  keywords: ['gia dinh', 'family', 'dinh'],
  updatedAt: new Date('2026-05-17T00:00:00Z'),
}

const draftEntry = {
  ...publishedEntry,
  id: 2,
  slug: 'ban-be',
  term: 'bạn bè',
  normalizedTerm: 'ban be',
  status: 'DRAFT',
}

const needsReviewEntry = {
  ...publishedEntry,
  id: 3,
  slug: 'truong-hoc',
  term: 'trường học',
  normalizedTerm: 'truong hoc',
  status: 'NEEDS_REVIEW',
}

describe('GET /api/dictionary', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('returns only PUBLISHED entries with videoUrl or videoKey metadata', async () => {
    ;(prisma.dictionaryEntry.findMany as jest.Mock).mockResolvedValue([publishedEntry])

    const { GET } = loadDictionaryRoute()
    const response = await GET(makeRequest('http://localhost:3000/api/dictionary'))

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(prisma.dictionaryEntry.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: 'PUBLISHED',
          OR: expect.arrayContaining([
            { videoUrl: { not: null } },
            { videoKey: { not: null } },
          ]),
        }),
      }),
    )
    expect(data.entries).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          slug: 'gia-dinh',
          status: 'PUBLISHED',
          videoUrl: expect.stringContaining('.mp4'),
        }),
      ]),
    )
    expect(JSON.stringify(data)).not.toContain('DRAFT')
    expect(JSON.stringify(data)).not.toContain('NEEDS_REVIEW')
  })

  test.each(['gia đình', 'Gia Dinh', 'gia_dinh', 'dinh'])(
    'normalizes Vietnamese search variant "%s"',
    async (query) => {
      ;(prisma.dictionaryEntry.findMany as jest.Mock).mockResolvedValue([publishedEntry])

      const { GET } = loadDictionaryRoute()
      const response = await GET(
        makeRequest(`http://localhost:3000/api/dictionary?search=${encodeURIComponent(query)}`),
      )

      expect(response.status).toBe(200)
      expect(prisma.dictionaryEntry.findMany).toHaveBeenCalledWith(
        expect.objectContaining({
          where: expect.objectContaining({
            status: 'PUBLISHED',
            OR: expect.arrayContaining([
              expect.objectContaining({ normalizedTerm: expect.any(Object) }),
              expect.objectContaining({ keywords: expect.any(Object) }),
            ]),
          }),
        }),
      )
    },
  )

  test('filters by category and exposes published counts for browsing', async () => {
    ;(prisma.dictionaryEntry.findMany as jest.Mock).mockResolvedValue([publishedEntry])
    ;(prisma.dictionaryCategory.findMany as jest.Mock).mockResolvedValue([
      { id: 10, slug: 'family', name: 'Family', _count: { entries: 1 } },
      { id: 11, slug: 'school', name: 'School', _count: { entries: 0 } },
    ])

    const { GET } = loadDictionaryRoute()
    const response = await GET(makeRequest('http://localhost:3000/api/dictionary?category=family'))

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(prisma.dictionaryEntry.findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: 'PUBLISHED',
          category: expect.objectContaining({ slug: 'family' }),
        }),
      }),
    )
    expect(data.categories).toEqual(
      expect.arrayContaining([
        expect.objectContaining({ slug: 'family', publishedCount: 1 }),
      ]),
    )
  })

  test('never includes DRAFT or NEEDS_REVIEW fixtures in user-visible results', async () => {
    ;(prisma.dictionaryEntry.findMany as jest.Mock).mockResolvedValue([publishedEntry])

    const { GET } = loadDictionaryRoute()
    const response = await GET(makeRequest('http://localhost:3000/api/dictionary'))

    expect(response.status).toBe(200)
    expect(prisma.dictionaryEntry.findMany).not.toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          status: expect.arrayContaining(['DRAFT', 'NEEDS_REVIEW']),
        }),
      }),
    )
    const data = await response.json()
    expect(JSON.stringify(data)).not.toContain(draftEntry.slug)
    expect(JSON.stringify(data)).not.toContain(needsReviewEntry.slug)
  })
})

describe('GET /api/dictionary/[slug]', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('returns published detail playback metadata, tags, updated date, and related signs', async () => {
    ;(prisma.dictionaryEntry.findUnique as jest.Mock).mockResolvedValue(publishedEntry)
    ;(prisma.dictionaryEntry.findMany as jest.Mock).mockResolvedValue([
      { ...publishedEntry, id: 4, slug: 'me', term: 'mẹ' },
    ])

    const { GET } = loadDictionaryDetailRoute()
    const response = await GET(
      makeRequest('http://localhost:3000/api/dictionary/gia-dinh'),
      { params: { slug: 'gia-dinh' } },
    )

    expect(response.status).toBe(200)
    const data = await response.json()
    expect(data.entry).toEqual(
      expect.objectContaining({
        slug: 'gia-dinh',
        status: 'PUBLISHED',
        videoUrl: expect.any(String),
        thumbnailUrl: expect.any(String),
        keywords: expect.arrayContaining(['gia dinh']),
        updatedAt: expect.any(String),
      }),
    )
    expect(data.entry.playbackSpeeds).toEqual([0.5, 0.75, 1])
    expect(data.related).toEqual(
      expect.arrayContaining([expect.objectContaining({ category: publishedEntry.category })]),
    )
  })
})
