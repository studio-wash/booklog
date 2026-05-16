// Spec PLAN-000007 / knowledge/reference/api/aladin-openapi.md — ItemLookUp.

const ALADIN_LOOKUP = 'http://www.aladin.co.kr/ttb/api/ItemLookUp.aspx';
const LOOKUP_TIMEOUT_MS = 4000;

export function extractItemPageFromAladinJson(data: unknown): number | null {
  if (!data || typeof data !== 'object') return null;
  const root = data as Record<string, unknown>;
  let item = root.item;
  if (Array.isArray(item)) item = item[0];
  if (!item || typeof item !== 'object') return null;
  const sub = (item as Record<string, unknown>).subInfo;
  if (!sub || typeof sub !== 'object') return null;
  const page = (sub as Record<string, unknown>).itemPage;
  if (typeof page === 'number' && Number.isFinite(page) && page > 0) {
    return Math.floor(page);
  }
  if (typeof page === 'string') {
    const n = Number.parseInt(page, 10);
    if (Number.isFinite(n) && n > 0) return n;
  }
  return null;
}

export async function lookupItemPageByIsbn13(
  isbn13: string,
  ttbKey: string,
): Promise<number | null> {
  const url = new URL(ALADIN_LOOKUP);
  url.searchParams.set('TTBKey', ttbKey);
  url.searchParams.set('ItemIdType', 'ISBN13');
  url.searchParams.set('ItemId', isbn13);
  url.searchParams.set('Output', 'JS');
  url.searchParams.set('Version', '20131101');

  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), LOOKUP_TIMEOUT_MS);
  try {
    const res = await fetch(url.toString(), {
      signal: controller.signal,
      cache: 'no-store',
    });
    if (!res.ok) return null;
    const data: unknown = await res.json();
    return extractItemPageFromAladinJson(data);
  } catch {
    return null;
  } finally {
    clearTimeout(timer);
  }
}
