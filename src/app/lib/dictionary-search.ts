const DIACRITIC_REGEX = /\p{Diacritic}/gu

export function normalizeVietnameseSearch(input: string): string {
  return input
    .normalize('NFD')
    .replace(DIACRITIC_REGEX, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .replace(/[_\s]+/g, ' ')
    .trim()
    .toLowerCase()
}

export function normalizeKeywordList(input: string[] | string | null | undefined): string[] {
  if (!input) return []
  if (Array.isArray(input)) {
    return input
      .map((item) => normalizeVietnameseSearch(String(item)))
      .filter(Boolean)
  }

  return input
    .split(',')
    .map((item) => normalizeVietnameseSearch(item))
    .filter(Boolean)
}
