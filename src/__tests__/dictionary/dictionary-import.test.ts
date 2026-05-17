import fs from 'node:fs/promises'
import os from 'node:os'
import path from 'node:path'
import { beforeEach, describe, expect, jest, test } from '@jest/globals'
import { prisma } from '@/app/lib/db'
import {
  importDictionaryManifest,
  readManifestRows,
  resolveRowStatus,
} from '@/../scripts/import-dictionary'

describe('dictionary import tooling', () => {
  beforeEach(() => {
    jest.clearAllMocks()
  })

  test('reads CSV manifest rows', async () => {
    const tempFile = path.join(os.tmpdir(), `dictionary-import-${Date.now()}.csv`)
    await fs.writeFile(
      tempFile,
      'slug,vietnameseText,category,keywords,videoKey,videoUrl,thumbnailKey,thumbnailUrl,status\n'
        + 'xin-chao,Xin chào,Greetings,"hello, greeting",videos/xin-chao.mp4,,,https://cdn.example.com/thumbs/xin-chao.jpg,PUBLISHED\n',
      'utf8',
    )

    const rows = await readManifestRows(tempFile)
    expect(rows).toHaveLength(1)
    expect(rows[0].slug).toBe('xin-chao')
  })

  test.each([
    [{ slug: 'a', vietnameseText: 'Xin chào', category: 'Greetings' }, 'NEEDS_REVIEW'],
    [{ slug: '', vietnameseText: 'Xin chào', category: 'Greetings', videoUrl: 'https://cdn.example.com/x.mp4' }, 'DRAFT'],
    [{ slug: 'xin-chao', vietnameseText: 'Xin chào', category: 'Greetings', videoUrl: 'https://cdn.example.com/x.mp4' }, 'PUBLISHED'],
  ])('resolves manifest status safely', (row, expected) => {
    expect(resolveRowStatus(row as any)).toBe(expected)
  })

  test('creates or updates categories and entries from the manifest', async () => {
    const tempFile = path.join(os.tmpdir(), `dictionary-import-run-${Date.now()}.csv`)
    await fs.writeFile(
      tempFile,
      'slug,vietnameseText,category,keywords,videoKey,videoUrl,thumbnailKey,thumbnailUrl,status\n'
        + 'xin-chao,Xin chào,Greetings,"hello, greeting",videos/xin-chao.mp4,,,https://cdn.example.com/thumbs/xin-chao.jpg,PUBLISHED\n',
      'utf8',
    )

    ;(prisma.dictionaryCategory.upsert as jest.Mock).mockResolvedValue({ id: 9, slug: 'greetings', name: 'Greetings' })
    ;(prisma.dictionaryEntry.findUnique as jest.Mock).mockResolvedValue(null)
    ;(prisma.dictionaryEntry.create as jest.Mock).mockResolvedValue({ id: 11 })

    const result = await importDictionaryManifest(tempFile)

    expect(result.total).toBe(1)
    expect(prisma.dictionaryCategory.upsert).toHaveBeenCalled()
    expect(prisma.dictionaryEntry.create).toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({
          slug: 'xin-chao',
          status: 'PUBLISHED',
        }),
      }),
    )
  })
})
