import { getCatalogDb } from './db';
import { normalizeIsbn13 } from '../isbn';

export type NaverCatalogFields = {
  isbnRaw: string;
  title: string;
  imageUrl: string;
  author: string | null;
  publisher: string | null;
  pubdate: string | null;
  link: string | null;
};

export function stripHtml(s: string): string {
  return s.replace(/<[^>]*>/g, '').trim();
}

export function naverItemToCatalogFields(item: Record<string, unknown>): NaverCatalogFields | null {
  const rawTitle = item.title;
  if (typeof rawTitle !== 'string' || !rawTitle.trim()) return null;
  const title = stripHtml(rawTitle);
  if (!title) return null;

  const isbnRaw =
    typeof item.isbn === 'string'
      ? item.isbn.trim()
      : item.isbn != null
        ? String(item.isbn).trim()
        : '';
  if (!isbnRaw) return null;

  const image =
    typeof item.image === 'string' && item.image.trim()
      ? item.image.trim()
      : '';

  const str = (k: string): string | null => {
    const v = item[k];
    if (typeof v !== 'string') return null;
    const t = stripHtml(v);
    return t.length ? t : null;
  };

  return {
    isbnRaw,
    title,
    imageUrl: image,
    author: str('author'),
    publisher: str('publisher'),
    pubdate: str('pubdate'),
    link: str('link'),
  };
}

/** Upsert Naver metadata; never overwrite existing total_pages. */
export function upsertFromNaver(fields: NaverCatalogFields): string | null {
  const isbn13 = normalizeIsbn13(fields.isbnRaw);
  if (!isbn13) return null;

  const now = Math.floor(Date.now() / 1000);
  const db = getCatalogDb();
  db.prepare(
    `
    INSERT INTO book_catalog (
      isbn13, title, image_url, author, publisher, pubdate, link,
      naver_cached_at, updated_at
    ) VALUES (
      @isbn13, @title, @image_url, @author, @publisher, @pubdate, @link,
      @naver_cached_at, @updated_at
    )
    ON CONFLICT(isbn13) DO UPDATE SET
      title = excluded.title,
      image_url = excluded.image_url,
      author = excluded.author,
      publisher = excluded.publisher,
      pubdate = excluded.pubdate,
      link = excluded.link,
      naver_cached_at = excluded.naver_cached_at,
      updated_at = excluded.updated_at
    `,
  ).run({
    isbn13,
    title: fields.title,
    image_url: fields.imageUrl,
    author: fields.author,
    publisher: fields.publisher,
    pubdate: fields.pubdate,
    link: fields.link,
    naver_cached_at: now,
    updated_at: now,
  });

  return isbn13;
}

export function getCatalogTotalPages(isbn13: string): number | null {
  const row = getCatalogDb()
    .prepare('SELECT total_pages FROM book_catalog WHERE isbn13 = ?')
    .get(isbn13) as { total_pages: number | null } | undefined;
  if (!row || row.total_pages == null || row.total_pages <= 0) return null;
  return row.total_pages;
}

export function setCatalogTotalPagesFromAladin(isbn13: string, totalPages: number): void {
  const now = Math.floor(Date.now() / 1000);
  getCatalogDb()
    .prepare(
      `
      UPDATE book_catalog
      SET total_pages = @total_pages,
          page_source = 'aladin',
          aladin_enriched_at = @aladin_enriched_at,
          updated_at = @updated_at
      WHERE isbn13 = @isbn13 AND (total_pages IS NULL OR total_pages <= 0)
      `,
    )
    .run({
      isbn13,
      total_pages: totalPages,
      aladin_enriched_at: now,
      updated_at: now,
    });
}
