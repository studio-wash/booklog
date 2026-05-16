import { normalizeIsbn13 } from '../isbn';
import { getCatalogTotalPages } from './upsert';

function isbn13FromNaverItem(raw: Record<string, unknown>): string | null {
  const isbnRaw =
    typeof raw.isbn === 'string'
      ? raw.isbn.trim()
      : raw.isbn != null
        ? String(raw.isbn).trim()
        : '';
  if (!isbnRaw) return null;
  return normalizeIsbn13(isbnRaw);
}

/**
 * Optional catalog read helper (not used on search response — keep DB off the hot path).
 * Search returns raw Naver items; upsert + Aladin run in background only.
 */
export async function attachCachedTotalPagesOnly(
  naverItems: Record<string, unknown>[],
): Promise<Record<string, unknown>[]> {
  const out: Record<string, unknown>[] = [];
  for (const raw of naverItems) {
    const item = { ...raw, total_pages: null as number | null };
    const isbn13 = isbn13FromNaverItem(raw);
    if (isbn13) {
      item.total_pages = await getCatalogTotalPages(isbn13);
    }
    out.push(item);
  }
  return out;
}
