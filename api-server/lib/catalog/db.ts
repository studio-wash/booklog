import { ensurePgReady, resetPgForTests } from './db-pg';
import { getCatalogDb, resetCatalogDbForTests as resetSqliteCatalogDb } from './db-sqlite';

export type CatalogRow = {
  isbn13: string;
  title: string | null;
  image_url: string | null;
  author: string | null;
  publisher: string | null;
  pubdate: string | null;
  link: string | null;
  total_pages: number | null;
  page_source: string | null;
  naver_cached_at: number | null;
  aladin_enriched_at: number | null;
  updated_at: number;
};

/** Neon Postgres when set; otherwise local SQLite (dev/tests). */
export function usesPostgresCatalog(): boolean {
  return Boolean(process.env.DATABASE_URL?.trim());
}

export async function ensureCatalogReady(): Promise<void> {
  if (usesPostgresCatalog()) {
    await ensurePgReady();
    return;
  }
  getCatalogDb();
}

export function resetCatalogDbForTests(): void {
  resetPgForTests();
  resetSqliteCatalogDb();
}

export { catalogDbPath, isServerlessRuntime } from './db-sqlite';
