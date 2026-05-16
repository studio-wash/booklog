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

/** Stay within Vercel serverless timeouts (sequential ItemLookUp calls). */
const MAX_ALADIN_PER_REQUEST = 3;

function naverItemsWithNullPages(naverItems: Record<string, unknown>[]): Record<string, unknown>[] {
  return naverItems.map((raw) => ({ ...raw, total_pages: null }));
}

/**
 * Background job: Naver upsert → catalog read → lazy Aladin (per-request cap).
 * Search route returns before this runs; see enrich-fast.ts for the fast path.
 */
export async function enrichNaverSearchItems(
  naverItems: Record<string, unknown>[],
  maxAladinAttempts: number,
): Promise<EnrichedSearchResult> {
  const aladinCap = Math.min(maxAladinAttempts, MAX_ALADIN_PER_REQUEST);
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

    const isbn13 = await upsertFromNaver(fields);
    if (!isbn13) {
      recordAladinSkip(metrics, 'no_isbn');
      item.total_pages = null;
      out.push(item);
      continue;
    }

    let pages = await getCatalogTotalPages(isbn13);

    if (pages == null && hasKey && aladinAttempts < aladinCap) {
      metrics.attempted += 1;
      aladinAttempts += 1;

      if (!(await canCallAladin())) {
        recordAladinSkip(metrics, 'limit');
      } else {
        const lookedUp = await lookupItemPageByIsbn13(isbn13, ttbKey);
        if (lookedUp != null) {
          await setCatalogTotalPagesFromAladin(isbn13, lookedUp);
          await incrementAladinCallCount();
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
  const callCount = await getAladinCallCount(day);
  logAladinMetrics(metrics, day, callCount);

  return { items: out, aladinMetrics: metrics, aladinCallCount: callCount };
}

/**
 * Safe enrich for serverless: never throws; returns Naver rows on catalog/Aladin failure.
 */
export async function enrichNaverSearchItemsSafe(
  naverItems: Record<string, unknown>[],
  maxAladinAttempts: number,
): Promise<EnrichedSearchResult> {
  try {
    return await enrichNaverSearchItems(naverItems, maxAladinAttempts);
  } catch (err) {
    console.error(
      JSON.stringify({
        event: 'enrich_failed',
        message: err instanceof Error ? err.message : String(err),
      }),
    );
    return {
      items: naverItemsWithNullPages(naverItems),
      aladinMetrics: createAladinMetrics(),
      aladinCallCount: 0,
    };
  }
}

/** Attach total_pages from catalog for a single raw isbn (no Aladin call). */
export async function attachTotalPagesFromCatalog(
  item: Record<string, unknown>,
): Promise<Record<string, unknown>> {
  const isbnRaw =
    typeof item.isbn === 'string'
      ? item.isbn
      : item.isbn != null
        ? String(item.isbn)
        : '';
  const isbn13 = normalizeIsbn13(isbnRaw);
  const pages = isbn13 ? await getCatalogTotalPages(isbn13) : null;
  return { ...item, total_pages: pages ?? null };
}
