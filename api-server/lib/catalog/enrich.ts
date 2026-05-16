import {
  createAladinMetrics,
  logAladinMetrics,
  recordAladinSkip,
  type AladinSearchMetrics,
} from '../aladin/metrics';
import {
  canCallAladin,
  getAladinCallCount,
  incrementAladinCallCount,
} from '../aladin/daily-limit';
import { lookupItemPageByIsbn13 } from '../aladin/lookup';
import { normalizeIsbn13 } from '../isbn';
import {
  getCatalogTotalPages,
  naverItemToCatalogFields,
  setCatalogTotalPagesFromAladin,
  upsertFromNaver,
} from './upsert';

export type EnrichedSearchResult = {
  items: Record<string, unknown>[];
  aladinMetrics: AladinSearchMetrics;
  aladinCallCount: number;
};

/**
 * Naver items → catalog upsert → lazy Aladin page enrich (per-request cap).
 */
export async function enrichNaverSearchItems(
  naverItems: Record<string, unknown>[],
  maxAladinAttempts: number,
): Promise<EnrichedSearchResult> {
  const metrics = createAladinMetrics();
  const ttbKey = process.env.ALADIN_TTB_KEY?.trim() ?? '';
  const hasKey = ttbKey.length > 0;
  let aladinAttempts = 0;

  const out: Record<string, unknown>[] = [];

  for (const raw of naverItems) {
    const fields = naverItemToCatalogFields(raw);
    const item = { ...raw };

    if (!fields) {
      item.total_pages = null;
      out.push(item);
      continue;
    }

    const isbn13 = upsertFromNaver(fields);
    if (!isbn13) {
      recordAladinSkip(metrics, 'no_isbn');
      item.total_pages = null;
      out.push(item);
      continue;
    }

    let pages = getCatalogTotalPages(isbn13);

    if (pages == null && hasKey && aladinAttempts < maxAladinAttempts) {
      metrics.attempted += 1;
      aladinAttempts += 1;

      if (!canCallAladin()) {
        recordAladinSkip(metrics, 'limit');
      } else {
        const lookedUp = await lookupItemPageByIsbn13(isbn13, ttbKey);
        if (lookedUp != null) {
          setCatalogTotalPagesFromAladin(isbn13, lookedUp);
          incrementAladinCallCount();
          pages = lookedUp;
          metrics.enriched += 1;
        } else {
          recordAladinSkip(metrics, 'no_match');
        }
      }
    } else if (pages == null && !hasKey) {
      recordAladinSkip(metrics, 'no_key');
    }

    item.total_pages = pages ?? null;
    out.push(item);
  }

  const day = new Date().toISOString().slice(0, 10);
  const callCount = getAladinCallCount(day);
  logAladinMetrics(metrics, day, callCount);

  return { items: out, aladinMetrics: metrics, aladinCallCount: callCount };
}

/** Attach total_pages from catalog for a single raw isbn (no Aladin call). */
export function attachTotalPagesFromCatalog(item: Record<string, unknown>): Record<string, unknown> {
  const isbnRaw =
    typeof item.isbn === 'string'
      ? item.isbn
      : item.isbn != null
        ? String(item.isbn)
        : '';
  const isbn13 = normalizeIsbn13(isbnRaw);
  const pages = isbn13 ? getCatalogTotalPages(isbn13) : null;
  return { ...item, total_pages: pages ?? null };
}
