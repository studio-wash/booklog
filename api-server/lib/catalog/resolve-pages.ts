import { canCallAladin, incrementAladinCallCount } from '../aladin/daily-limit';
import { lookupItemPageByIsbn13 } from '../aladin/lookup';
import { normalizeIsbn13 } from '../isbn';
import {
  getCatalogTotalPages,
  markAladinLookupAttempted,
  naverItemToCatalogFields,
  setCatalogTotalPagesFromAladin,
  upsertFromNaver,
  wasAladinLookupAttempted,
  type NaverCatalogFields,
} from './upsert';

export type CatalogPagesBody = {
  isbn?: string;
  title?: string;
  image?: string;
  author?: string;
  publisher?: string;
  pubdate?: string;
  link?: string;
};

export function bodyToNaverFields(body: CatalogPagesBody): NaverCatalogFields | null {
  const isbnRaw = body.isbn?.trim() ?? '';
  const title = body.title?.trim() ?? '';
  if (!isbnRaw || !title) return null;
  return {
    isbnRaw,
    title,
    imageUrl: body.image?.trim() ?? '',
    author: body.author?.trim() || null,
    publisher: body.publisher?.trim() || null,
    pubdate: body.pubdate?.trim() || null,
    link: body.link?.trim() || null,
  };
}

/** Upsert Naver meta, read cache, optional single Aladin ItemLookUp. */
export async function resolveCatalogTotalPages(
  body: CatalogPagesBody,
): Promise<{ isbn13: string | null; total_pages: number | null }> {
  const fields = bodyToNaverFields(body);
  if (!fields) {
    return { isbn13: null, total_pages: null };
  }

  const isbn13 = await upsertFromNaver(fields);
  if (!isbn13) {
    return { isbn13: null, total_pages: null };
  }

  let pages = await getCatalogTotalPages(isbn13);
  if (pages != null) {
    return { isbn13, total_pages: pages };
  }

  if (await wasAladinLookupAttempted(isbn13)) {
    return { isbn13, total_pages: null };
  }

  const ttbKey = process.env.ALADIN_TTB_KEY?.trim() ?? '';
  if (!ttbKey || !(await canCallAladin())) {
    return { isbn13, total_pages: null };
  }

  const lookedUp = await lookupItemPageByIsbn13(isbn13, ttbKey);
  await incrementAladinCallCount();
  if (lookedUp != null) {
    await setCatalogTotalPagesFromAladin(isbn13, lookedUp);
    pages = lookedUp;
  } else {
    await markAladinLookupAttempted(isbn13);
  }

  return { isbn13, total_pages: pages };
}

/** For tests: normalize ISBN from body without DB. */
export function normalizeIsbnFromBody(body: CatalogPagesBody): string | null {
  const raw = body.isbn?.trim() ?? '';
  if (!raw) return null;
  return normalizeIsbn13(raw);
}
