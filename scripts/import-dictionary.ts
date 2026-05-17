import fs from 'node:fs/promises'
import path from 'node:path'
import { prisma } from '@/app/lib/db'
import { normalizeKeywordList, normalizeVietnameseSearch } from '@/app/lib/dictionary-search'

type ImportStatus = 'DRAFT' | 'NEEDS_REVIEW' | 'PUBLISHED' | 'UNPUBLISHED'

export type DictionaryManifestRow = {
  slug: string
  vietnameseText: string
  category: string
  keywords?: string
  videoKey?: string
  videoUrl?: string
  thumbnailKey?: string
  thumbnailUrl?: string
  status?: string
}

function parseCsvLine(line: string): string[] {
  const result: string[] = []
  let current = ''
  let inQuotes = false

  for (let i = 0; i < line.length; i += 1) {
    const char = line[i]

    if (char === '"') {
      if (inQuotes && line[i + 1] === '"') {
        current += '"'
        i += 1
      } else {
        inQuotes = !inQuotes
      }
      continue
    }

    if (char === ',' && !inQuotes) {
      result.push(current)
      current = ''
      continue
    }

    current += char
  }

  result.push(current)
  return result.map((value) => value.trim())
}

export async function readManifestRows(manifestPath: string): Promise<DictionaryManifestRow[]> {
  const file = await fs.readFile(manifestPath, 'utf8')
  const lines = file.split(/\r?\n/).filter(Boolean)
  if (lines.length < 2) return []

  const headers = parseCsvLine(lines[0])
  return lines.slice(1).map((line) => {
    const values = parseCsvLine(line)
    return headers.reduce<Record<string, string>>((acc, header, index) => {
      acc[header] = values[index] ?? ''
      return acc
    }, {}) as DictionaryManifestRow
  })
}

export function resolveRowStatus(row: DictionaryManifestRow): ImportStatus {
  const explicitStatus = (row.status ?? '').toUpperCase()
  const hasVideo = Boolean(row.videoUrl || row.videoKey)
  const hasCoreMetadata = Boolean(row.slug && row.vietnameseText && row.category)

  if (!hasCoreMetadata) return 'DRAFT'
  if (!hasVideo) return 'NEEDS_REVIEW'
  if (['DRAFT', 'NEEDS_REVIEW', 'PUBLISHED', 'UNPUBLISHED'].includes(explicitStatus)) {
    return explicitStatus as ImportStatus
  }
  return 'PUBLISHED'
}

function categorySlugFromName(name: string) {
  return normalizeVietnameseSearch(name).replace(/\s+/g, '-')
}

export async function importDictionaryManifest(manifestPath: string) {
  const rows = await readManifestRows(manifestPath)
  let created = 0
  let updated = 0

  for (const row of rows) {
    const categoryName = row.category?.trim()
    const vietnameseText = row.vietnameseText?.trim()
    const slug = row.slug?.trim() || normalizeVietnameseSearch(vietnameseText).replace(/\s+/g, '-')
    const status = resolveRowStatus(row)

    const category = await prisma.dictionaryCategory.upsert({
      where: { slug: categorySlugFromName(categoryName) },
      update: { name: categoryName },
      create: {
        slug: categorySlugFromName(categoryName),
        name: categoryName,
      },
    })

    const payload = {
      slug,
      vietnameseText,
      searchText: normalizeVietnameseSearch(`${vietnameseText} ${row.keywords ?? ''}`),
      keywords: normalizeKeywordList(row.keywords),
      categoryId: category.id,
      status,
      videoKey: row.videoKey || null,
      videoUrl: row.videoUrl || null,
      thumbnailKey: row.thumbnailKey || null,
      thumbnailUrl: row.thumbnailUrl || null,
    }

    const existing = await prisma.dictionaryEntry.findUnique({
      where: { slug },
      select: { id: true },
    })

    if (existing) {
      await prisma.dictionaryEntry.update({
        where: { slug },
        data: payload,
      })
      updated += 1
      continue
    }

    await prisma.dictionaryEntry.create({
      data: payload,
    })
    created += 1
  }

  return {
    total: rows.length,
    created,
    updated,
  }
}

async function main() {
  const manifestFlagIndex = process.argv.findIndex((arg) => arg === '--manifest')
  const manifestPath =
    manifestFlagIndex >= 0 ? process.argv[manifestFlagIndex + 1] : 'data/dictionary/vsl-4000.csv'

  if (!manifestPath) {
    throw new Error('Expected --manifest <path>')
  }

  const resolvedPath = path.resolve(process.cwd(), manifestPath)
  const result = await importDictionaryManifest(resolvedPath)
  console.log(JSON.stringify({ manifestPath: resolvedPath, ...result }, null, 2))
}

if (require.main === module) {
  main().catch((error) => {
    console.error(error)
    process.exit(1)
  })
}
