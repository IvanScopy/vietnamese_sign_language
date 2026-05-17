import fs from 'node:fs/promises'
import path from 'node:path'
import { normalizeVietnameseSearch } from '@/app/lib/dictionary-search'

type SourceRow = {
  ID: string
  VIDEO: string
  LABEL: string
  base_label: string
  suffix: string
}

type ManifestRow = {
  slug: string
  vietnameseText: string
  category: string
  keywords: string
  videoKey: string
  videoUrl: string
  thumbnailKey: string
  thumbnailUrl: string
  status: 'PUBLISHED'
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

function csvEscape(value: string) {
  if (/[",\n]/.test(value)) {
    return `"${value.replace(/"/g, '""')}"`
  }
  return value
}

function slugify(value: string) {
  return normalizeVietnameseSearch(value)
    .replace(/[^a-z0-9\s-]/g, '')
    .trim()
    .replace(/\s+/g, '-')
}

type CategoryRule = {
  category: string
  patterns: RegExp[]
}

const CATEGORY_RULES: CategoryRule[] = [
  {
    category: 'Gia đình & Con người',
    patterns: [
      /\b(ba|m[ẹe]|b[ốo]|cha|anh|chị|em|ông|bà|cô|chú|bác|dì|cậu|con|cháu|gia đình|vợ|chồng|bé|trẻ)\b/,
    ],
  },
  {
    category: 'Địa điểm & Địa lý',
    patterns: [
      /\b(tỉnh|thành phố|quốc gia|nước|đảo|biển|núi|sông|đường|địa chỉ|phương đông|phương tây|miền)\b/,
      /\b(hà nội|hồ chí minh|đà nẵng|quy nhơn|tuy hoà|ma cao|albania|đ[uư] bai|ả rập|do thái|miến điện)\b/,
    ],
  },
  {
    category: 'Học tập & Trường lớp',
    patterns: [
      /\b(trường|lớp|giáo|học|bài|sách|vở|bút|kiểm tra|điểm|sinh viên|học sinh)\b/,
    ],
  },
  {
    category: 'Công việc & Xã hội',
    patterns: [
      /\b(nhân viên|tiếp tân|công ty|cơ quan|công việc|làm việc|nghề|nghiệp|lương|nhập khẩu|xuất khẩu|kinh doanh|hợp đồng)\b/,
    ],
  },
  {
    category: 'Ẩm thực',
    patterns: [
      /\b(ăn|uống|cơm|cháo|bún|phở|bánh|kẹo|trái cây|rau|thịt|cá|trứng|sữa|cafe|cà phê|bia|rượu|nước ngọt|đói|khát)\b/,
    ],
  },
  {
    category: 'Sức khỏe & Cơ thể',
    patterns: [
      /\b(đau|bệnh|sốt|ho|thuốc|bác sĩ|bệnh viện|cơ thể|mắt|tai|mũi|miệng|tay|chân|tim|bụng|đầu|răng|mặt)\b/,
      /\b(rửa mặt|rửa chân|đánh răng)\b/,
    ],
  },
  {
    category: 'Cảm xúc & Tính cách',
    patterns: [
      /\b(vui|buồn|giận|ghen|yêu|thương|ghét|sợ|lo|xấu hổ|ngạc nhiên|hạnh phúc|căng thẳng|tôn trọng|tham ăn|hấp dẫn|nổi da gà)\b/,
    ],
  },
  {
    category: 'Hành động & Mô tả',
    patterns: [
      /\b(chạy|đi|đứng|ngồi|nằm|mở|đóng|cười|khóc|làm|giúp|giám sát|tác động|lung tung|đứng đầu)\b/,
    ],
  },
  {
    category: 'Thời gian & Số lượng',
    patterns: [
      /\b(hôm nay|ngày|tháng|năm|giờ|phút|tuần|thứ|sáng|trưa|chiều|tối|sớm|muộn|đầu tiên|cuối cùng|một|hai|ba|bốn|năm mươi|trăm|nghìn)\b/,
    ],
  },
  {
    category: 'Di chuyển & Phương tiện',
    patterns: [
      /\b(xe|tàu|thuyền|máy bay|xe máy|ô tô|giao thông|đi bộ|du lịch|đến nơi|khởi hành)\b/,
    ],
  },
  {
    category: 'Tự nhiên & Động vật',
    patterns: [
      /\b(trời|mưa|nắng|gió|đất|cây|hoa|lá|rừng|động vật|chim|cá|chó|mèo|gà)\b/,
    ],
  },
  {
    category: 'Tín ngưỡng & Văn hóa',
    patterns: [
      /\b(chùa|nhà thờ|phật|chúa|lễ|tết|văn hóa|do thái|ả rập)\b/,
    ],
  },
  {
    category: 'An toàn & Khẩn cấp',
    patterns: [
      /\b(cấp cứu|nguy hiểm|cảnh sát|cứu|cháy|khẩn cấp|tai nạn|bảo vệ)\b/,
    ],
  },
]

function inferCategory(baseLabel: string) {
  const normalized = normalizeVietnameseSearch(baseLabel)
  for (const rule of CATEGORY_RULES) {
    if (rule.patterns.some((pattern) => pattern.test(normalized))) {
      return rule.category
    }
  }
  return 'Từ vựng thông dụng'
}

function buildKeywords(row: SourceRow) {
  const keywords = [row.base_label.trim(), row.LABEL.trim()]
  if (row.suffix && row.suffix !== 'none') {
    keywords.push(`mien ${row.suffix.toLowerCase()}`)
  }
  return Array.from(new Set(keywords.filter(Boolean))).join(', ')
}

async function readSourceRows(sourcePath: string): Promise<SourceRow[]> {
  const content = await fs.readFile(sourcePath, 'utf8')
  const lines = content.split(/\r?\n/).filter(Boolean)
  const headers = parseCsvLine(lines[0])

  return lines.slice(1).map((line) => {
    const values = parseCsvLine(line)
    return headers.reduce<Record<string, string>>((acc, header, index) => {
      acc[header] = values[index] ?? ''
      return acc
    }, {}) as SourceRow
  })
}

async function main() {
  const sourcePath = path.resolve(process.cwd(), 'data-video12-5/Labels/merged_label.csv')
  const outputDir = path.resolve(process.cwd(), 'data/dictionary')
  const cdnBaseUrl = (process.env.DICTIONARY_CDN_BASE_URL ?? '').replace(/\/$/, '')

  if (!cdnBaseUrl) {
    throw new Error('DICTIONARY_CDN_BASE_URL is required')
  }

  const rows = await readSourceRows(sourcePath)
  const usedSlugs = new Set<string>()
  const manifests: ManifestRow[] = rows.map((row) => {
    const vietnameseText = row.base_label.trim()
    const slugBase = slugify(vietnameseText || row.VIDEO.replace(/\.mp4$/i, ''))
    const variantSuffix = row.suffix && row.suffix !== 'none' ? `-${row.suffix.toLowerCase()}` : ''
    const videoKey = row.VIDEO.trim()
    const videoSlugSuffix = slugify(videoKey.replace(/\.mp4$/i, ''))
    let slug = `${slugBase}${variantSuffix}`

    if (usedSlugs.has(slug)) {
      slug = `${slug}-${videoSlugSuffix}`
    }
    usedSlugs.add(slug)

    return {
      slug,
      vietnameseText,
      category: inferCategory(vietnameseText),
      keywords: buildKeywords(row),
      videoKey,
      videoUrl: `${cdnBaseUrl}/${encodeURIComponent(videoKey)}`,
      thumbnailKey: '',
      thumbnailUrl: '',
      status: 'PUBLISHED',
    }
  })

  const header = 'slug,vietnameseText,category,keywords,videoKey,videoUrl,thumbnailKey,thumbnailUrl,status'
  const lines = manifests.map((row) =>
    [
      row.slug,
      row.vietnameseText,
      row.category,
      row.keywords,
      row.videoKey,
      row.videoUrl,
      row.thumbnailKey,
      row.thumbnailUrl,
      row.status,
    ].map(csvEscape).join(','),
  )

  await fs.mkdir(outputDir, { recursive: true })
  const content = `${header}\n${lines.join('\n')}\n`
  await Promise.all([
    fs.writeFile(path.join(outputDir, 'vsl-4000.csv'), content, 'utf8'),
    fs.writeFile(path.join(outputDir, 'vsl-4362.csv'), content, 'utf8'),
  ])

  const categoryCounts = manifests.reduce<Record<string, number>>((acc, row) => {
    acc[row.category] = (acc[row.category] ?? 0) + 1
    return acc
  }, {})

  console.log(JSON.stringify({
    total: manifests.length,
    categories: Object.keys(categoryCounts).length,
    topCategories: Object.entries(categoryCounts)
      .sort((a, b) => b[1] - a[1])
      .slice(0, 10),
  }, null, 2))
}

main().catch((error) => {
  console.error(error)
  process.exit(1)
})
