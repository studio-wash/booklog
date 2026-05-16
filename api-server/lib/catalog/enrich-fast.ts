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
 * Search response path only: attach cached `total_pages` from catalog (read).
 * No Naver upsert, no Aladin calls — those run in background after the response.
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
